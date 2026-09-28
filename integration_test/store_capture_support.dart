// Shared seeding + driving helpers for the store capture tests
// (tool/store_screenshots/README.md): store_screenshots_test.dart (SHOT
// markers, screenshots) and store_video_test.dart (REC_START / REC_STOP /
// CUE markers, screen recordings).
//
// Both boot the real app on a DEDICATED simulator/emulator - they write
// settings, stats, a saved connection and the Pro debug override - and
// seed the same believable "streamer" state. Chat is fed by fake-backed
// platform stores (the same fakes the widget tests use) with fictional
// viewers - no network, no real accounts.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/models/kick_auth.dart';
import 'package:obs_blade/models/past_record_data.dart';
import 'package:obs_blade/models/past_stream_data.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/models/youtube_auth.dart';
import 'package:obs_blade/stores/shared/tabs.dart';
import 'package:obs_blade/stores/views/combined_chat.dart';
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
import 'package:obs_blade/utils/routing_helper.dart';
import 'package:obs_blade/utils/kick/kick_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/youtube/youtube_auth_service.dart';
import 'package:obs_blade/utils/youtube_target.dart';

import '../test/chat/support/fake_kick_services.dart';
import '../test/chat/support/fake_twitch_services.dart';
import '../test/chat/support/fake_youtube_services.dart';

const String kObsHost = String.fromEnvironment(
  'OBS_HOST',
  defaultValue: '127.0.0.1',
);
const String kObsWsPassword = String.fromEnvironment('OBS_WS_PASSWORD');

/// Loopback port of the ack server the test runs inside the app process.
/// The capture wrapper on the host acks each marker once it has acted on it
/// (screenshot taken, recorder running / file finalized) - a hard handshake
/// instead of fixed delays, since VM service log lines arrive in bursts.
/// iOS simulators share the host's loopback; Android goes through
/// `adb forward`.
const int kAckPort = 8977;
const String kFeaturedStream = 'Neon Circuit - Grand Prix night';

void storeLog(String message) {
  // ignore: avoid_print
  print(message);
}

/// Pumps [ms] in steps of at most 250 ms.
Future<void> pumpMs(WidgetTester tester, int ms) async {
  int remaining = ms;
  while (remaining > 0) {
    final int step = remaining > 250 ? 250 : remaining;
    await tester.pump(Duration(milliseconds: step));
    remaining -= step;
  }
}

/// Pumps in [stepMs] steps until [test] holds (or [timeoutMs] passed).
Future<bool> waitUntil(
  WidgetTester tester,
  bool Function() test, {
  int timeoutMs = 20000,
  int stepMs = 250,
}) async {
  for (int waited = 0; waited < timeoutMs; waited += stepMs) {
    if (test()) return true;
    await pumpMs(tester, stepMs);
  }
  return test();
}

/// The ack server: [request] prints a marker line and waits until the host
/// wrapper calls `/ack?name=<key>`.
class CaptureAcks {
  CaptureAcks._(this._server) {
    _server.listen((HttpRequest request) {
      final String? name = request.uri.queryParameters['name'];
      final Completer<void>? ack = name != null ? _pending[name] : null;
      if (ack != null && !ack.isCompleted) ack.complete();
      request.response.statusCode = HttpStatus.ok;
      request.response.close();
    });
  }

  final HttpServer _server;
  final Map<String, Completer<void>> _pending = {};

  static Future<CaptureAcks> bind() async => CaptureAcks._(
    await HttpServer.bind(InternetAddress.loopbackIPv4, kAckPort),
  );

  /// Prints [line] and waits for the ack named [key]. No ack within
  /// [timeout] fails the test on the spot with [failure]: the host wrapper
  /// is gone or stuck, and a test left running on its own must not go on
  /// driving the app (and through it OBS - the wrapper's cleanup may have
  /// switched OBS back to the user's own profile by then).
  Future<void> request(
    String line,
    String key, {
    Duration timeout = const Duration(seconds: 12),
    required String failure,
  }) async {
    final Completer<void> ack = Completer<void>();
    _pending[key] = ack;
    storeLog(line);
    try {
      await ack.future.timeout(timeout);
    } on TimeoutException {
      storeLog('ERROR: $failure - aborting');
      fail(failure);
    } finally {
      _pending.remove(key);
    }
  }

  Future<void> close() => _server.close(force: true);
}

Box<dynamic> get settingsBox => Hive.box<dynamic>(HiveKeys.Settings.name);

void switchTab(Tabs tab) => GetIt.instance<TabsStore>().setActiveTab(tab);

void pushInTab(Tabs tab, String route, {Object? arguments}) =>
    GetIt.instance<TabsStore>().navigatorKeys[tab]!.currentState!.pushNamed(
      route,
      arguments: arguments,
    );

void popInTab(Tabs tab) =>
    GetIt.instance<TabsStore>().navigatorKeys[tab]!.currentState!.maybePop();

