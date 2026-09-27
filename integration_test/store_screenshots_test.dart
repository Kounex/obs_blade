// Store screenshot capture for OBS Blade (tool/store_screenshots/README.md).
//
// Boots the real app on a DEDICATED simulator/emulator (it writes settings,
// stats, a saved connection and the Pro debug override - never run it on a
// device that holds real data), seeds a believable "streamer" state, connects
// to the local demo OBS (obs_demo.dart: live + recording) and prints
// `SHOT: <name>` markers. tool/store_screenshots/capture.sh takes a device
// screenshot per marker and acks it back over loopback (same handshake as
// the visual-QA walk).
//
// Chat is fed by fake-backed platform stores (the same fakes the widget
// tests use) with fictional viewers - no network, no real accounts.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/main.dart' as app;
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/models/kick_auth.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/models/youtube_auth.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/models/past_record_data.dart';
import 'package:obs_blade/models/past_stream_data.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/shared/tabs.dart';
import 'package:obs_blade/stores/views/combined_chat.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/stores/views/home.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/kick/kick_auth_service.dart';
import 'package:obs_blade/utils/routing_helper.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/youtube/youtube_auth_service.dart';
import 'package:obs_blade/utils/youtube_target.dart';
import 'package:obs_blade/views/dashboard/dashboard.dart';
import 'package:obs_blade/views/intro/intro.dart';
import 'package:obs_blade/views/statistics/statistic_detail/statistic_detail.dart';

import '../test/chat/support/fake_kick_services.dart';
import '../test/chat/support/fake_twitch_services.dart';
import '../test/chat/support/fake_youtube_services.dart';

const String kObsHost = String.fromEnvironment(
  'OBS_HOST',
  defaultValue: '127.0.0.1',
);
const String kObsWsPassword = String.fromEnvironment('OBS_WS_PASSWORD');

/// Comma-separated shot names to capture (empty = all) - lets a re-run
/// grab just the frames that need another take.
const String kOnly = String.fromEnvironment('STORE_SHOTS_ONLY');

const int kAckPort = 8977;
const String kFeaturedStream = 'Neon Circuit - Grand Prix night';
final Map<String, Completer<void>> _shotAcks = {};

void _log(String message) {
  // ignore: avoid_print
  print(message);
}

Future<void> _pump(WidgetTester tester, int ms) async {
  int remaining = ms;
  while (remaining > 0) {
    final int step = remaining > 250 ? 250 : remaining;
    await tester.pump(Duration(milliseconds: step));
    remaining -= step;
  }
}

bool _wanted(String name) =>
    kOnly.isEmpty || kOnly.split(',').map((s) => s.trim()).contains(name);

Future<void> _shot(
  WidgetTester tester,
  String name, {
  int settleMs = 2000,
  Map<String, List<Finder>> crops = const {},
}) async {
  if (!_wanted(name)) {
    // still let pushed routes mount before the flow pops them again
    await _pump(tester, min(settleMs, 800));
    return;
  }
  await _pump(tester, settleMs);
  crops.forEach((key, finders) => _crop(tester, name, key, finders));
  final Completer<void> ack = Completer<void>();
  _shotAcks[name] = ack;
  _log('SHOT: $name');
  await ack.future.timeout(
    const Duration(seconds: 12),
    onTimeout: () => _log('WARN: no capture ack for $name'),
  );
  _shotAcks.remove(name);
}

/// Prints the union rect of [finders] (first match each, missing ones
/// skipped) as fractions of the screen: `CROP: <shot> <key> l t w h`. The
/// store composer cuts its enlarged callout cards from these.
void _crop(
  WidgetTester tester,
  String shot,
  String key,
  List<Finder> finders, {
  double pad = 8,
}) {
  Rect? rect;
  for (final Finder finder in finders) {
    if (finder.evaluate().isEmpty) continue;
    final Rect r = tester.getRect(finder.first);
    rect = rect == null ? r : rect.expandToInclude(r);
  }
  if (rect == null) {
    _log('WARN: crop $shot/$key - nothing found');
    return;
  }
  final Size screen = tester.view.physicalSize / tester.view.devicePixelRatio;
  final Rect clamped = rect.inflate(pad).intersect(Offset.zero & screen);
  String f(double v) => v.toStringAsFixed(4);
  _log(
    'CROP: $shot $key ${f(clamped.left / screen.width)} '
    '${f(clamped.top / screen.height)} ${f(clamped.width / screen.width)} '
    '${f(clamped.height / screen.height)}',
  );
}

