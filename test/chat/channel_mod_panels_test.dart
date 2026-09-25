import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/models/kick_auth.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/models/youtube_auth.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/views/combined_chat.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/classes/chat/chat_ban_entry.dart';
import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/kick/kick_auth_service.dart';
import 'package:obs_blade/utils/kick/kick_channel_service.dart';
import 'package:obs_blade/utils/youtube/youtube_auth_service.dart';
import 'package:obs_blade/utils/youtube_target.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/combined_channel_mod_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/kick_channel_mod_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/youtube_channel_mod_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_chrome.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_kick_services.dart';
import 'support/fake_twitch_services.dart';
import 'support/fake_youtube_services.dart';

Widget wrap(Widget child) => MaterialApp(
  theme: ThemeData(
    extensions: const [AppStatusColors.standard, AppTextColors.standard],
  ),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late TwitchChatStore twitch;
  late YouTubeChatStore youTube;
  late KickChatStore kick;
  late FakeKickApiService kickApi;
  late CombinedChatStore combined;
  late List<String> toasts;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('channel_mod_panels');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
    await Hive.openBox<YouTubeAuth>(HiveKeys.YouTubeAuth.name);
    await Hive.openBox<KickAuth>(HiveKeys.KickAuth.name);
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

    twitch = TwitchChatStore(
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
    );
    youTube = YouTubeChatStore(
      authService: FakeYouTubeAuthService(),
      chatService: FakeYouTubeLiveChatService(),
      liveResolver: FakeYouTubeLiveResolver(),
      isProResolver: () => true,
    );
    kickApi = FakeKickApiService();
    kick = KickChatStore(
      channelService: FakeKickChannelService(),
      apiService: kickApi,
      isProResolver: () => true,
      pusherFactory: ({required onEvent, required onStateChanged}) =>
          FakeKickPusherService(
            onEvent: onEvent,
            onStateChanged: onStateChanged,
          ),
    );
    kick.authState = KickAuthState.signedIn;
    kick.ownChannelSlug = 'kicker';
    kick.channelInfo = const KickChannelInfo(
      id: 1,
      userId: 9001,
      slug: 'kicker',
      chatroom: KickChatroom(id: 2, slowMode: true, messageInterval: 5),
    );
    youTube.authState = YouTubeAuthState.signedIn;
    youTube.ownChannel = const YouTubeChatChannel(
      label: kYouTubeOwnChannelLabel,
      target: YouTubeChannelTarget('channel/UCownchannel000000000000'),
      isOwn: true,
      title: 'My Channel',
    );
    combined = CombinedChatStore(
      twitchStore: () => twitch,
      youTubeStore: () => youTube,
      kickStore: () => kick,
    );
    GetIt.instance
      ..registerSingleton<TwitchChatStore>(twitch)
      ..registerSingleton<YouTubeChatStore>(youTube)
      ..registerSingleton<KickChatStore>(kick)
      ..registerSingleton<CombinedChatStore>(combined);
    toasts = <String>[];
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await kick.dispose();
    await youTube.dispose();
    await twitch.dispose();
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('Kick: modes read-only, bans with Unban, a 403 toasts the '
      'not-a-mod explanation', (tester) async {
    kick.recentBans.add(
      ChatBanEntry(userId: '7', userName: 'troll', at: DateTime(2026)),
    );
    kickApi.unbanThrows = const KickApiException(
      'no permission',
      statusCode: 403,
    );
    await tester.pumpWidget(wrap(KickChannelModPanel(onToast: toasts.add)));

    expect(find.text('Slow mode'), findsOneWidget);
    expect(find.text('5s'), findsOneWidget);
    expect(find.text('troll'), findsOneWidget);

    await tester.tap(find.byKey(const Key('channel-mod-unban-7')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unban').last);
    await tester.pumpAndSettle();

    expect(kickApi.unbanCalls.single.userId, 7);
    expect(toasts, [chatNotModeratorText('Kick')]);
    expect(find.text('troll'), findsOneWidget, reason: 'still banned');
  });

  testWidgets('YouTube: echoed bans without a ban id cannot be lifted '
      'here; moderators are owner-only', (tester) async {
    youTube.recentBans.add(
      ChatBanEntry(userId: 'chan-9', userName: 'spam', at: DateTime(2026)),
    );
    youTube.selectedChannelLabel = 'Friend';
    await tester.pumpWidget(
      wrap(YouTubeChannelModPanel(onToast: toasts.add)),
    );

    expect(find.text('spam'), findsOneWidget);
    expect(find.byKey(const Key('channel-mod-unban-chan-9')), findsNothing);
    expect(find.textContaining('lift it on youtube.com'), findsOneWidget);
    expect(
      find.text('YouTube only lets the channel owner manage moderators.'),
      findsOneWidget,
    );
    expect(find.text('Polls need a live chat.'), findsOneWidget);
  });

  testWidgets('combined: one tab per moderatable source; switching tabs '
      'swaps the panel', (tester) async {
    expect(combinedModPlatforms(combined), [ChatType.YouTube, ChatType.Kick]);

    await tester.pumpWidget(
      wrap(CombinedChannelModSheet(onToast: toasts.add)),
    );

    expect(find.byKey(const Key('combined-mod-tab-YouTube')), findsOneWidget);
    expect(find.byKey(const Key('combined-mod-tab-Kick')), findsOneWidget);
    expect(find.byKey(const Key('combined-mod-tab-Twitch')), findsNothing);
    expect(find.byType(YouTubeChannelModPanel), findsOneWidget);

    await tester.tap(find.byKey(const Key('combined-mod-tab-Kick')));
    await tester.pumpAndSettle();

    expect(find.byType(KickChannelModPanel), findsOneWidget);
    expect(find.byType(YouTubeChannelModPanel), findsNothing);
  });

  testWidgets('combined: a single moderatable source shows no tab strip', (
    tester,
  ) async {
    youTube.authState = YouTubeAuthState.signedOut;
    await tester.pumpWidget(
      wrap(CombinedChannelModSheet(onToast: toasts.add)),
    );

    expect(find.byKey(const Key('combined-mod-tab-Kick')), findsNothing);
    expect(find.byType(KickChannelModPanel), findsOneWidget);
  });
}
