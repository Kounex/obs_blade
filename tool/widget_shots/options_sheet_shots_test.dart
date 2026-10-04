import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/models/kick_auth.dart';
import 'package:obs_blade/models/youtube_auth.dart';
import 'package:obs_blade/stores/views/combined_chat.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/kick/kick_auth_service.dart';
import 'package:obs_blade/utils/youtube/youtube_auth_service.dart';
import 'package:obs_blade/utils/youtube_target.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_options_sheet.dart';

import '../../test/chat/support/fake_kick_services.dart';
import '../../test/chat/support/fake_twitch_services.dart';
import '../../test/chat/support/fake_youtube_services.dart';
import 'support/shots_harness.dart';

/// Native chat options per platform and in combined chat: "All chats"
/// rows, then the platform's own section (combined: platform tabs).
void main() {
  final harness = ShotsHarness();

  setUpAll(ShotsHarness.loadFonts);
  setUp(() async {
    await harness.setUp();
    await Hive.box<KickAuth>(HiveKeys.KickAuth.name).put(
      KickAuth.kBoxKey,
      KickAuth(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600000,
        scopes: kKickChatScopes,
        userId: 9001,
        username: 'kicker',
        channelSlug: 'kicker',
      ),
    );
    await Hive.box<YouTubeAuth>(HiveKeys.YouTubeAuth.name).put(
      YouTubeAuth.kBoxKey,
      YouTubeAuth(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600000,
        scopes: kYouTubeChatScopes,
        channelTitle: 'My Channel',
        channelId: 'UCownchannel000000000000',
      ),
    );
    final twitch = TwitchChatStore(
      authService: FakeTwitchAuthService(),
      isProResolver: () => true,
      eventSubFactory: (_, _, _, _, _, _, _, _, _, _) =>
          FakeTwitchEventSubService(),
      ircSidecarFactory: (_) => FakeSilentIrcSidecar(),
    );
    final youTube = YouTubeChatStore(
      authService: FakeYouTubeAuthService(),
      chatService: FakeYouTubeLiveChatService(),
      liveResolver: FakeYouTubeLiveResolver(),
      isProResolver: () => true,
    );
    final kick = KickChatStore(
      channelService: FakeKickChannelService(),
      apiService: FakeKickApiService(),
      isProResolver: () => true,
      pusherFactory: ({required onEvent, required onStateChanged}) =>
          FakeKickPusherService(
            onEvent: onEvent,
            onStateChanged: onStateChanged,
          ),
    );
    kick.authState = KickAuthState.signedIn;
    kick.ownChannelSlug = 'kicker';
    youTube.authState = YouTubeAuthState.signedIn;
    youTube.ownChannel = const YouTubeChatChannel(
      label: kYouTubeOwnChannelLabel,
      target: YouTubeChannelTarget('channel/UCownchannel000000000000'),
      isOwn: true,
      title: 'My Channel',
    );
    GetIt.instance
      ..registerSingleton<TwitchChatStore>(twitch)
      ..registerSingleton<YouTubeChatStore>(youTube)
      ..registerSingleton<KickChatStore>(kick)
      ..registerSingleton<CombinedChatStore>(
        CombinedChatStore(
          twitchStore: () => twitch,
          youTubeStore: () => youTube,
          kickStore: () => kick,
        ),
      );
  });
  tearDown(() async {
    await GetIt.instance.reset();
    await harness.tearDown();
  });

  for (final type in [
    ChatType.Twitch,
    ChatType.YouTube,
    ChatType.Kick,
    ChatType.Combined,
  ]) {
    testWidgets('options ${type.name}', (tester) async {
      await harness.shot(
        tester,
        'options_${type.name.toLowerCase()}',
        NativeChatOptionsSheet(chatType: type),
      );
    });
  }

  testWidgets('combined narrow, Kick tab', (tester) async {
    await harness.shot(
      tester,
      'options_combined_narrow_base',
      const NativeChatOptionsSheet(chatType: ChatType.Combined),
      size: const Size(320, 640),
    );
    await tester.ensureVisible(find.byKey(const Key('options-tab-Kick')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('options-tab-Kick')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(
        '../../build/widget_shots/options_combined_narrow_kick.png',
      ),
    );
  });
}