Future<bool> _waitFor(
  WidgetTester tester,
  bool Function() test, {
  int timeoutMs = 20000,
}) async {
  for (int waited = 0; waited < timeoutMs; waited += 250) {
    if (test()) return true;
    await _pump(tester, 250);
  }
  return test();
}

Box<dynamic> get _settings => Hive.box<dynamic>(HiveKeys.Settings.name);

void _switchTab(Tabs tab) => GetIt.instance<TabsStore>().setActiveTab(tab);

void _pushInTab(Tabs tab, String route, {Object? arguments}) =>
    GetIt.instance<TabsStore>().navigatorKeys[tab]!.currentState!.pushNamed(
      route,
      arguments: arguments,
    );

void _popInTab(Tabs tab) =>
    GetIt.instance<TabsStore>().navigatorKeys[tab]!.currentState!.maybePop();

ScrollController? _routeScroll(WidgetTester tester, Type view) {
  final Finder finder = find.byType(view);
  if (finder.evaluate().isEmpty) return null;
  final Object? args = ModalRoute.of(
    tester.element(finder.first),
  )?.settings.arguments;
  return args is ScrollController ? args : null;
}

/// Scrolls [controller] so [target]'s top lands [topInset] px below the top
/// of the screen.
Future<void> _scrollTo(
  WidgetTester tester,
  ScrollController? controller,
  Finder target, {
  double topInset = 110,
}) async {
  if (controller == null || !controller.hasClients) return;
  for (int i = 0; i < 12 && target.evaluate().isEmpty; i++) {
    controller.jumpTo(
      min(controller.offset + 300, controller.position.maxScrollExtent),
    );
    await _pump(tester, 300);
  }
  if (target.evaluate().isEmpty) {
    _log('WARN: scroll target not found: $target');
    return;
  }
  final double dy = tester.getTopLeft(target.first).dy - topInset;
  controller.jumpTo(
    (controller.offset + dy).clamp(0.0, controller.position.maxScrollExtent),
  );
  await _pump(tester, 600);
}

// ---------------------------------------------------------------- seeding

void _seedSettings() {
  _settings.putAll({
    SettingsKeys.HasUserSeenIntro202609.name: true,
    SettingsKeys.ProDebugOverride.name: true,
    SettingsKeys.DontShowPreviewWarning.name: true,
    SettingsKeys.DontShowHotkeysTechnicalPreviewWarning.name: true,
    SettingsKeys.ExposeStreamingControls.name: true,
    SettingsKeys.ExposeRecordingControls.name: true,
    SettingsKeys.ExposeScenePreview.name: true,
    SettingsKeys.StreamingMode.name: false,
  });
}

