import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/kick_auth.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/third_party_emote.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/kick/kick_auth_service.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/kick_mod_action_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/kick_user_card_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/kick_chat_message_row.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_input.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_kick_chat_view.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_kick_services.dart';
import 'support/fake_twitch_services.dart' show FakeThirdPartyEmoteService;

KickChatMessage kickMessage(
  String id, {
  int senderId = 1,
  String? username,
  String? content,
  bool tombstoned = false,
}) => KickChatMessage(
  id: id,
  chatroomId: 42,
  content: content ?? 'text $id',
  createdAt: DateTime.utc(2026, 9, 22, 12),
  sender: KickChatSender(
    id: senderId,
    username: username ?? 'User $senderId',
    slug: 'user-$senderId',
    identity: const KickChatIdentity(color: '#FFAE76'),
  ),
  isTombstoned: tombstoned,
);

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeKickApiService apiService;
  late KickChatStore store;
  late FakeThirdPartyEmoteService emoteService;
  late ThirdPartyEmoteStore emoteStore;

  Widget wrap() =>
      const MaterialApp(home: Scaffold(body: NativeKickChatView()));

  String renderedRichText(WidgetTester tester) => tester
      .widgetList<RichText>(find.byType(RichText))
      .map((rich) => rich.text.toPlainText())
      .join('\n');

  /// Awaited Hive writes never complete in a [testWidgets] fake-async zone.
  Future<void> signIn(WidgetTester tester) async {
    await tester.runAsync(() async {
      await Hive.box<KickAuth>(HiveKeys.KickAuth.name).put(
        KickAuth.kBoxKey,
        KickAuth(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
          scopes: kKickChatScopes,
          userId: 9001,
          username: 'kicker',
        ),
      );
    });
    store.authState = KickAuthState.signedIn;
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kick_view_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.openBox<KickAuth>(HiveKeys.KickAuth.name);
    apiService = FakeKickApiService();
    store = KickChatStore(
      channelService: FakeKickChannelService(),
      apiService: apiService,
      pusherFactory: ({required onEvent, required onStateChanged}) =>
          FakeKickPusherService(
            onEvent: onEvent,
            onStateChanged: onStateChanged,
          ),
      isProResolver: () => true,
    );
    GetIt.instance.registerSingleton<KickChatStore>(store);
    emoteService = FakeThirdPartyEmoteService();
    emoteStore = ThirdPartyEmoteStore(service: emoteService);
    GetIt.instance.registerSingleton<ThirdPartyEmoteStore>(emoteStore);
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
    store.chatConnection = KickChatConnectionState.connecting;
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('Connecting to Kick chat…'), findsOneWidget);
  });

  testWidgets('offline with an empty buffer explains the missing channel', (
    tester,
  ) async {
    store.chatConnection = KickChatConnectionState.offline;
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(
      find.text(
        'No chat for this channel — the slug may be wrong or the channel is unavailable.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('error with an empty buffer shows the error and a retry', (
    tester,
  ) async {
    store.chatConnection = KickChatConnectionState.error;
    store.chatError = 'Could not resolve the Kick channel';
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('Could not resolve the Kick channel'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('connected timeline renders buffered messages', (tester) async {
    store.chatConnection = KickChatConnectionState.connected;
    store.messages.addAll([kickMessage('m1'), kickMessage('m2')]);
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(renderedRichText(tester), contains('User 1'));
    expect(renderedRichText(tester), contains('text m1'));
    expect(renderedRichText(tester), contains('text m2'));
  });

  testWidgets('a mute-word match drops the row from the timeline', (
    tester,
  ) async {
    await tester.runAsync(
      () => Hive.box(
        HiveKeys.Settings.name,
      ).put(SettingsKeys.ChatMuteWords.name, 'giveaway'),
    );
    store.chatConnection = KickChatConnectionState.connected;
    store.messages.addAll([
      kickMessage('m1', content: 'hi chat'),
      kickMessage('m2', content: 'check my GIVEAWAY'),
    ]);
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(renderedRichText(tester), contains('hi chat'));
    expect(renderedRichText(tester), isNot(contains('GIVEAWAY')));
  });

  testWidgets(
    'a mute-word match never hides system rows (/clear, sub notices)',
    (tester) async {
      await tester.runAsync(
        () => Hive.box(
          HiveKeys.Settings.name,
        ).put(SettingsKeys.ChatMuteWords.name, 'subscribed'),
      );
      store.chatConnection = KickChatConnectionState.connected;
      store.messages.add(
        KickChatMessage(
          id: 'system-sub-1',
          type: KickChatMessageType.system,
          content: 'Loyal subscribed — 6 months',
          createdAt: DateTime.utc(2026, 9, 22, 12),
        ),
      );
      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.text('Loyal subscribed — 6 months'), findsOneWidget);
    },
  );

  testWidgets('tombstoned rows render the dimmed marker', (tester) async {
    store.chatConnection = KickChatConnectionState.connected;
    store.messages.add(kickMessage('m1', tombstoned: true));
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(renderedRichText(tester), contains(' —Deleted'));
  });

  testWidgets('the /clear system row renders its notice', (tester) async {
    store.chatConnection = KickChatConnectionState.connected;
    store.messages.add(
      KickChatMessage(
        id: 'system-clear-1',
        type: KickChatMessageType.system,
        createdAt: DateTime.utc(2026, 9, 22, 12),
      ),
    );
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('Chat was cleared by a moderator'), findsOneWidget);
  });

  testWidgets('a sub notice renders its content', (tester) async {
    store.chatConnection = KickChatConnectionState.connected;
    store.messages.add(
      KickChatMessage(
        id: 'system-sub-1',
        type: KickChatMessageType.system,
        content: 'Loyal subscribed — 6 months',
        createdAt: DateTime.utc(2026, 9, 22, 12),
      ),
    );
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('Loyal subscribed — 6 months'), findsOneWidget);
  });

  testWidgets('a third-party (7TV) emote token in plain text renders inline', (
    tester,
  ) async {
    emoteService.sevenTvKickChannel = {
      'Kappa': const ThirdPartyEmote(
        name: 'Kappa',
        imageUrl: 'https://cdn.7tv.app/emote/kappa/2x.webp',
      ),
    };
    await emoteStore.fetch(broadcasterId: '1101', isKick: true);
    store.channelInfo = const KickChannelInfo(
      id: 5,
      userId: 1101,
      slug: 'streamer',
      chatroom: KickChatroom(id: 42),
    );
    store.chatConnection = KickChatConnectionState.connected;
    store.messages.add(kickMessage('m1', content: 'hello Kappa'));
    await tester.pumpWidget(wrap());
    await tester.pump();

    /// flutter_test 400s every image request, so the third-party
    /// emote's Image.network falls back to its raw token text via
    /// errorBuilder (its own nested Text/RichText, hence a separate
    /// line here) — same rendering contract as Twitch's row. The
    /// Image widget itself still mounts, which is what proves the
    /// catalog lookup actually matched (an unknown token never
    /// creates one).
    expect(find.byType(Image), findsOneWidget);
    final rendered = renderedRichText(tester);
    expect(rendered, contains('hello'));
    expect(rendered, contains('Kappa'));
  });

  testWidgets(
    'hiding sub/gift notices via settings drops them from the timeline',
    (tester) async {
      await tester.runAsync(
        () => Hive.box(
          HiveKeys.Settings.name,
        ).put(SettingsKeys.KickChatNoticeSubs.name, false),
      );
      store.chatConnection = KickChatConnectionState.connected;
      store.messages.addAll([
        kickMessage('m1'),
        KickChatMessage(
          id: 'system-sub-1',
          type: KickChatMessageType.system,
          content: 'Loyal subscribed',
          createdAt: DateTime.utc(2026, 9, 22, 12),
        ),
      ]);
      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.text('Loyal subscribed'), findsNothing);
      expect(renderedRichText(tester), contains('text m1'));
    },
  );

  testWidgets('emote tokens fall back to their bracketed name when the '
      'image cannot load', (tester) async {
    store.chatConnection = KickChatConnectionState.connected;
    store.messages.add(kickMessage('m1', content: 'hi [emote:37253:UWU]'));
    await tester.pumpWidget(wrap());
    await tester.pump();

    /// flutter_test's HTTP override 400s every image — the row's
    /// errorBuilder keeps the emote name visible.
    expect(renderedRichText(tester), contains('[UWU]'));
    expect(find.byType(KickChatMessageRow), findsOneWidget);
  });

  testWidgets('signed out: long-press opens no mod sheet', (tester) async {
    store.chatConnection = KickChatConnectionState.connected;
    store.messages.add(kickMessage('m1'));
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.longPress(find.textContaining('text m1'));
    await tester.pumpAndSettle();

    expect(find.byType(KickModActionSheet), findsNothing);
  });

  testWidgets('signed in: long-press opens the reply/mod sheet', (
    tester,
  ) async {
    await signIn(tester);
    store.chatConnection = KickChatConnectionState.connected;
    store.messages.add(kickMessage('m1', username: 'Viewer1'));
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.longPress(find.textContaining('text m1'));
    await tester.pumpAndSettle();

    expect(find.byType(KickModActionSheet), findsOneWidget);
    expect(find.text('Moderate Viewer1'), findsOneWidget);
    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Delete message'), findsOneWidget);
    expect(find.text('Timeout…'), findsOneWidget);
    expect(find.text('Ban'), findsOneWidget);
  });

  testWidgets('signed in: Reply sets the store reply target', (tester) async {
    await signIn(tester);
    store.chatConnection = KickChatConnectionState.connected;
    store.messages.add(kickMessage('m1', username: 'Viewer1'));
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.longPress(find.textContaining('text m1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();

    expect(store.replyTarget?.id, 'm1');
    expect(find.byType(KickModActionSheet), findsNothing);
  });

  testWidgets('the Kick read-only dock strip offers sign-in', (tester) async {
    /// The exact locked-state wiring stream_chat docks for a signed-out
    /// Kick session.
    var reloginTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NativeChatInput(
            canSend: false,
            inFlight: false,
            accentColor: const Color(0xFF53FC18),
            onSend: (_) async => false,
            onRelogin: () => reloginTapped = true,
            lockedHintText: 'Chat is read-only',
            lockedActionText: 'Sign in to chat',
          ),
        ),
      ),
    );

    expect(find.text('Chat is read-only'), findsOneWidget);
    await tester.tap(find.text('Sign in to chat'));
    expect(reloginTapped, isTrue);
  });

  testWidgets(
    'signed out: author tap opens the user card with a placeholder avatar '
    'and no fetch attempt',
    (tester) async {
      store.chatConnection = KickChatConnectionState.connected;
      store.messages.add(kickMessage('m1', senderId: 7, username: 'Viewer1'));
      await tester.pumpWidget(wrap());
      await tester.pump();

      await tester.tap(find.text('Viewer1').first);
      await tester.pumpAndSettle();

      expect(find.byType(KickUserCardSheet), findsOneWidget);
      expect(apiService.fetchUserCalls, isEmpty);
      expect(find.byIcon(CupertinoIcons.person_fill), findsOneWidget);
    },
  );

  testWidgets(
    'signed in: author tap fetches the profile and renders the avatar',
    (tester) async {
      await signIn(tester);
      apiService.fetchUserResult = const KickUserIdentity(
        userId: 7,
        name: 'Viewer1',
        profilePicture: 'https://example.com/avatar.png',
      );
      store.chatConnection = KickChatConnectionState.connected;
      store.messages.add(kickMessage('m1', senderId: 7, username: 'Viewer1'));
      await tester.pumpWidget(wrap());
      await tester.pump();

      await tester.tap(find.text('Viewer1').first);
      await tester.pumpAndSettle();

      expect(find.byType(KickUserCardSheet), findsOneWidget);
      expect(apiService.fetchUserCalls, [7]);
      expect(find.byIcon(CupertinoIcons.person_fill), findsNothing);
    },
  );

  testWidgets('the /clear system row has no author tap target', (tester) async {
    store.chatConnection = KickChatConnectionState.connected;
    store.messages.add(
      KickChatMessage(
        id: 'system-clear-1',
        type: KickChatMessageType.system,
        createdAt: DateTime.utc(2026, 9, 22, 12),
      ),
    );
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('Chat was cleared by a moderator'));
    await tester.pumpAndSettle();

    expect(find.byType(KickUserCardSheet), findsNothing);
  });
}
