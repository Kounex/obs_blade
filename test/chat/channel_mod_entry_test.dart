import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_engine.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/channel_mod_button.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/chat_username_bar.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/channel_mod_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_options_sheet.dart';

import '../persistence/support/hive_test_harness.dart';
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
          (w.icon == CupertinoIcons.shield ||
              w.icon == CupertinoIcons.shield_fill));

Widget wrap(Widget child, {double width = 800}) => MaterialApp(
      theme: ThemeData(cupertinoOverrideTheme: const CupertinoThemeData()),
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(0.8)),
        child: Scaffold(
          body: SizedBox(
            width: width,
            child: child,
          ),
        ),
      ),
    );

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late TwitchChatStore store;

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
    store = TwitchChatStore(
      authService: FakeTwitchAuthService(),
      eventSubFactory: (_, __, ___, ____, _____, ______, _______, ________, _________, __________) =>
          FakeTwitchEventSubService(),
    );
    GetIt.instance.registerSingleton<TwitchChatStore>(store);
    GetIt.instance.registerSingleton<ThirdPartyEmoteStore>(
        ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService()));
  });

  tearDown(() async {
    store.dispose();
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
      await settingsBox()
          .put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
      await settingsBox()
          .put(SettingsKeys.SelectedChatEngine.name, ChatEngine.native);
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
  });

  testWidgets(
      'narrow cluster folds Mod into a combined options chip',
      (tester) async {
    await tester.runAsync(() async {
      await seedLoggedIn();
      store.user = const TwitchUser(
        id: 'user-1',
        login: 'verylongdisplayname',
        displayName: 'VeryLongDisplayNameThatCannotFit',
      );
      await settingsBox()
          .put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
      await settingsBox()
          .put(SettingsKeys.SelectedChatEngine.name, ChatEngine.native);
    });

    /// Long display name + mid width: three controls do not fit the right
    /// cluster; options + (compressed) account still do.
    await tester.pumpWidget(wrap(const ChatUsernameBar(), width: 400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(store.canModerateSelectedChannel, isTrue);
    expect(find.byType(ChannelModButton), findsNothing);
    final options = tester.widget<NativeChatOptionsButton>(
      find.byType(NativeChatOptionsButton),
    );
    expect(options.modFoldedIntoOptions, isTrue);
    /// Combined chip: gear + shield inside the options control.
    expect(
      find.descendant(
        of: find.byType(NativeChatOptionsButton),
        matching: find.byIcon(CupertinoIcons.slider_horizontal_3),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(NativeChatOptionsButton),
        matching: shieldFinder(),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'folded options sheet shows featured Mod card; tap opens ChannelModSheet',
      (tester) async {
    await tester.runAsync(() async {
      await seedLoggedIn();
    });

    await tester.pumpWidget(
      wrap(const NativeChatOptionsSheet(
        chatType: ChatType.Twitch,
        modFoldedIntoOptions: true,
      )),
    );
    await tester.pump();

    expect(find.text('Channel moderation'), findsOneWidget);
    expect(find.text('Moderation…'), findsNothing);

    await tester.tap(find.text('Channel moderation'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ChannelModSheet), findsOneWidget);
  });

  testWidgets(
      'options sheet omits Mod when shield is on the bar (not folded)',
      (tester) async {
    await tester.runAsync(() async {
      await seedLoggedIn();
    });

    await tester.pumpWidget(
      wrap(const NativeChatOptionsSheet(
        chatType: ChatType.Twitch,
        modFoldedIntoOptions: false,
      )),
    );
    await tester.pump();

    expect(find.text('Channel moderation'), findsNothing);
    expect(find.text('Moderation…'), findsNothing);
  });

  testWidgets('WebView engine shows no shield', (tester) async {
    await tester.runAsync(() async {
      await seedLoggedIn();
      await settingsBox()
          .put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
      await settingsBox()
          .put(SettingsKeys.SelectedChatEngine.name, ChatEngine.webView);
    });

    await tester.pumpWidget(wrap(const ChatUsernameBar(), width: 800));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(shieldFinder(), findsNothing);
    expect(find.byType(ChannelModButton), findsNothing);
    expect(find.byType(NativeChatOptionsButton), findsNothing);
  });

  testWidgets(
      'not moderating → no shield, no combined chip, no Mod card',
      (tester) async {
    await tester.runAsync(() async {
      await seedLoggedIn(scopes: const ['user:read:chat']);
      store.user = const TwitchUser(
        id: 'user-1',
        login: 'verylongdisplayname',
        displayName: 'VeryLongDisplayNameThatCannotFit',
      );
      await settingsBox()
          .put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
      await settingsBox()
          .put(SettingsKeys.SelectedChatEngine.name, ChatEngine.native);
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
      wrap(const NativeChatOptionsSheet(
        chatType: ChatType.Twitch,
        modFoldedIntoOptions: true,
      )),
    );
    await tester.pump();
    expect(find.text('Channel moderation'), findsNothing);
    expect(find.text('Moderation…'), findsNothing);
  });
}