/// Past streams + recordings with smooth, plausible curves.
Future<void> _seedStats() async {
  final Box<PastStreamData> streams = Hive.box<PastStreamData>(
    HiveKeys.PastStreamData.name,
  );
  final Box<PastRecordData> records = Hive.box<PastRecordData>(
    HiveKeys.PastRecordData.name,
  );
  if (streams.length >= 4) return;

  final Random random = Random(7);
  final DateTime now = DateTime.now();
  final List<(String, int, int, bool)> sessions = [
    // name, days ago, minutes, starred
    (kFeaturedStream, 1, 186, true),
    ('Community races + Q&A', 3, 142, false),
    ('Speedrun attempts', 5, 97, false),
    ('Chill Sunday stream', 7, 214, true),
    ('Ranked grind', 9, 128, false),
  ];
  for (final (name, daysAgo, minutes, starred) in sessions) {
    final PastStreamData data = PastStreamData();
    final DateTime start = DateTime(
      now.year,
      now.month,
      now.day - daysAgo,
      19,
      random.nextInt(30),
    );
    final int points = minutes; // one averaged point per minute
    for (int i = 0; i < points; i++) {
      final double t = i / points;
      data.listEntryDateMS.add(
        start.add(Duration(minutes: i)).millisecondsSinceEpoch,
      );
      data.fpsList.add(
        (60 -
                (random.nextDouble() < 0.04 ? random.nextDouble() * 6 : 0) -
                random.nextDouble() * 0.4)
            .toDouble(),
      );
      data.cpuUsageList.add(
        14 + 6 * sin(t * pi * 3) + random.nextDouble() * 4 + (t < 0.05 ? 8 : 0),
      );
      data.kbitsPerSecList.add(
        (6000 + 180 * sin(t * pi * 7) + random.nextInt(260) - 130).round(),
      );
      data.memoryUsageList.add(420 + 60 * t + random.nextDouble() * 12);
    }
    data.totalTime = minutes * 60;
    data.renderTotalFrames = minutes * 60 * 60;
    data.renderSkippedFrames = 12 + random.nextInt(40);
    data.outputTotalFrames = minutes * 60 * 60;
    data.outputSkippedFrames = random.nextInt(20);
    data.averageFrameTime = 2.1 + random.nextDouble();
    data.name = name;
    data.starred = starred;
    await streams.add(data);
  }

  final PastRecordData record = PastRecordData();
  final DateTime start = DateTime(now.year, now.month, now.day - 2, 15, 10);
  for (int i = 0; i < 42; i++) {
    record.listEntryDateMS.add(
      start.add(Duration(minutes: i)).millisecondsSinceEpoch,
    );
    record.fpsList.add(60 - random.nextDouble() * 0.3);
    record.cpuUsageList.add(11 + random.nextDouble() * 5);
    record.kbitsPerSecList.add(0);
    record.memoryUsageList.add(400 + random.nextDouble() * 15);
  }
  record.totalTime = 42 * 60;
  record.renderTotalFrames = 42 * 60 * 60;
  record.renderSkippedFrames = 3;
  record.outputTotalFrames = 42 * 60 * 60;
  record.outputSkippedFrames = 0;
  record.averageFrameTime = 1.9;
  record.name = 'Tutorial: drift lines';
  await records.add(record);
}

Future<Connection> _seedConnection() async {
  final Box<Connection> box = Hive.box<Connection>(
    HiveKeys.SavedConnections.name,
  );
  for (final Connection c in box.values) {
    if (c.name == 'Studio PC') return c;
  }
  final Connection connection = Connection(kObsHost, 4455, kObsWsPassword)
    ..name = 'Studio PC';
  await box.add(connection);
  return connection;
}

// ------------------------------------------------------------------- chat

late TwitchChatStore _twitch;
late YouTubeChatStore _youTube;
late KickChatStore _kick;

/// Swaps the (not yet created) lazy platform chat stores for fake-backed
/// ones. CombinedChatStore (created at boot) resolves them through GetIt
/// on every access, so it picks the fakes up.
void _installFakeChatStores() {
  final GetIt getIt = GetIt.instance;
  _twitch = TwitchChatStore(
    authService: FakeTwitchAuthService(),
    isProResolver: () => true,
    eventSubFactory: (_, _, _, _, _, _, _, _, _, _) =>
        FakeTwitchEventSubService(),
    ircSidecarFactory: (_) => FakeSilentIrcSidecar(),
  );
  _youTube = YouTubeChatStore(
    authService: FakeYouTubeAuthService(),
    chatService: FakeYouTubeLiveChatService(),
    liveResolver: FakeYouTubeLiveResolver(),
    isProResolver: () => true,
  );
  _kick = KickChatStore(
    channelService: FakeKickChannelService(),
    isProResolver: () => true,
    pusherFactory: ({required onEvent, required onStateChanged}) =>
        FakeKickPusherService(onEvent: onEvent, onStateChanged: onStateChanged),
  );
  for (final void Function() swap in [
    () => getIt
      ..unregister<TwitchChatStore>()
      ..registerSingleton<TwitchChatStore>(_twitch),
    () => getIt
      ..unregister<YouTubeChatStore>()
      ..registerSingleton<YouTubeChatStore>(_youTube),
    () => getIt
      ..unregister<KickChatStore>()
      ..registerSingleton<KickChatStore>(_kick),
    () => getIt
      ..unregister<TwitchBadgeStore>()
      ..registerSingleton<TwitchBadgeStore>(
        TwitchBadgeStore(service: FakeTwitchBadgeService()),
      ),
    () => getIt
      ..unregister<ThirdPartyEmoteStore>()
      ..registerSingleton<ThirdPartyEmoteStore>(
        ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService()),
      ),
    // A fresh combined store: swapped LAST - bindToChatType observes
    // its computeds right away, binding them to whatever stores GetIt
    // returns at that moment (the boot one is bound to the real ones)
    () => getIt
      ..unregister<CombinedChatStore>()
      ..registerSingleton<CombinedChatStore>(
        CombinedChatStore()..bindToChatType(),
      ),
  ]) {
    try {
      swap();
    } catch (e) {
      _log('WARN: store swap failed: $e');
    }
  }
}

