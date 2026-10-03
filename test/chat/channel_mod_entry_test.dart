import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_engine.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/channel_mod_button.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/chat_username_bar.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/channel_mod_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_options_sheet.dart';

import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/native_channel_dropdown.dart';
import '../persistence/support/hive_test_harness.dart';
import '../pro/support/fake_pro_purchase_gateway.dart';
import 'support/fake_twitch_services.dart';

const _modScopes = [
  'user:read:chat',
  'user:write:chat',
  'moderator:manage:chat_messages',
  'moderator:manage:banned_users',
];

Finder shieldFinder() => find.byWidgetPredicate(
  (w) =>
      w is Icon &&
      (w.icon == CupertinoIcons.shield || w.icon == CupertinoIcons.shield_fill),
);

Widget wrap(Widget child, {double width = 800}) => MaterialApp(
  theme: ThemeData(cupertinoOverrideTheme: const CupertinoThemeData()),
  home: MediaQuery(
    data: const MediaQueryData(textScaler: TextScaler.linear(0.8)),
    child: Scaffold(
      body: SizedBox(width: width, child: child),
    ),
  ),
);

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late TwitchChatStore store;
  late ProStore proStore;

  Box<dynamic> settingsBox() => Hive.box(HiveKeys.Settings.name);
  Box<TwitchAuth> authBox() => Hive.box<TwitchAuth>(HiveKeys.TwitchAuth.name);

  Future<void> seedLoggedIn({List<String> scopes = _modScopes}) async {
    await authBox().put(
      TwitchAuth.kBoxKey,
      TwitchAuth(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3_600_000,
        scopes: scopes,
      ),
    );
    store.authState = TwitchAuthState.loggedIn;
    store.user = FakeTwitchAuthService.user;
    store.chatConnection = TwitchChatConnectionState.live;
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('channel_mod_entry_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);

    /// Entitlement: the username bar's native cluster is Pro-gated, so
    /// seed the real flag and register the real store reading it. The
    /// cold-start restore is skipped so no store call fires.
    await settingsBox().put(SettingsKeys.BoughtPro.name, true);
    await settingsBox().put(SettingsKeys.ProColdStartRestoreDone.name, true);
    proStore = ProStore(
      service: ProPurchaseService(gateway: FakeProPurchaseGateway()),
    )..init();
    GetIt.instance.registerSingleton<ProStore>(proStore);

    store = TwitchChatStore(
      authService: FakeTwitchAuthService(),
      ircSidecarFactory: (_) => FakeSilentIrcSidecar(),
      eventSubFactory:
          (
            _,
            __,
            ___,
            ____,
            _____,
            ______,
            _______,
            ________,
            _________,
            __________,
          ) => FakeTwitchEventSubService(),
    );
    GetIt.instance.registerSingleton<TwitchChatStore>(store);
    GetIt.instance.registerSingleton<ThirdPartyEmoteStore>(
      ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService()),
    );
  });

  tearDown(() async {
    store.dispose();
    proStore.dispose();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets(
    'wide cluster with short name shows shield and gear-only options',
    (tester) async {
      await tester.runAsync(() async {
        await seedLoggedIn();
        await settingsBox().put(
          SettingsKeys.SelectedChatType.name,
          ChatType.Twitch,
        );
        await settingsBox().put(
          SettingsKeys.SelectedChatEngine.name,
          ChatEngine.native,
        );
      });

      await tester.pumpWidget(wrap(const ChatUsernameBar(), width: 800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(store.canModerateSelectedChannel, isTrue);
      expect(shieldFinder(), findsOneWidget);
      expect(find.byType(ChannelModButton), findsOneWidget);
      final options = tester.widget<NativeChatOptionsButton>(
        find.byType(NativeChatOptionsButton),
      );
      expect(options.modFoldedIntoOptions, isFalse);
    },
  );

  testWidgets('a long display name keeps the shield (no account chip in '
      'the signed-in bar)', (tester) async {
    await tester.runAsync(() async {
      await seedLoggedIn();
      store.user = const TwitchUser(
        id: 'user-1',
        login: 'verylongdisplayname',
        displayName: 'VeryLongDisplayNameThatCannotFit',
      );
      await settingsBox().put(
        SettingsKeys.SelectedChatType.name,
        ChatType.Twitch,
      );
      await settingsBox().put(
        SettingsKeys.SelectedChatEngine.name,
        ChatEngine.native,
      );
    });

    await tester.pumpWidget(wrap(const ChatUsernameBar(), width: 400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(store.canModerateSelectedChannel, isTrue);
    expect(find.byType(ChannelModButton), findsOneWidget);
    expect(
      tester
          .widget<NativeChatOptionsButton>(find.byType(NativeChatOptionsButton))
          .modFoldedIntoOptions,
      isFalse,
    );
  });

  testWidgets('native: the channel dropdown fills the row next to the '
      'shield + options, at phone and tablet widths', (tester) async {
    await tester.runAsync(() async {
      await seedLoggedIn();
      await settingsBox().put(
        SettingsKeys.SelectedChatType.name,
        ChatType.Twitch,
      );
      await settingsBox().put(
        SettingsKeys.SelectedChatEngine.name,
        ChatEngine.native,
      );
    });

    for (final width in [320.0, 400.0, 800.0]) {
      await tester.pumpWidget(wrap(const ChatUsernameBar(), width: width));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final dropdown = tester.getRect(find.byType(NativeChannelDropdown));
      final shield = tester.getRect(find.byType(ChannelModButton));
      final options = tester.getRect(find.byType(NativeChatOptionsButton));

      /// Dropdown from the left edge up to the shield (one gap), shield
      /// then options flush right - no space left unused.
      expect(dropdown.left, 0.0, reason: 'width $width');
      expect(shield.left - dropdown.right, AppSpacing.sm, reason: '$width');
      expect(options.left - shield.right, AppSpacing.sm, reason: '$width');
      expect(options.right, width, reason: 'width $width');
    }
  });

  testWidgets('native signed out: no dropdown, options + Connect pill hug '
      'the right edge', (tester) async {
    await tester.runAsync(() async {
      await settingsBox().put(
        SettingsKeys.SelectedChatType.name,
        ChatType.Twitch,
      );
      await settingsBox().put(
        SettingsKeys.SelectedChatEngine.name,
        ChatEngine.native,
      );
    });

    await tester.pumpWidget(wrap(const ChatUsernameBar(), width: 400));
    await tester.pump();

    expect(find.byType(NativeChannelDropdown), findsNothing);
    final options = tester.getRect(find.byType(NativeChatOptionsButton));
    final pill = tester.getRect(find.text('Connect Twitch'));
    expect(pill.right, lessThanOrEqualTo(400.0));
    expect(
      pill.left - options.right,
      lessThan(AppSpacing.sm + AppSpacing.lg + 1),
      reason: 'the pill sits next to the options (gap + its own padding)',
    );
  });

  test('Mod folds into options only below shield + options (96pt)', () {
    expect(nativeModClusterFitsWithShield(maxWidth: 96.0), isTrue);
    expect(nativeModClusterFitsWithShield(maxWidth: 95.0), isFalse);
  });

  testWidgets(
    'folded options sheet shows featured Mod card; tap opens ChannelModSheet',
    (tester) async {
      await tester.runAsync(() async {
        await seedLoggedIn();
      });

      await tester.pumpWidget(
        wrap(
          const NativeChatOptionsSheet(
            chatType: ChatType.Twitch,
            modFoldedIntoOptions: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Channel moderation'), findsOneWidget);
      expect(find.text('Moderation…'), findsNothing);

      await tester.tap(find.text('Channel moderation'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ChannelModSheet), findsOneWidget);
    },
  );

  testWidgets(
    'options sheet omits Mod when shield is on the bar (not folded)',
    (tester) async {
      await tester.runAsync(() async {
        await seedLoggedIn();
      });

      await tester.pumpWidget(
        wrap(
          const NativeChatOptionsSheet(
            chatType: ChatType.Twitch,
            modFoldedIntoOptions: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Channel moderation'), findsNothing);
      expect(find.text('Moderation…'), findsNothing);
    },
  );

  testWidgets('WebView engine shows no shield', (tester) async {
    await tester.runAsync(() async {
      await seedLoggedIn();
      await settingsBox().put(
        SettingsKeys.SelectedChatType.name,
        ChatType.Twitch,
      );
      await settingsBox().put(
        SettingsKeys.SelectedChatEngine.name,
        ChatEngine.webView,
      );
    });

    await tester.pumpWidget(wrap(const ChatUsernameBar(), width: 800));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(shieldFinder(), findsNothing);
    expect(find.byType(ChannelModButton), findsNothing);
    expect(find.byType(NativeChatOptionsButton), findsNothing);
  });

  testWidgets('not moderating → no shield, no combined chip, no Mod card', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await seedLoggedIn(scopes: const ['user:read:chat']);
      store.user = const TwitchUser(
        id: 'user-1',
        login: 'verylongdisplayname',
        displayName: 'VeryLongDisplayNameThatCannotFit',
      );
      await settingsBox().put(
        SettingsKeys.SelectedChatType.name,
        ChatType.Twitch,
      );
      await settingsBox().put(
        SettingsKeys.SelectedChatEngine.name,
        ChatEngine.native,
      );
    });

    /// Same tight width that folds Mod for moderators — must stay gear-only.
    await tester.pumpWidget(wrap(const ChatUsernameBar(), width: 400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(store.canModerateSelectedChannel, isFalse);
    expect(find.byType(ChannelModButton), findsNothing);
    final options = tester.widget<NativeChatOptionsButton>(
      find.byType(NativeChatOptionsButton),
    );
    expect(options.modFoldedIntoOptions, isFalse);
    expect(
      find.descendant(
        of: find.byType(NativeChatOptionsButton),
        matching: shieldFinder(),
      ),
      findsNothing,
    );

    await tester.pumpWidget(
      wrap(
        const NativeChatOptionsSheet(
          chatType: ChatType.Twitch,
          modFoldedIntoOptions: true,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Channel moderation'), findsNothing);
    expect(find.text('Moderation…'), findsNothing);
  });
}
