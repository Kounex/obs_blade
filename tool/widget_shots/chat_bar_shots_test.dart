import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_engine.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/models/kick_auth.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/models/youtube_auth.dart';
import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/types/classes/twitch/twitch_channel_ref.dart';
import 'package:obs_blade/utils/youtube_target.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/kick/kick_auth_service.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/youtube/youtube_auth_service.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/chat_username_bar.dart';

import '../../test/chat/support/fake_kick_services.dart';
import '../../test/chat/support/fake_twitch_services.dart';
import '../../test/chat/support/fake_youtube_services.dart';
import '../../test/pro/support/fake_pro_purchase_gateway.dart';
import 'support/shots_harness.dart';

/// The native chat bar signed in on each platform, phone + narrow: no
/// account chip (the account lives in the chat header's sheet), so the
/// mod shield fits next to the options.
void main() {
  final harness = ShotsHarness();
  late TwitchChatStore twitch;
  late YouTubeChatStore youTube;
  late KickChatStore kick;

  setUpAll(ShotsHarness.loadFonts);
  setUp(() async {
    await harness.setUp();
    final settings = Hive.box(HiveKeys.Settings.name);
    await settings.put(SettingsKeys.BoughtPro.name, true);
    await settings.put(SettingsKeys.ProColdStartRestoreDone.name, true);
    await settings.put(SettingsKeys.SelectedChatEngine.name, ChatEngine.native);
    await settings.put(SettingsKeys.YouTubeApiKey.name, 'api-key');
    final expires = DateTime.now().millisecondsSinceEpoch + 3600000;
    await Hive.box<TwitchAuth>(HiveKeys.TwitchAuth.name).put(
      TwitchAuth.kBoxKey,
      TwitchAuth(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtMs: expires,
        scopes: kTwitchChatScopes,
        userId: FakeTwitchAuthService.user.id,
        userLogin: FakeTwitchAuthService.user.login,
        userDisplayName: FakeTwitchAuthService.user.displayName,
      ),
    );
    await Hive.box<YouTubeAuth>(HiveKeys.YouTubeAuth.name).put(
      YouTubeAuth.kBoxKey,
      YouTubeAuth(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtMs: expires,
        scopes: kYouTubeChatScopes,
        channelTitle: 'My Channel With A Long Title',
        channelId: 'UCownchannel000000000000',
      ),
    );
    await Hive.box<KickAuth>(HiveKeys.KickAuth.name).put(
      KickAuth.kBoxKey,
      KickAuth(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtMs: expires,
        scopes: kKickChatScopes,
        userId: 9001,
        username: 'kounex',
        channelSlug: 'kounex',
      ),
    );

    final pro = ProStore(
      service: ProPurchaseService(gateway: FakeProPurchaseGateway()),
    )..init();
    twitch =
        TwitchChatStore(
            authService: FakeTwitchAuthService(),
            isProResolver: () => true,
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
            ircSidecarFactory: (_) => FakeSilentIrcSidecar(),
          )
          ..authState = TwitchAuthState.loggedIn
          ..user = FakeTwitchAuthService.user;
    youTube = YouTubeChatStore(
      authService: FakeYouTubeAuthService(),
      chatService: FakeYouTubeLiveChatService(),
      isProResolver: () => false,
    )..authState = YouTubeAuthState.signedIn;
    kick =
        KickChatStore(
            channelService: FakeKickChannelService(),
            isProResolver: () => false,
          )
          ..authState = KickAuthState.signedIn
          ..ownChannelSlug = 'kounex';
    GetIt.instance
      ..registerSingleton<ProStore>(pro)
      ..registerSingleton<TwitchChatStore>(twitch)
      ..registerSingleton<YouTubeChatStore>(youTube)
      ..registerSingleton<KickChatStore>(kick)
      ..registerSingleton<DashboardStore>(DashboardStore())
      ..registerSingleton<ThirdPartyEmoteStore>(
        ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService()),
      );
  });
  tearDown(() async {
    await GetIt.instance.reset();
    await harness.tearDown();
  });

  Widget bar() => const Padding(
    padding: EdgeInsets.all(AppSpacing.lg),
    child: Align(alignment: Alignment.topCenter, child: ChatUsernameBar()),
  );

  for (final type in [ChatType.Twitch, ChatType.YouTube, ChatType.Kick]) {
    testWidgets('${type.name} signed in', (tester) async {
      await tester.runAsync(
        () => Hive.box(
          HiveKeys.Settings.name,
        ).put(SettingsKeys.SelectedChatType.name, type),
      );
      await harness.shot(tester, 'chat_bar_${type.name.toLowerCase()}', bar());
      await harness.shot(
        tester,
        'chat_bar_${type.name.toLowerCase()}_narrow',
        bar(),
        size: const Size(320, 640),
      );
    });
  }

  /// A long channel name selected on each platform - the native dropdown
  /// fills the row next to the shield + options.
  void selectLongChannels() {
    runInAction(() {
      twitch.channels.add(
        TwitchChannelRef(
          id: '77',
          login: 'averyveryverylongtwitchname',
          displayName: 'AVeryVeryVeryLongTwitchName',
          addedAt: DateTime.utc(2026, 10, 3),
        ),
      );
      twitch.selectedChannelId = '77';
      youTube.channels.add(
        const YouTubeChatChannel(
          label: 'Markiplier Clips and Highlights',
          target: YouTubeChannelTarget('@markiplierclips'),
        ),
      );
      youTube.selectedChannelLabel = 'Markiplier Clips and Highlights';
      kick.channels.addAll(['xqcow-waiting-room-x', 'trainwreckstv']);
      kick.selectedChannelSlug = 'xqcow-waiting-room-x';
      kick.channelLivePreview['xqcow-waiting-room-x'] = const KickChannelInfo(
        id: 1,
        slug: 'xqcow-waiting-room-x',
        chatroom: KickChatroom(id: 2),
        livestream: KickLivestreamInfo(isLive: true, viewerCount: 12400),
      );
      kick.channelLivePreview['trainwreckstv'] = const KickChannelInfo(
        id: 3,
        slug: 'trainwreckstv',
        chatroom: KickChatroom(id: 4),
      );
    });
  }

  for (final type in [ChatType.Twitch, ChatType.YouTube, ChatType.Kick]) {
    testWidgets('${type.name} long channel name (phone, narrow, tablet)', (
      tester,
    ) async {
      await tester.runAsync(
        () => Hive.box(
          HiveKeys.Settings.name,
        ).put(SettingsKeys.SelectedChatType.name, type),
      );
      selectLongChannels();
      final name = 'chat_bar_${type.name.toLowerCase()}_long';
      await harness.shot(tester, name, bar());
      await harness.shot(
        tester,
        '${name}_narrow',
        bar(),
        size: const Size(320, 640),
      );
      await harness.shot(tester, '${name}_tablet', bar(), size: kShotTablet);
    });
  }

  testWidgets('Kick open channel menu: LIVE chips get the row width', (
    tester,
  ) async {
    await tester.runAsync(
      () => Hive.box(
        HiveKeys.Settings.name,
      ).put(SettingsKeys.SelectedChatType.name, ChatType.Kick),
    );
    selectLongChannels();
    await harness.shot(tester, 'chat_bar_kick_menu_closed', bar());
    await tester.tap(find.text('xqcow-waiting-room-x').first);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../build/widget_shots/chat_bar_kick_menu_open.png'),
    );
  });

  testWidgets('signed out: YouTube dropdown next to the sign-in pill, '
      'Twitch pill right-aligned', (tester) async {
    await tester.runAsync(
      () => Hive.box(
        HiveKeys.Settings.name,
      ).put(SettingsKeys.SelectedChatType.name, ChatType.YouTube),
    );
    selectLongChannels();
    runInAction(() {
      youTube.authState = YouTubeAuthState.signedOut;
      twitch.authState = TwitchAuthState.loggedOut;
    });
    await harness.shot(tester, 'chat_bar_youtube_signed_out', bar());
    await harness.shot(
      tester,
      'chat_bar_youtube_signed_out_narrow',
      bar(),
      size: const Size(320, 640),
    );
    await tester.runAsync(
      () => Hive.box(
        HiveKeys.Settings.name,
      ).put(SettingsKeys.SelectedChatType.name, ChatType.Twitch),
    );
    await harness.shot(tester, 'chat_bar_twitch_signed_out', bar());
  });
}