/// Placeholder sessions with write scopes, so the chat dock shows its real
/// input instead of the read-only strip. The fake-backed stores never send
/// these anywhere.
Future<void> _seedChatAuth() async {
  final int expires = DateTime.now()
      .add(const Duration(days: 30))
      .millisecondsSinceEpoch;
  await Hive.box<TwitchAuth>(HiveKeys.TwitchAuth.name).put(
    TwitchAuth.kBoxKey,
    TwitchAuth(
      accessToken: 'store-shots',
      refreshToken: 'store-shots',
      expiresAtMs: expires,
      scopes: [
        ...kTwitchChatScopes,
        ...kTwitchModerationScopes,
        ...kTwitchManageModToolingScopes,
      ],
      userId: '4242',
      userLogin: 'novarush',
      userDisplayName: 'NovaRush',
    ),
  );
  await Hive.box<YouTubeAuth>(HiveKeys.YouTubeAuth.name).put(
    YouTubeAuth.kBoxKey,
    YouTubeAuth(
      accessToken: 'store-shots',
      refreshToken: 'store-shots',
      expiresAtMs: expires,
      scopes: kYouTubeChatScopes,
      channelTitle: 'NovaRush',
      channelId: 'UCnovarush00000000000000',
    ),
  );
  await Hive.box<KickAuth>(HiveKeys.KickAuth.name).put(
    KickAuth.kBoxKey,
    KickAuth(
      accessToken: 'store-shots',
      refreshToken: 'store-shots',
      expiresAtMs: expires,
      scopes: kKickChatScopes,
      userId: 4242,
      username: 'novarush',
      channelSlug: 'novarush',
    ),
  );
}

/// Own channels on all three platforms, all on air.
void _seedChatAccounts() {
  runInAction(() {
    _twitch.user = const TwitchUser(
      id: '4242',
      login: 'novarush',
      displayName: 'NovaRush',
    );
    _twitch.authState = TwitchAuthState.loggedIn;
    _twitch.chatConnection = TwitchChatConnectionState.live;
    _twitch.selectedChannelIsLive = true;
    _twitch.selectedChannelViewerCount = 1284;

    _youTube.authState = YouTubeAuthState.signedIn;
    _youTube.ownChannel = const YouTubeChatChannel(
      label: kYouTubeOwnChannelLabel,
      target: YouTubeChannelTarget('channel/UCnovarush00000000000000'),
      isOwn: true,
      title: 'NovaRush',
    );
    _youTube.chatConnection = YouTubeChatConnectionState.connected;
    _youTube.selectedChannelViewerCount = 342;

    _kick.authState = KickAuthState.signedIn;
    _kick.ownChannelSlug = 'novarush';
    _kick.channelInfo = const KickChannelInfo(
      id: 1,
      slug: 'novarush',
      chatroom: KickChatroom(id: 2),
      livestream: KickLivestreamInfo(isLive: true, viewerCount: 187),
    );
    _kick.chatConnection = KickChatConnectionState.connected;
  });
}

