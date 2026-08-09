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
import 'package:obs_blade/types/classes/twitch/chat_settings.dart';
import 'package:obs_blade/types/classes/twitch/chat_system_notice.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_irc_sidecar.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/channel_mod_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_text_field.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_device_code_dialog.dart';

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

const _fullRoomScopes = [
  'user:read:chat',
  'user:write:chat',
  'moderator:manage:chat_messages',
  'moderator:manage:banned_users',
  'moderator:manage:chat_settings',
  'moderator:manage:shield_mode',
  'moderator:manage:announcements',
];

const _clearOnlyScopes = [
  'user:read:chat',
  'user:write:chat',
  'moderator:manage:chat_messages',
  'moderator:manage:banned_users',
];

/// No-op IRC sidecar so widget tests never open a real Twitch WS
/// (and never spin a reconnect loop).
class _SilentIrcSidecar extends TwitchIrcSidecar {
  _SilentIrcSidecar()
      : super(
          onFirstMessage: (_) {},
          channelFactory: (_) => throw StateError('IRC disabled in tests'),
          sleep: (_) async {},
        );

  @override
  Future<void> connect({
    required String accessToken,
    required String login,
    required String channelLogin,
  }) async {}

  @override
  Future<void> switchChannel(String channelLogin) async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeTwitchAuthService authService;
  late FakeTwitchEventSubService eventSubService;
  late FakeTwitchModerationService moderationService;
  late TwitchChatStore store;

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await settle(tester);
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showChannelModSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
    // Let refreshRoomModState finish and rebuild the sheet.
    await settle(tester);
  }

  Future<void> login({List<String> scopes = _fullRoomScopes}) async {
    authService.tokenScopes = scopes;
    store = TwitchChatStore(
      authService: authService,
      eventSubFactory: (_, __, ___, ____, _____, ______, _______, ________) =>
          eventSubService,
      badgeStoreResolver: () =>
          TwitchBadgeStore(service: FakeTwitchBadgeService()),
      moderationService: moderationService,
      channelService: FakeTwitchChannelService(),
      ircSidecarFactory: (_) => _SilentIrcSidecar(),
    );
    await store.startLogin();
    store.chatConnection = TwitchChatConnectionState.live;
    if (GetIt.instance.isRegistered<TwitchChatStore>()) {
      await GetIt.instance.reset();
    }
    GetIt.instance.registerSingleton<TwitchChatStore>(store);
    GetIt.instance.registerSingleton<TwitchBadgeStore>(
        TwitchBadgeStore(service: FakeTwitchBadgeService()));
    GetIt.instance.registerSingleton<ThirdPartyEmoteStore>(
        ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService()));
  }

  Future<void> harnessSetUp({List<String> scopes = _fullRoomScopes}) async {
    tempDir = await Directory.systemTemp.createTemp('channel_mod_sheet_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
    authService = FakeTwitchAuthService();
    eventSubService = FakeTwitchEventSubService();
    moderationService = FakeTwitchModerationService();
    await login(scopes: scopes);
  }

  Future<void> harnessTearDown() async {
    await GetIt.instance.reset();
    await store.dispose();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }

  group('full room scopes', () {
    setUp(() => harnessSetUp());
    tearDown(harnessTearDown);

  testWidgets('open sheet shows channel title and sections', (tester) async {
    await openSheet(tester);

    expect(find.textContaining('Moderate'), findsOneWidget);
    expect(find.textContaining('kounex'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Modes'), findsOneWidget);
    expect(find.text('Shield'), findsOneWidget);
    expect(find.text('Announce'), findsOneWidget);
    expect(find.text('Clear chat'), findsOneWidget);
    expect(find.textContaining('Emote'), findsOneWidget);
    expect(moderationService.getSettingsCalls, 1);
    expect(moderationService.getShieldCalls, 1);
  });

  testWidgets('Clear → confirm → Helix clear, local clear, sheet closes',
      (tester) async {
    store.appendChatMessageForTest(chatMessage('m1', 'u1'));
    store.appendChatMessageForTest(chatMessage('m2', 'u2'));

    await openSheet(tester);
    await tapVisible(tester, find.text('Clear chat'));

    expect(find.textContaining('Clear'), findsWidgets);
    expect(moderationService.clearCalls, 0);

    await tapVisible(tester, find.text('Clear').last);

    expect(moderationService.clearCalls, 1);
    expect(moderationService.lastClearBroadcasterId, 'user-1');
    expect(store.isMessageDeleted('m1'), isTrue);
    expect(store.isMessageDeleted('m2'), isTrue);
    expect(store.systemNotices.single.kind, ChatSystemNoticeKind.chatCleared);
    expect(find.byType(ChannelModSheet), findsNothing);
  });

  testWidgets('canceling Clear confirm leaves sheet open and skips Helix',
      (tester) async {
    store.appendChatMessageForTest(chatMessage('m1', 'u1'));

    await openSheet(tester);
    await tapVisible(tester, find.text('Clear chat'));
    await tapVisible(tester, find.text('Cancel'));

    expect(moderationService.clearCalls, 0);
    expect(store.isMessageDeleted('m1'), isFalse);
    expect(find.byType(ChannelModSheet), findsOneWidget);
    expect(find.text('Clear chat'), findsOneWidget);
  });

  testWidgets('toggle emote-only off→on confirms then updates settings',
      (tester) async {
    moderationService.chatSettings = const TwitchChatSettings(
      emoteMode: false,
      followerMode: false,
      followerModeDurationMinutes: null,
      subscriberMode: false,
      slowMode: false,
      slowModeWaitTimeSeconds: null,
      uniqueChatMode: false,
    );
    store.roomChatSettings = moderationService.chatSettings;

    await openSheet(tester);
    await tapVisible(tester, find.textContaining('Emote'));

    expect(moderationService.updateSettingsCalls, 0);
    await tapVisible(tester, find.text('Enable').last);

    expect(moderationService.updateSettingsCalls, 1);
    expect(moderationService.lastUpdateEmoteMode, isTrue);
    expect(store.roomChatSettings?.emoteMode, isTrue);
    expect(find.byType(ChannelModSheet), findsOneWidget);
  });

  testWidgets('followers-only enable → preset → confirm with minutes',
      (tester) async {
    moderationService.chatSettings = const TwitchChatSettings(
      emoteMode: false,
      followerMode: false,
      followerModeDurationMinutes: null,
      subscriberMode: false,
      slowMode: false,
      slowModeWaitTimeSeconds: null,
      uniqueChatMode: false,
    );
    store.roomChatSettings = moderationService.chatSettings;

    await openSheet(tester);
    await tapVisible(tester, find.textContaining('Followers'));

    expect(find.byIcon(CupertinoIcons.chevron_back), findsOneWidget);
    expect(find.text('10 minutes'), findsOneWidget);
    expect(moderationService.updateSettingsCalls, 0);

    await tapVisible(tester, find.text('10 minutes'));

    expect(find.textContaining('Followers'), findsWidgets);
    await tapVisible(tester, find.text('Enable').last);

    expect(moderationService.updateSettingsCalls, 1);
    expect(moderationService.lastUpdateFollowerMode, isTrue);
    expect(moderationService.lastUpdateFollowerDurationMinutes, 10);
  });

  testWidgets('Shield on → confirm → update shield', (tester) async {
    moderationService.shieldModeActive = false;
    store.roomShieldModeActive = false;

    await openSheet(tester);
    await tapVisible(tester, find.textContaining('Shield Mode'));

    expect(moderationService.updateShieldCalls, 0);
    await tapVisible(tester, find.text('Enable').last);

    expect(moderationService.updateShieldCalls, 1);
    expect(moderationService.lastShieldIsActive, isTrue);
    expect(store.roomShieldModeActive, isTrue);
  });

  testWidgets('Announce compose Send with color closes sheet', (tester) async {
    await openSheet(tester);
    await tapVisible(tester, find.text('Announce…'));

    expect(find.byIcon(CupertinoIcons.chevron_back), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);

    /// Empty → Send disabled.
    await tester.tap(find.text('Send'));
    await settle(tester);
    expect(moderationService.announceCalls, 0);

    expect(find.byType(NativeChatTextField), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(NativeChatTextField),
        matching: find.byType(TextField),
      ),
      'Hello chat',
    );
    await tester.pump();
    await tapVisible(tester, find.text('blue'));
    await tapVisible(tester, find.text('Send'));

    expect(moderationService.announceCalls, 1);
    expect(moderationService.lastAnnounceMessage, 'Hello chat');
    expect(moderationService.lastAnnounceColor, 'blue');
    expect(find.byType(ChannelModSheet), findsNothing);
  });
  });

  group('clear-only scopes', () {
    setUp(() => harnessSetUp(scopes: _clearOnlyScopes));
    tearDown(harnessTearDown);

    testWidgets(
        'missing manage scopes: modes/shield/announce re-login; Clear works',
        (tester) async {
      /// Next device-code poll fails so the re-login dialog stays open.
      authService.failPollWith = const TwitchAuthException('denied');
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));

      await openSheet(tester);
      expect(find.text('Clear chat'), findsOneWidget);
      expect(find.textContaining('Emote'), findsOneWidget);

      await tapVisible(tester, find.textContaining('Emote'));

      expect(moderationService.updateSettingsCalls, 0);
      expect(find.byType(TwitchDeviceCodeDialog), findsOneWidget);

      Navigator.of(tester.element(find.byType(TwitchDeviceCodeDialog))).pop();
      store.cancelLogin();
      await settle(tester);

      await tapVisible(tester, find.text('Clear chat'));
      await tapVisible(tester, find.text('Clear').last);

      expect(moderationService.clearCalls, 1);
      expect(store.isMessageDeleted('m1'), isTrue);
      expect(find.byType(ChannelModSheet), findsNothing);
    });
  });
}
