import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/youtube_auth.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/youtube/youtube_auth_service.dart';
import 'package:obs_blade/utils/youtube/youtube_live_chat_service.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/youtube_user_card_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_youtube_chat_view.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_youtube_services.dart';

YouTubeChatMessage ytMessage(
  String id, {
  String author = 'chan-1',
  bool isOwner = false,
  bool isModerator = false,
  bool isSponsor = false,
  bool isVerified = false,
  String? profileImageUrl,
}) => YouTubeChatMessage(
  id: id,
  snippet: YouTubeChatMessageSnippet(
    type: YouTubeChatMessageType.textMessage,
    publishedAt: DateTime.utc(2026, 9, 3),
    authorChannelId: author,
    displayMessage: 'text $id',
    textMessageDetails: YouTubeTextMessageDetails(messageText: 'text $id'),
  ),
  authorDetails: YouTubeChatAuthorDetails(
    channelId: author,
    displayName: 'User $author',
    isChatOwner: isOwner,
    isChatModerator: isModerator,
    isChatSponsor: isSponsor,
    isVerified: isVerified,
    profileImageUrl: profileImageUrl,
  ),
);

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeYouTubeLiveChatService chatService;
  late YouTubeChatStore store;

  Box<YouTubeAuth> authBox() =>
      Hive.box<YouTubeAuth>(HiveKeys.YouTubeAuth.name);

  Box settingsBox() => Hive.box(HiveKeys.Settings.name);

  Widget wrap() =>
      const MaterialApp(home: Scaffold(body: NativeYouTubeChatView()));

  String renderedRichText(WidgetTester tester) => tester
      .widgetList<RichText>(find.byType(RichText))
      .map((rich) => rich.text.toPlainText())
      .join('\n');

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yt_view_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.openBox<YouTubeAuth>(HiveKeys.YouTubeAuth.name);
    chatService = FakeYouTubeLiveChatService();
    store = YouTubeChatStore(
      authService: FakeYouTubeAuthService(),
      chatService: chatService,
      sleep: (duration) async {},
    );
    GetIt.instance.registerSingleton<YouTubeChatStore>(store);
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await store.dispose();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('connecting with an empty buffer shows the spinner copy', (
    tester,
  ) async {
    store.chatConnection = YouTubeChatConnectionState.connecting;
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('Connecting to YouTube chat…'), findsOneWidget);
  });

  testWidgets('offline with an empty buffer explains the missing chat', (
    tester,
  ) async {
    store.chatConnection = YouTubeChatConnectionState.offline;
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(
      find.text(
        'No active live chat — the stream is offline or chat is disabled.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('error with an empty buffer shows the error and a retry', (
    tester,
  ) async {
    store.chatConnection = YouTubeChatConnectionState.error;
    store.chatError = 'Lost connection to YouTube chat';
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('Lost connection to YouTube chat'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('connected timeline renders buffered messages', (tester) async {
    store.chatConnection = YouTubeChatConnectionState.connected;
    store.messages.addAll([ytMessage('m1'), ytMessage('m2')]);
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(renderedRichText(tester), contains('User chan-1'));
    expect(renderedRichText(tester), contains('text m1'));
    expect(renderedRichText(tester), contains('text m2'));
  });

  testWidgets('a mute-word match drops the row from the timeline', (
    tester,
  ) async {
    await tester.runAsync(
      () => settingsBox().put(SettingsKeys.ChatMuteWords.name, 'giveaway'),
    );
    store.chatConnection = YouTubeChatConnectionState.connected;
    store.messages.addAll([
      ytMessage('m1'),
      YouTubeChatMessage(
        id: 'm2',
        snippet: YouTubeChatMessageSnippet(
          type: YouTubeChatMessageType.textMessage,
          publishedAt: DateTime.utc(2026, 9, 3),
          authorChannelId: 'chan-2',
          displayMessage: 'check my GIVEAWAY',
          textMessageDetails: YouTubeTextMessageDetails(
            messageText: 'check my GIVEAWAY',
          ),
        ),
        authorDetails: YouTubeChatAuthorDetails(
          channelId: 'chan-2',
          displayName: 'Spammer',
        ),
      ),
    ]);
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(renderedRichText(tester), contains('text m1'));
    expect(renderedRichText(tester), isNot(contains('GIVEAWAY')));
    expect(find.text('Spammer'), findsNothing);
  });

  testWidgets(
    'signed out: long-press opens a Copy-only sheet, not mod actions',
    (tester) async {
      store.chatConnection = YouTubeChatConnectionState.connected;
      store.messages.add(ytMessage('m1'));

      /// Signed out (reads work via the API key) — long-press chrome is
      /// still there (Copy always works), but it's the lightweight
      /// message sheet, not the mod action sheet.
      await tester.pumpWidget(wrap());
      await tester.pump();
      expect(find.byType(ChatRowLongPressListener), findsOneWidget);

      await tester.longPress(find.textContaining('text m1'));
      await tester.pumpAndSettle();
      expect(find.text('Copy message'), findsOneWidget);
      expect(find.text('Delete message'), findsNothing);
      expect(find.text('Ban'), findsNothing);
    },
  );

  testWidgets('mod long-press chrome appears when signed in', (tester) async {
    /// runAsync: the Hive write must not land in the fake-async zone (a
    /// pending write deadlocks tearDown's harness.close()).
    await tester.runAsync(
      () => authBox().put(
        YouTubeAuth.kBoxKey,
        YouTubeAuth(
          accessToken: 'access',
          refreshToken: 'refresh',
          expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600000,
          scopes: kYouTubeChatScopes,
        ),
      ),
    );

    store.chatConnection = YouTubeChatConnectionState.connected;
    store.messages.add(ytMessage('m1'));

    await tester.pumpWidget(wrap());
    await tester.pump();
    expect(find.byType(ChatRowLongPressListener), findsOneWidget);

    await tester.longPress(find.textContaining('text m1'));
    await tester.pumpAndSettle();
    expect(find.text('Copy message'), findsOneWidget);
    expect(find.text('Delete message'), findsOneWidget);
    expect(find.text('Ban'), findsOneWidget);
  });

  testWidgets(
    'author tap opens the user card with role facts from the buffered '
    'message — no API key needed',
    (tester) async {
      store.chatConnection = YouTubeChatConnectionState.connected;
      store.messages.add(ytMessage('m1', isOwner: true));
      await tester.pumpWidget(wrap());
      await tester.pump();

      await tester.tap(find.text('User chan-1').first);
      await tester.pumpAndSettle();

      expect(find.byType(YouTubeUserCardSheet), findsOneWidget);
      expect(find.text('Channel owner'), findsOneWidget);
      expect(chatService.fetchChannelCalls, isEmpty);
    },
  );

  testWidgets('author tap fetches the channel creation date when an API key is '
      'configured', (tester) async {
    await tester.runAsync(
      () => settingsBox().put(SettingsKeys.YouTubeApiKey.name, 'test-key'),
    );
    chatService.fetchChannelResult = YouTubeChannelInfo(
      title: 'Chan One',
      publishedAt: DateTime.utc(2015, 3, 4),
    );
    store.chatConnection = YouTubeChatConnectionState.connected;
    store.messages.add(ytMessage('m1'));
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('User chan-1').first);
    await tester.pumpAndSettle();

    expect(find.byType(YouTubeUserCardSheet), findsOneWidget);
    expect(chatService.fetchChannelCalls, ['chan-1']);
    expect(find.textContaining('Channel created on'), findsOneWidget);
  });

  testWidgets('author tap with an avatar renders without a fallback icon', (
    tester,
  ) async {
    store.chatConnection = YouTubeChatConnectionState.connected;
    store.messages.add(
      ytMessage('m1', profileImageUrl: 'https://example.com/avatar.png'),
    );
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('User chan-1').first);
    await tester.pumpAndSettle();

    expect(find.byType(YouTubeUserCardSheet), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.person_fill), findsNothing);
  });
}