/// The ScrollController a tab route got as its arguments (dashboard, stats).
ScrollController? routeScroll(WidgetTester tester, Type view) {
  final Finder finder = find.byType(view);
  if (finder.evaluate().isEmpty) return null;
  final Object? args = ModalRoute.of(
    tester.element(finder.first),
  )?.settings.arguments;
  return args is ScrollController ? args : null;
}

/// Scrolls [controller] so [target]'s top lands [topInset] px below the top
/// of the screen. Jumps by default (screenshots); with [animate] it scrolls
/// on camera instead - in steps while the lazily built target is not
/// there yet, then onto it.
Future<void> scrollToTarget(
  WidgetTester tester,
  ScrollController? controller,
  Finder target, {
  double topInset = 110,
  Duration? animate,
}) async {
  if (controller == null || !controller.hasClients) return;
  for (int i = 0; i < 12 && target.evaluate().isEmpty; i++) {
    final double next = min(
      controller.offset + (animate != null ? 400 : 300),
      controller.position.maxScrollExtent,
    );
    if (animate != null) {
      await controller.animateTo(
        next,
        duration: const Duration(milliseconds: 280),
        curve: Curves.linear,
      );
      await tester.pump();
    } else {
      controller.jumpTo(next);
      await pumpMs(tester, 300);
    }
  }
  if (target.evaluate().isEmpty) {
    storeLog('WARN: scroll target not found: $target');
    return;
  }
  final double dy = tester.getTopLeft(target.first).dy - topInset;
  final double to = (controller.offset + dy).clamp(
    0.0,
    controller.position.maxScrollExtent,
  );
  if (animate != null) {
    await controller.animateTo(
      to,
      duration: animate,
      curve: Curves.easeInOutCubic,
    );
    await pumpMs(tester, 200);
  } else {
    controller.jumpTo(to);
    await pumpMs(tester, 600);
  }
}

int _nextPointer = 1 << 20;

/// Taps the center of [finder] the way a finger does - as a device pointer
/// event instead of a test one, so the live test binding paints no
/// crosshair over the app (it marks every test-sourced pointer down). The
/// caller sets `shouldPropagateDevicePointerEvents` for the test (see
/// store_video_test.dart). Holds [holdMs] so press states show.
Future<void> deviceTap(
  WidgetTester tester,
  Finder finder, {
  int holdMs = 120,
}) async {
  final Finder target = finder.hitTestable();
  if (target.evaluate().isEmpty) {
    storeLog('WARN: tap target not hittable: $finder');
    return;
  }
  final Offset at = tester.getCenter(target.first);
  final int pointer = _nextPointer++;
  final int viewId = tester.view.viewId;
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.instance;
  binding.handlePointerEventForSource(
    PointerDownEvent(pointer: pointer, viewId: viewId, position: at),
  );
  await pumpMs(tester, holdMs);
  binding.handlePointerEventForSource(
    PointerUpEvent(pointer: pointer, viewId: viewId, position: at),
  );
  await tester.pump();
}

/// A widget's [Semantics] wrapper by exact label - the app labels its icon
/// toggles ('Mute Mic', 'Hide Webcam') even where there is no text.
Finder semanticsLabeled(String label) => find.byWidgetPredicate(
  (Widget widget) => widget is Semantics && widget.properties.label == label,
);

// ---------------------------------------------------------------- seeding