const List<(ChatType, String, String, String)> _chatScript = [
  (
    ChatType.Twitch,
    'pixel_pilot',
    '#9147FF',
    'that drift into turn 3 was insane 🔥',
  ),
  (
    ChatType.YouTube,
    'Mara Lindqvist',
    '',
    'Just got here, what lap are we on?',
  ),
  (ChatType.Kick, 'apexhunter', '#53FC18', 'P1 lets gooo 🏁'),
  (ChatType.Twitch, 'LunaLoops', '#FF7AB6', 'the new overlay looks so clean'),
  (ChatType.Twitch, 'grid_ghost', '#3DE8FF', '!discord'),
  (ChatType.YouTube, 'Tobi Racing', '', 'Lap 2 of 3 - hold that line!'),
  (
    ChatType.Kick,
    'turbo_tilde',
    '#FFD60A',
    'first time catching the stream live 👋',
  ),
  (
    ChatType.Twitch,
    'synthwave_sam',
    '#FF9F0A',
    'GG in advance, that lead is massive',
  ),
  (ChatType.YouTube, 'Jonas', '', 'The synthwave vibe on this track 😍'),
  (ChatType.Twitch, 'mod_moxie', '#30D158', 'Reminder: be kind in chat 💜'),
  (ChatType.Kick, 'driftwood', '#53FC18', 'how is the car so fast in sector 2'),
  (ChatType.Twitch, 'pixel_pilot', '#9147FF', 'clip it! CLIP IT'),
  (ChatType.YouTube, 'Aiko', '', 'Watching from Tokyo, good luck Nova!'),
  (
    ChatType.Twitch,
    'kaicodes',
    '#64D2FF',
    'what settings do you run for 60fps?',
  ),
  (ChatType.Kick, 'apexhunter', '#53FC18', 'final lap 😤'),
  (ChatType.Twitch, 'LunaLoops', '#FF7AB6', 'W stream as always'),
];

void _seedChatMessages() {
  final DateTime now = DateTime.now();
  runInAction(() {
    _twitch.messages.clear();
    _youTube.messages.clear();
    _kick.messages.clear();
    for (int i = 0; i < _chatScript.length; i++) {
      final (ChatType platform, String author, String color, String text) =
          _chatScript[i];
      final DateTime at = now.subtract(
        Duration(seconds: (_chatScript.length - i) * 9),
      );
      switch (platform) {
        case ChatType.Twitch:
          _twitch.messages.add(
            ChatMessageEvent(
              broadcasterUserId: '4242',
              chatterUserId: 'u-$author',
              chatterUserLogin: author.toLowerCase(),
              chatterUserName: author,
              messageId: 'store-tw-$i',
              color: color,
              message: ChatMessageText(
                text: text,
                fragments: [ChatMessageFragment(type: 'text', text: text)],
              ),
              receivedAt: at,
            ),
          );
        case ChatType.YouTube:
          _youTube.messages.add(
            YouTubeChatMessage(
              id: 'store-yt-$i',
              snippet: YouTubeChatMessageSnippet(
                type: YouTubeChatMessageType.textMessage,
                publishedAt: at,
                authorChannelId: 'yt-$author',
                displayMessage: text,
                textMessageDetails: YouTubeTextMessageDetails(
                  messageText: text,
                ),
              ),
              authorDetails: YouTubeChatAuthorDetails(
                channelId: 'yt-$author',
                displayName: author,
              ),
            ),
          );
        case ChatType.Kick:
          _kick.messages.add(
            KickChatMessage(
              id: 'store-kick-$i',
              content: text,
              createdAt: at,
              sender: KickChatSender(
                id: 100 + i,
                username: author,
                slug: author,
                identity: KickChatIdentity(color: color),
              ),
            ),
          );
        default:
      }
    }
  });
}

