import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_search_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_options_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_combined_chat_view.dart'
    show CombinedPlatformBadge;

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
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/kick/kick_auth_service.dart';
import 'package:obs_blade/utils/kick/kick_channel_service.dart';
import 'package:obs_blade/utils/youtube/youtube_auth_service.dart';
import 'package:obs_blade/utils/youtube_target.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/combined_channel_mod_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/kick_channel_mod_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/youtube_channel_mod_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_chrome.dart';

import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/combined_sources_sheet.dart';

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
    await tester.pumpWidget(wrap(YouTubeChannelModPanel(onToast: toasts.add)));

    expect(find.text('spam'), findsOneWidget);
    expect(find.byKey(const Key('channel-mod-unban-chan-9')), findsNothing);
    expect(find.textContaining('lift it on youtube.com'), findsOneWidget);
    expect(
      find.text('YouTube only lets the channel owner manage moderators.'),
      findsOneWidget,
    );
    expect(find.text('Polls need a live chat.'), findsOneWidget);
  });

  testWidgets('combined: every source gets a tab; a blocked one explains '
      'why, offers the fix and lists what mods could do', (tester) async {
    /// The reported case: a random streamer's combo, YouTube not set up.
    youTube.authState = YouTubeAuthState.unconfigured;
    await tester.pumpWidget(wrap(CombinedChannelModSheet(onToast: toasts.add)));

    expect(combinedModPlatforms(combined), [ChatType.Kick]);
    expect(find.byKey(const Key('combined-mod-tab-YouTube')), findsOneWidget);
    expect(find.byKey(const Key('combined-mod-tab-Kick')), findsOneWidget);

    /// Opens on the first moderatable tab.
    expect(find.byType(KickChannelModPanel), findsOneWidget);

    await tester.tap(find.byKey(const Key('combined-mod-tab-YouTube')));
    await tester.pumpAndSettle();

    expect(find.byType(YouTubeChannelModPanel), findsNothing);
    expect(
      find.byKey(const Key('combined-mod-blocked-YouTube')),
      findsOneWidget,
    );
    expect(find.textContaining('isn\'t set up yet'), findsOneWidget);
    expect(find.byKey(const Key('combined-mod-fix-YouTube')), findsOneWidget);
    expect(
      find.text(kCombinedModCapabilities[ChatType.YouTube]!),
      findsOneWidget,
    );
  });

  testWidgets('combined: nothing moderatable still shows the tabs', (
    tester,
  ) async {
    youTube.authState = YouTubeAuthState.signedOut;
    kick.authState = KickAuthState.signedOut;
    await tester.pumpWidget(wrap(CombinedChannelModSheet(onToast: toasts.add)));

    expect(combinedModPlatforms(combined), isEmpty);
    expect(find.byKey(const Key('combined-mod-tab-YouTube')), findsOneWidget);
    expect(find.byKey(const Key('combined-mod-tab-Kick')), findsOneWidget);
    expect(
      find.byKey(const Key('combined-mod-blocked-YouTube')),
      findsOneWidget,
    );
    expect(find.textContaining('Sign in to YouTube'), findsWidgets);
  });

  /// Checklist state "signed in without a channel": every surface says
  /// so and offers another account - never "Sign in" (that loops into
  /// the same account) and never a write that fails.
  testWidgets('combined: a Google account without a channel is its own '
      'state in the mod sheet and the sources sheet', (tester) async {
    youTube.ownChannel = null;
    youTube.signedInWithoutChannel = true;
    final source = CombinedSource(
      platform: ChatType.YouTube,
      key: 'A',
      label: 'A',
    );
    expect(combinedModBlock(source), CombinedModBlock.noChannel);

    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => CombinedSourcesSheet(hostContext: context),
        ),
      ),
    );
    final youTubeStatus = tester.widget<Text>(
      find.byKey(const Key('combined-source-status-YouTube')),
    );
    expect(youTubeStatus.data, 'No channel on this Google account');
    expect(find.text('Switch account'), findsOneWidget);
  });

  test('combined: a Twitch source the account doesn\'t moderate is '
      'blocked as not-a-moderator', () async {
    final source = CombinedSource(
      platform: ChatType.Twitch,
      key: 'chan-1',
      label: 'Streamer',
    );
    twitch.authState = TwitchAuthState.loggedIn;
    twitch.user = FakeTwitchAuthService.user;
    await Hive.box<TwitchAuth>(HiveKeys.TwitchAuth.name).put(
      TwitchAuth.kBoxKey,
      TwitchAuth(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600000,
        scopes: const [
          'moderator:manage:chat_messages',
          'moderator:manage:banned_users',
        ],
      ),
    );
    twitch.selectedChannelId = 'chan-1';

    expect(combinedModBlock(source), CombinedModBlock.notModerator);

    twitch.moderatedChannelIds.add('chan-1');
    expect(combinedModBlock(source), isNull);
  });

  group('combined options sheet', () {
    Widget sheet() => MaterialApp(
      theme: ThemeData(
        extensions: const [AppStatusColors.standard, AppTextColors.standard],
      ),
      home: const Scaffold(
        body: NativeChatOptionsSheet(chatType: ChatType.Combined),
      ),
    );

    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    testWidgets('All chats rows, then a tab per platform of the combo with '
        'that platform\'s own pages', (tester) async {
      await tester.pumpWidget(sheet());
      await tester.pumpAndSettle();
      expect(find.text('Search chat'), findsOneWidget);
      for (final label in [
        'Appearance',
        'Highlights',
        'Mute words',
        'Text to speech',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      final platforms = [
        for (final source in combined.activeSources) source.platform,
      ];
      for (final platform in platforms) {
        expect(find.byKey(Key('options-tab-${platform.name}')), findsOneWidget);
      }

      /// Kick: its Emotes page is Kick's (7TV only), not Twitch's
      await tapVisible(tester, find.byKey(const Key('options-tab-Kick')));
      await tapVisible(tester, find.text('Emotes'));
      expect(find.text('Third-party emotes (7TV)'), findsOneWidget);
      await tapVisible(tester, find.byIcon(CupertinoIcons.chevron_back));

      /// YouTube: setup, no account rows (they live in the chat header)
      await tapVisible(tester, find.byKey(const Key('options-tab-YouTube')));
      expect(find.text('Chat setup'), findsOneWidget);
      expect(find.text('Emotes'), findsNothing);
      expect(find.textContaining('Sign out'), findsNothing);
    });

    testWidgets('YouTube\'s own sheet: the same split, setup in its section', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [
              AppStatusColors.standard,
              AppTextColors.standard,
            ],
          ),
          home: const Scaffold(
            body: NativeChatOptionsSheet(chatType: ChatType.YouTube),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Chat setup'), findsOneWidget);
      expect(find.textContaining('Sign out'), findsNothing);
    });

    testWidgets('search over the whole combined timeline', (tester) async {
      youTube.messages.add(
        YouTubeChatMessage(
          id: 'yt-1',
          snippet: YouTubeChatMessageSnippet(
            type: YouTubeChatMessageType.textMessage,
            publishedAt: DateTime.utc(2026, 10, 5, 12),
            authorChannelId: 'chan-1',
            displayMessage: 'gg from youtube',
            textMessageDetails: const YouTubeTextMessageDetails(
              messageText: 'gg from youtube',
            ),
          ),
          authorDetails: const YouTubeChatAuthorDetails(
            channelId: 'chan-1',
            displayName: 'Tuber',
          ),
        ),
      );
      kick.messages.addAll([
        KickChatMessage(
          id: 'k-1',
          content: 'gg from kick',
          type: KickChatMessageType.message,
          createdAt: DateTime.utc(2026, 10, 5, 12, 1),
          sender: const KickChatSender(id: 5, username: 'kickfan'),
        ),
        KickChatMessage(
          id: 'k-2',
          content: 'hello',
          type: KickChatMessageType.message,
          createdAt: DateTime.utc(2026, 10, 5, 12, 2),
          sender: const KickChatSender(id: 6, username: 'other'),
        ),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [
              AppStatusColors.standard,
              AppTextColors.standard,
            ],
          ),
          home: const Scaffold(
            body: ChatSearchSheet(chatType: ChatType.Combined),
          ),
        ),
      );
      await tester.enterText(find.byKey(const Key('chat-search-field')), 'gg');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('search-youtube:yt-1')), findsOneWidget);
      expect(find.byKey(const Key('search-kick:k-1')), findsOneWidget);
      expect(find.byKey(const Key('search-kick:k-2')), findsNothing);
      expect(find.byKey(const Key('combined-row-icon-YouTube')), findsNothing);
      expect(find.byType(CombinedPlatformBadge), findsNWidgets(2));

      /// Search shows what the chat shows: an ignored user stays hidden
      await tester.runAsync(() async {
        await Hive.box(
          HiveKeys.Settings.name,
        ).put(SettingsKeys.ChatIgnoredUsers.name, 'kickfan');
        await Hive.box(HiveKeys.Settings.name).flush();
      });
      await tester.enterText(find.byKey(const Key('chat-search-field')), 'gg ');
      await tester.enterText(find.byKey(const Key('chat-search-field')), 'gg');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('search-kick:k-1')), findsNothing);
      expect(find.byKey(const Key('search-youtube:yt-1')), findsOneWidget);
    });
  });
}