void seedSettings() {
  settingsBox.putAll({
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
Future<void> seedStats() async {
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

Future<Connection> seedConnection() async {
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

late TwitchChatStore fakeTwitch;
late YouTubeChatStore fakeYouTube;
late KickChatStore fakeKick;

/// Swaps the (not yet created) lazy platform chat stores for fake-backed
/// ones. CombinedChatStore (created at boot) resolves them through GetIt
/// on every access, so it picks the fakes up. Twitch sends go to a fake
/// message service (the video's reply) - EventSub would echo a real send,
/// [addChatMessage] stands in for that.
void installFakeChatStores() {
  final GetIt getIt = GetIt.instance;
  fakeTwitch = TwitchChatStore(
    authService: FakeTwitchAuthService(),
    isProResolver: () => true,
    eventSubFactory: (_, _, _, _, _, _, _, _, _, _) =>
        FakeTwitchEventSubService(),
    ircSidecarFactory: (_) => FakeSilentIrcSidecar(),
    messageService: FakeTwitchMessageService(),
  );
  fakeYouTube = YouTubeChatStore(
    authService: FakeYouTubeAuthService(),
    chatService: FakeYouTubeLiveChatService(),
    liveResolver: FakeYouTubeLiveResolver(),
    isProResolver: () => true,
  );
  fakeKick = KickChatStore(
    channelService: FakeKickChannelService(),
    isProResolver: () => true,
    pusherFactory: ({required onEvent, required onStateChanged}) =>
        FakeKickPusherService(onEvent: onEvent, onStateChanged: onStateChanged),
  );
  for (final void Function() swap in [
    () => getIt
      ..unregister<TwitchChatStore>()
      ..registerSingleton<TwitchChatStore>(fakeTwitch),
    () => getIt
      ..unregister<YouTubeChatStore>()
      ..registerSingleton<YouTubeChatStore>(fakeYouTube),
    () => getIt
      ..unregister<KickChatStore>()
      ..registerSingleton<KickChatStore>(fakeKick),
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
      storeLog('WARN: store swap failed: $e');
    }
  }
}

/// Placeholder sessions with write scopes, so the chat dock shows its real
/// input instead of the read-only strip. The fake-backed stores never send
/// these anywhere.
Future<void> seedChatAuth() async {
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
void seedChatAccounts() {
  runInAction(() {
    fakeTwitch.user = const TwitchUser(
      id: '4242',
      login: 'novarush',
      displayName: 'NovaRush',
    );
    fakeTwitch.authState = TwitchAuthState.loggedIn;
    fakeTwitch.chatConnection = TwitchChatConnectionState.live;
    fakeTwitch.selectedChannelIsLive = true;
    fakeTwitch.selectedChannelViewerCount = 1284;

    fakeYouTube.authState = YouTubeAuthState.signedIn;
    fakeYouTube.ownChannel = const YouTubeChatChannel(
      label: kYouTubeOwnChannelLabel,
      target: YouTubeChannelTarget('channel/UCnovarush00000000000000'),
      isOwn: true,
      title: 'NovaRush',
    );
    fakeYouTube.chatConnection = YouTubeChatConnectionState.connected;
    fakeYouTube.selectedChannelViewerCount = 342;

    fakeKick.authState = KickAuthState.signedIn;
    fakeKick.ownChannelSlug = 'novarush';
    fakeKick.channelInfo = const KickChannelInfo(
      id: 1,
      slug: 'novarush',
      chatroom: KickChatroom(id: 2),
      livestream: KickLivestreamInfo(isLive: true, viewerCount: 187),
    );
    fakeKick.chatConnection = KickChatConnectionState.connected;
  });
}

/// (platform, author, name color, text) - fictional viewers, 4+.
typedef ChatLine = (ChatType, String, String, String);

const List<ChatLine> kChatScript = [
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

/// Appends one message to its platform's fake-backed store (what a live
/// EventSub / poll / Pusher event would do). [id] makes the message ids
/// unique; Kick senders get [kickSenderId] (default: stable per author).
void addChatMessage(
  ChatLine line, {
  required String id,
  DateTime? at,
  int? kickSenderId,
}) {
  final (ChatType platform, String author, String color, String text) = line;
  final DateTime when = at ?? DateTime.now();
  runInAction(() {
    switch (platform) {
      case ChatType.Twitch:
        fakeTwitch.messages.add(
          ChatMessageEvent(
            broadcasterUserId: '4242',
            chatterUserId: 'u-$author',
            chatterUserLogin: author.toLowerCase(),
            chatterUserName: author,
            messageId: 'store-tw-$id',
            color: color,
            message: ChatMessageText(
              text: text,
              fragments: [ChatMessageFragment(type: 'text', text: text)],
            ),
            receivedAt: when,
          ),
        );
      case ChatType.YouTube:
        fakeYouTube.messages.add(
          YouTubeChatMessage(
            id: 'store-yt-$id',
            snippet: YouTubeChatMessageSnippet(
              type: YouTubeChatMessageType.textMessage,
              publishedAt: when,
              authorChannelId: 'yt-$author',
              displayMessage: text,
              textMessageDetails: YouTubeTextMessageDetails(messageText: text),
            ),
            authorDetails: YouTubeChatAuthorDetails(
              channelId: 'yt-$author',
              displayName: author,
            ),
          ),
        );
      case ChatType.Kick:
        fakeKick.messages.add(
          KickChatMessage(
            id: 'store-kick-$id',
            content: text,
            createdAt: when,
            sender: KickChatSender(
              id: kickSenderId ?? 1000 + author.codeUnits.fold(0, _sum),
              username: author,
              slug: author,
              identity: KickChatIdentity(color: color),
            ),
          ),
        );
      default:
    }
  });
}

int _sum(int a, int b) => a + b;

void seedChatMessages() {
  final DateTime now = DateTime.now();
  runInAction(() {
    fakeTwitch.messages.clear();
    fakeYouTube.messages.clear();
    fakeKick.messages.clear();
    for (int i = 0; i < kChatScript.length; i++) {
      addChatMessage(
        kChatScript[i],
        id: '$i',
        at: now.subtract(Duration(seconds: (kChatScript.length - i) * 9)),
        kickSenderId: 100 + i,
      );
    }
  });
}