// ------------------------------------------------------------------- test

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('store screenshots', (WidgetTester tester) async {
    app.main();
    await _pump(tester, 5000);

    final HttpServer ackServer = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      kAckPort,
    );
    ackServer.listen((HttpRequest request) {
      final String? name = request.uri.queryParameters['name'];
      final Completer<void>? ack = name != null ? _shotAcks[name] : null;
      if (ack != null && !ack.isCompleted) ack.complete();
      request.response.statusCode = HttpStatus.ok;
      request.response.close();
    });

    // Seed while the intro is still the root route: the tab shell (every
    // tab is built eagerly) must not exist yet when the chat stores are
    // swapped, or its observers stay bound to the real stores.
    if (find.byType(IntroView).evaluate().isEmpty) {
      _log('ERROR: expected a fresh install booting into the intro');
    }
    // No autodiscover scan: emulators have no WLAN (the scan throws) and the
    // test connects to its seeded connection directly anyway
    GetIt.instance<HomeStore>().setConnectMode(ConnectMode.Manual);
    _seedSettings();
    await _seedStats();
    final Connection connection = await _seedConnection();
    await _seedChatAuth();
    _installFakeChatStores();
    await _settings.put(SettingsKeys.SelectedChatType.name, ChatType.Combined);
    _seedChatAccounts();
    _seedChatMessages();
    await _pump(tester, 1500);

    await _shot(tester, 'intro_welcome', settleMs: 1500);
    if (find.byType(IntroView).evaluate().isNotEmpty) {
      Navigator.of(
        tester.element(find.byType(IntroView).first),
        rootNavigator: true,
      ).pushReplacementNamed(AppRoutingKeys.Tabs.route);
    }
    await _pump(tester, 3000);

    // ========================= STATISTICS =========================
    // Before connecting: a live session adds its own (unnamed) entries.
    _switchTab(Tabs.Statistics);
    await _shot(tester, 'stats_landing', settleMs: 2500);
    final List<PastStreamData> streams = Hive.box<PastStreamData>(
      HiveKeys.PastStreamData.name,
    ).values.toList();
    final PastStreamData featured = streams.firstWhere(
      (s) => s.name == kFeaturedStream,
      orElse: () => streams.first,
    );
    _pushInTab(
      Tabs.Statistics,
      StaticticsTabRoutingKeys.Detail.route,
      arguments: featured,
    );
    await _shot(tester, 'stats_detail', settleMs: 3000);
    final Finder detailScrollable = find.descendant(
      of: find.byType(StatisticDetailView),
      matching: find.byType(Scrollable),
    );
    if (detailScrollable.evaluate().isNotEmpty) {
      final ScrollPosition position = tester
          .state<ScrollableState>(detailScrollable.first)
          .position;
      position.jumpTo(min(position.maxScrollExtent, 700.0));
      await _shot(tester, 'stats_detail_charts', settleMs: 1500);
    }
    _popInTab(Tabs.Statistics);
    await _pump(tester, 1000);

    // ========================== SETTINGS ==========================
    _switchTab(Tabs.Settings);
    await _shot(tester, 'settings', settleMs: 2000);
    _pushInTab(
      Tabs.Settings,
      SettingsTabRoutingKeys.DashboardCustomisation.route,
    );
    await _shot(tester, 'customisation', settleMs: 2200);
    _pushInTab(
      Tabs.Settings,
      SettingsTabRoutingKeys.DashboardCustomisationOrder.route,
    );
    await _shot(tester, 'customisation_order', settleMs: 2200);
    _popInTab(Tabs.Settings);
    await _pump(tester, 800);
    _popInTab(Tabs.Settings);
    await _pump(tester, 800);
    _pushInTab(Tabs.Settings, SettingsTabRoutingKeys.CustomTheme.route);
    await _shot(tester, 'themes', settleMs: 2200);
    _popInTab(Tabs.Settings);
    await _pump(tester, 800);

    // ============================ CHAT ============================
    _seedChatAccounts();
    _seedChatMessages();
    _switchTab(Tabs.Chat);
    await _pump(tester, 3000);
    // Channel activation settles asynchronously - re-assert the seeded
    // state right before the capture
    _seedChatAccounts();
    _seedChatMessages();
    await _pump(tester, 800);
    _seedChatAccounts();
    final CombinedChatStore combined = GetIt.instance<CombinedChatStore>();
    _log(
      'STATE-INFO: combined active=${combined.active} '
      'sources=${combined.activeSources.length} '
      'live=${combined.liveSources}',
    );
    _log(
      'STATE-INFO: same twitch=${identical(GetIt.instance<TwitchChatStore>(), _twitch)} '
      'twitchLoggedIn=${_twitch.isLoggedIn} user=${_twitch.user?.login} '
      'ytOwn=${_youTube.ownChannel?.label} kick=${_kick.ownChannelSlug} '
      'avail=${combined.availableSources.length} my=${combined.mySources.length} '
      'disabled=${combined.disabledPlatforms} combo=${combined.selectedComboId}',
    );
    await _shot(
      tester,
      'chat_combined',
      settleMs: 600,
      crops: {
        'sources': [
          find.byKey(const Key('combined-focus-Twitch')),
          find.byKey(const Key('combined-focus-YouTube')),
          find.byKey(const Key('combined-focus-Kick')),
        ],
      },
    );

    // ========================== DASHBOARD =========================
    _switchTab(Tabs.Home);
    await _pump(tester, 800);
    unawaited(GetIt.instance<NetworkStore>().setOBSWebSocket(connection));
    final bool dashboard = await _waitFor(
      tester,
      () => find.byType(DashboardView).evaluate().isNotEmpty,
      timeoutMs: 25000,
    );
    if (!dashboard) {
      _log('ERROR: dashboard not reached - is the demo OBS up at $kObsHost?');
      await _shot(tester, 'error_connect', settleMs: 500);
      await ackServer.close(force: true);
      return;
    }
    await _pump(tester, 3000);
    final ScrollController? dashScroll = _routeScroll(tester, DashboardView);

    // Expand the scene preview (the warning is pre-dismissed by settings)
    final Finder previewTile = find.text('Current OBS scene preview');
    await _scrollTo(tester, dashScroll, previewTile, topInset: 400);
    if (previewTile.hitTestable().evaluate().isNotEmpty) {
      await tester.tap(previewTile.hitTestable().first);
      await _pump(tester, 1000);
    }
    await _waitFor(
      tester,
      () => GetIt.instance<DashboardStore>().scenePreviewImageBytes != null,
      timeoutMs: 10000,
    );
    if (dashScroll != null && dashScroll.hasClients) dashScroll.jumpTo(0);
    await _shot(
      tester,
      'dashboard_top',
      settleMs: 3000,
      crops: {
        'live_pills': [find.textContaining('LIVE'), find.textContaining('REC')],
        'scene_buttons': [find.text('Intro'), find.text('Outro')],
      },
    );

    // Stream / record controls
    final Finder controls = find.text('Exposed Controls');
    if (controls.hitTestable().evaluate().isNotEmpty) {
      await tester.tap(controls.hitTestable().first);
      await _pump(tester, 1000);
      await _shot(tester, 'dashboard_controls', settleMs: 1500);
      await tester.tap(controls.hitTestable().first);
      await _pump(tester, 800);
    }

    await _scrollTo(tester, dashScroll, previewTile, topInset: 110);
    await _shot(tester, 'dashboard_preview', settleMs: 2000);

    await _scrollTo(
      tester,
      dashScroll,
      find.text('Scene Items'),
      topInset: 160,
    );
    await _shot(tester, 'dashboard_scene_items', settleMs: 1200);
    final Finder audioTab = find.text('Audio').hitTestable();
    if (audioTab.evaluate().isNotEmpty) {
      await tester.tap(audioTab.first);
      await _pump(tester, 1000);
    } else {
      _log('WARN: Audio tab not hittable');
    }
    // Frame the scene mixer: the demo collection has no global audio
    // devices, so scroll past that (empty) block
    final Finder noGlobal = find.textContaining('No Global Audio source');
    if (noGlobal.evaluate().isNotEmpty &&
        dashScroll != null &&
        dashScroll.hasClients) {
      final double bottom = tester.getBottomLeft(noGlobal.first).dy;
      dashScroll.jumpTo(
        (dashScroll.offset + bottom - 150).clamp(
          0.0,
          dashScroll.position.maxScrollExtent,
        ),
      );
    }
    await _shot(
      tester,
      'dashboard_audio',
      settleMs: 1500,
      crops: {
        'fader': [
          find.text('Music'),
          find.byWidgetPredicate((w) => w is Slider || w is CupertinoSlider),
        ],
      },
    );
    await _scrollTo(tester, dashScroll, find.text('OBS Stats'), topInset: 160);
    await _shot(tester, 'dashboard_stats', settleMs: 2500);
    if (dashScroll != null && dashScroll.hasClients) dashScroll.jumpTo(0);
    await _pump(tester, 800);

    // ======================= STREAMING MODE =======================
    await _settings.put(SettingsKeys.StreamingMode.name, true);
    await _pump(tester, 1500);
    _seedChatAccounts();
    _seedChatMessages();
    await _shot(
      tester,
      'streaming_mode',
      settleMs: 3500,
      crops: {
        'health_pill': [find.textContaining('kbit/s')],
        'sources': [
          find.byKey(const Key('combined-focus-Twitch')),
          find.byKey(const Key('combined-focus-YouTube')),
          find.byKey(const Key('combined-focus-Kick')),
        ],
      },
    );
    await _settings.put(SettingsKeys.StreamingMode.name, false);
    await _pump(tester, 1200);

    await ackServer.close(force: true);
    _log('STORE-SHOTS: done');
  });
}
