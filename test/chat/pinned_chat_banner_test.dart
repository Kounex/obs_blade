import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/pinned_chat_banner.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';

ChatMessageEvent chatMessage(String id, String chatterId) => ChatMessageEvent(
      broadcasterUserId: 'user-1',
      chatterUserId: chatterId,
      chatterUserLogin: 'user$chatterId',
      chatterUserName: 'User$chatterId',
      messageId: id,
      message: ChatMessageText(
        text: 'text $id',
        fragments: [ChatMessageFragment(type: 'text', text: 'text $id')],
      ),
    );

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeTwitchAuthService authService;
  late FakeTwitchEventSubService eventSubService;
  late FakeTwitchModerationService moderationService;
  late TwitchChatStore store;

  Future<void> pumpBanner(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinnedChatBanner(
            pinned: FakeTwitchModerationService.pinnedSample,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pinned_banner_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
    authService = FakeTwitchAuthService();
    authService.tokenScopes = const [
      'user:read:chat',
      'user:write:chat',
      'moderator:manage:chat_messages',
      'moderator:manage:banned_users',
    ];
    eventSubService = FakeTwitchEventSubService();
    moderationService = FakeTwitchModerationService();
    store = TwitchChatStore(
      authService: authService,
      eventSubFactory: (_, __, ___, ____, _____, ______, _______, ________) =>
          eventSubService,
      badgeStoreResolver: () =>
          TwitchBadgeStore(service: FakeTwitchBadgeService()),
      moderationService: moderationService,
    );
    await store.startLogin();
    store.chatConnection = TwitchChatConnectionState.live;
    GetIt.instance.registerSingleton<TwitchChatStore>(store);
    GetIt.instance.registerSingleton<TwitchBadgeStore>(
        TwitchBadgeStore(service: FakeTwitchBadgeService()));
    GetIt.instance.registerSingleton<ThirdPartyEmoteStore>(
        ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService()));
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await store.dispose();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('renders sender and pinned text; mods get the unpin button',
      (tester) async {
    await pumpBanner(tester);

    expect(find.textContaining('Chatter:'), findsOneWidget);
    expect(find.textContaining('remember the giveaway'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.pin_fill), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
  });

  testWidgets('the unpin button confirms, then unpins via the store',
      (tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(store.pinnedMessage?.messageId, 'msg-pinned');

    await pumpBanner(tester);
    await tester.tap(find.byIcon(CupertinoIcons.xmark));
    await tester.pumpAndSettle();

    expect(find.text('Unpin this message?'), findsOneWidget);
    expect(moderationService.unpinCalls, 0);

    await tester.tap(find.text('Unpin'));
    await tester.pumpAndSettle();

    expect(moderationService.unpinCalls, 1);
    expect(moderationService.lastUnpinMessageId, 'msg-pinned');
    expect(store.pinnedMessage, isNull);
  });

  testWidgets('cancelling the unpin confirmation keeps the pin',
      (tester) async {
    await pumpBanner(tester);
    await tester.tap(find.byIcon(CupertinoIcons.xmark));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(moderationService.unpinCalls, 0);
    expect(store.pinnedMessage?.messageId, 'msg-pinned');
    expect(find.text('Unpin this message?'), findsNothing);
  });

  testWidgets('collapsed shows one muted line; tapping expands to active',
      (tester) async {
    await pumpBanner(tester);

    final context = tester.element(find.byType(PinnedChatBanner));
    final theme = Theme.of(context);
    RichText bannerText() => tester
        .widgetList<RichText>(find.byType(RichText))
        .firstWhere((rich) => rich.text.toPlainText().contains('Chatter:'));

    /// Text.rich wraps the given span in a root span carrying the merged
    /// default style — the banner's name/body spans live two levels down.
    TextSpan outerSpan() =>
        (bannerText().text as TextSpan).children!.first as TextSpan;
    TextSpan nameSpan() => outerSpan().children!.first as TextSpan;
    TextSpan bodySpan() => outerSpan().children!.last as TextSpan;

    /// Collapsed: one line, muted name and body.
    expect(bannerText().maxLines, 1);
    expect(nameSpan().style?.color, theme.textTheme.bodySmall?.color);
    expect(bodySpan().style?.color, theme.textTheme.bodySmall?.color);

    await tester.tap(find.textContaining('remember the giveaway'));
    await tester.pump();

    /// Expanded: no line cap, accent name, normal-contrast body.
    expect(bannerText().maxLines, isNull);
    expect(nameSpan().style?.color, theme.colorScheme.secondary);
    expect(bodySpan().style?.color, theme.textTheme.bodyMedium?.color);

    await tester.tap(find.textContaining('remember the giveaway'));
    await tester.pump();

    expect(bannerText().maxLines, 1);
    expect(nameSpan().style?.color, theme.textTheme.bodySmall?.color);
  });

  testWidgets('non-mods get no unpin button', (tester) async {
    store.selectedChannelId = 'chan-other';

    await pumpBanner(tester);

    expect(find.textContaining('remember the giveaway'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.xmark), findsNothing);
  });

  testWidgets('the chat view shows the banner above the timeline',
      (tester) async {
    store.appendChatMessageForTest(chatMessage('m1', 'u1'));

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: NativeTwitchChatView())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PinnedChatBanner), findsOneWidget);
    expect(find.textContaining('remember the giveaway'), findsOneWidget);
    expect(find.textContaining('text m1'), findsOneWidget);
  });

  testWidgets('the chat view hides the banner when nothing is pinned',
      (tester) async {
    moderationService.pinnedMessageResult = null;
    store.pinnedMessage = null;
    store.appendChatMessageForTest(chatMessage('m1', 'u1'));

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: NativeTwitchChatView())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PinnedChatBanner), findsNothing);
    expect(find.textContaining('text m1'), findsOneWidget);
  });

  testWidgets('unpin clears the banner in place (no other store event)',
      (tester) async {
    store.appendChatMessageForTest(chatMessage('m1', 'u1'));

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: NativeTwitchChatView())),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PinnedChatBanner), findsOneWidget);

    /// Regression: this must rebuild the view through the pinnedMessage
    /// observable alone — a stale store .g.dart (missing atoms) left the
    /// banner on screen until an unrelated timeline event forced a
    /// rebuild.
    await store.unpinMessage();
    await tester.pump();

    expect(store.pinnedMessage, isNull);
    expect(find.byType(PinnedChatBanner), findsNothing);
    expect(find.textContaining('text m1'), findsOneWidget);
  });
}
