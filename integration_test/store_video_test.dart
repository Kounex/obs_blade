// Store video capture for OBS Blade (tool/store_screenshots/README.md,
// "Video mode"): App Store app previews and the Play preview video are cut
// from these screen recordings of the real app.
//
// Same dedicated-device rule and seeding as store_screenshots_test.dart
// (shared: store_capture_support.dart). The demo OBS starts OFFLINE - the
// `golive` clip goes live through the app itself. Markers, each waiting for
// the host's ack (tool/store_screenshots/record.sh):
//
//   REC_START: <clip>          recorder running  -> ack start:<clip>
//   REC_STOP: <clip>           file finalized    -> ack stop:<clip>
//   CUE: <clip> <label> <ms>   a key moment, ms since the start ack - the
//                              wrapper turns it into seconds into the file
//                              (cues.json) so the edit can cut on it
//
// Every clip gets about a second of idle lead-in and tail. Two things keep
// the footage clean: the binding draws every frame the app asks for
// (`fullyLive` - the default only paints when the test pumps, ~4 fps on a
// recording), and taps go in as device pointer events (deviceTap), which
// the live binding does not mark with its debug crosshair.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:integration_test/integration_test.dart';
import 'package:obs_blade/main.dart' as app;
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/models/past_record_data.dart';
import 'package:obs_blade/models/past_stream_data.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/base/adaptive_switch.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/stores/views/home.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/routing_helper.dart';
import 'package:obs_blade/views/dashboard/dashboard.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_buttons/scene_button.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/audio_inputs/audio_inputs.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/studio_mode_checkbox.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/studio_mode_transition_button.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/combined_chat_input.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_input.dart';
import 'package:obs_blade/views/intro/intro.dart';
import 'package:obs_blade/views/settings/widgets/action_block.dart/block_entry.dart';
import 'package:obs_blade/views/statistics/statistic_detail/statistic_detail.dart';

import 'store_capture_support.dart';

/// Comma-separated clip names to record (empty = all) - the flow still
/// runs every step (later clips build on earlier state), only the
/// recording is skipped.
const String kOnly = String.fromEnvironment('STORE_VIDEO_ONLY');

/// New fictional chat lines for the live clips (the seeded backlog is
/// kChatScript).
const List<ChatLine> _liveChat = [
  (ChatType.Twitch, 'pixel_pilot', '#9147FF', 'NO WAY that overtake 😱'),
  (ChatType.Kick, 'apexhunter', '#53FC18', 'gap is growing 📈'),
  (ChatType.YouTube, 'Mara Lindqvist', '', 'This track is so pretty'),
  (ChatType.Twitch, 'LunaLoops', '#FF7AB6', 'hype train incoming 🚂'),
  (ChatType.Twitch, 'kaicodes', '#64D2FF', 'those lines are clean'),
  (ChatType.Kick, 'turbo_tilde', '#FFD60A', 'P1 P1 P1'),
  (ChatType.YouTube, 'Tobi Racing', '', 'Sector 3 personal best!'),
  (ChatType.Twitch, 'synthwave_sam', '#FF9F0A', 'the music on this one 🎶'),
  (ChatType.Twitch, 'mod_moxie', '#30D158', 'welcome in, new folks 💜'),
  (ChatType.YouTube, 'Aiko', '', 'Almost 2am here, worth it'),
  (ChatType.Kick, 'driftwood', '#53FC18', 'how many laps left?'),
  (ChatType.Twitch, 'grid_ghost', '#3DE8FF', 'GG GG GG'),
  (ChatType.Twitch, 'pixel_pilot', '#9147FF', 'chat is moving fast today'),
  (ChatType.YouTube, 'Jonas', '', 'That drift was textbook'),
  (ChatType.Kick, 'apexhunter', '#53FC18', 'no brakes needed 😂'),
  (ChatType.Twitch, 'LunaLoops', '#FF7AB6', 'Nova carrying again'),
  (ChatType.Twitch, 'kaicodes', '#64D2FF', 'is this the new build?'),
  (ChatType.YouTube, 'Mara Lindqvist', '', 'Final lap vibes'),
  (ChatType.Kick, 'turbo_tilde', '#FFD60A', 'clip that finish'),
  (ChatType.Twitch, 'synthwave_sam', '#FF9F0A', 'best stream this week'),
  (ChatType.YouTube, 'Tobi Racing', '', 'Lap record incoming?'),
  (ChatType.Twitch, 'grid_ghost', '#3DE8FF', 'the sunset on this map 🌅'),
  (ChatType.Kick, 'driftwood', '#53FC18', 'hello from the Kick side 👋'),
  (ChatType.Twitch, 'pixel_pilot', '#9147FF', 'VICTORY LAP 🏁'),
];

const String _reply = 'Thanks for hanging out, final lap coming up! 🏁';

/// Clip bookkeeping: markers, cues, lead-in and tail.
class _Recorder {
  _Recorder(this.tester, this.acks);

  final WidgetTester tester;
  final CaptureAcks acks;
  String? _clip;
  final Stopwatch _clock = Stopwatch();

  static bool _wanted(String name) =>
      kOnly.isEmpty || kOnly.split(',').map((s) => s.trim()).contains(name);

  Future<void> clip(
    String name,
    Future<void> Function() body, {
    int leadMs = 1000,
    int tailMs = 1000,
  }) async {
    final bool wanted = _wanted(name);
    if (wanted) {
      await acks.request(
        'REC_START: $name',
        'start:$name',
        timeout: const Duration(seconds: 30),
        warning: 'WARN: recorder for $name did not confirm the start',
      );
      _clip = name;
      _clock
        ..reset()
        ..start();
    }
    await pumpMs(tester, leadMs);
    await body();
    await pumpMs(tester, tailMs);
    if (wanted) {
      cue('end');
      _clip = null;
      await acks.request(
        'REC_STOP: $name',
        'stop:$name',
        timeout: const Duration(seconds: 90),
        warning: 'WARN: recorder for $name did not confirm the stop',
      );
    }
  }

  void cue(String label) {
    if (_clip == null) return;
    storeLog('CUE: $_clip $label ${_clock.elapsedMilliseconds}');
  }
}

/// New messages on a timer while a chat clip records (the fake stores are
/// filled once otherwise).
class _ChatFeeder {
  final Random _random = Random(11);
  Timer? _timer;
  int _next = 0;

  void start() {
    stop();
    _schedule();
  }

  void _schedule() {
    _timer = Timer(Duration(milliseconds: 500 + _random.nextInt(700)), () {
      addChatMessage(
        _liveChat[_next % _liveChat.length],
        id: 'live-$_next',
        kickSenderId: 300 + _next,
      );
      _next++;
      _schedule();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

/// The scene tile named [name] - the tile itself, not its label: the
/// tile's ring is stacked over the label, so the label never hit-tests.
Finder _scene(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(SceneButton));

Finder _settingsSwitch(String title) => find.descendant(
  of: find.ancestor(of: find.text(title), matching: find.byType(BlockEntry)),
  matching: find.byType(BaseAdaptiveSwitch),
);

DashboardStore get _dashboard => GetIt.instance<DashboardStore>();

/// The session this run went live with lands in "Latest Stats" as
/// "Unnamed entry" - give it a show name like the seeded ones.
void _nameLiveSession() {
  const String name = 'Neon Circuit - Finals night';
  for (final PastStreamData data in Hive.box<PastStreamData>(
    HiveKeys.PastStreamData.name,
  ).values.where((d) => d.name == null)) {
    data
      ..name = name
      ..save();
  }
  for (final PastRecordData data in Hive.box<PastRecordData>(
    HiveKeys.PastRecordData.name,
  ).values.where((d) => d.name == null)) {
    data
      ..name = name
      ..save();
  }
}

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('store video', (WidgetTester tester) async {
    final CaptureAcks acks = await CaptureAcks.bind();
    // deviceTap's events are device-sourced - the binding drops those
    // unless told to propagate them (reset before the test ends, the
    // binding verifies that)
    binding.shouldPropagateDevicePointerEvents = true;
    try {
      await _flow(tester, _Recorder(tester, acks));
    } finally {
      binding.shouldPropagateDevicePointerEvents = false;
      await acks.close();
    }
  });
}

Future<void> _flow(WidgetTester tester, _Recorder rec) async {
  final _ChatFeeder feeder = _ChatFeeder();

  // ============================ INTRO ============================
  // The binding shows "Test starting..." until the app runs - cover it
  // with the app's scaffold color, then start recording before the boot
  // so the Welcome slide's scale-in is on tape from its first frame
  runApp(const ColoredBox(color: Color(0xFF212123)));
  await tester.pump();
  await rec.clip('intro', () async {
    rec.cue('launch');
    app.main();
    final bool booted = await waitUntil(
      tester,
      () => find.byType(IntroView).evaluate().isNotEmpty,
      timeoutMs: 20000,
      stepMs: 16,
    );
    rec.cue('welcome');
    if (!booted) {
      storeLog('ERROR: expected a fresh install booting into the intro');
    }
    // The test connects to its seeded connection directly - no autodiscover
    // scan (and its LAN address) on screen later
    GetIt.instance<HomeStore>().setConnectMode(ConnectMode.Manual);
    await pumpMs(tester, 10000);
    final Finder pages = find.descendant(
      of: find.byType(IntroView),
      matching: find.byType(PageView),
    );
    // hold each slide for (at least) one loop of its visual
    for (final (int page, String label, int holdMs) in [
      (1, 'dashboard', 14400),
      (2, 'customise', 9500),
      (3, 'stats', 10000),
    ]) {
      if (pages.evaluate().isEmpty) break;
      tester
          .widget<PageView>(pages.first)
          .controller!
          .animateToPage(
            page,
            duration: AppMotion.slow,
            curve: AppMotion.emphasized,
          );
      rec.cue(label);
      await pumpMs(tester, holdMs);
    }
  }, tailMs: 0);

  // Seed while the intro is still the root route: the tab shell (every tab
  // is built eagerly) must not exist yet when the chat stores are swapped
  seedSettings();
  await seedStats();
  final Connection connection = await seedConnection();
  await seedChatAuth();
  installFakeChatStores();
  await settingsBox.put(SettingsKeys.SelectedChatType.name, ChatType.Combined);
  seedChatAccounts();
  seedChatMessages();
  await pumpMs(tester, 1000);
  if (find.byType(IntroView).evaluate().isNotEmpty) {
    Navigator.of(
      tester.element(find.byType(IntroView).first),
      rootNavigator: true,
    ).pushReplacementNamed(AppRoutingKeys.Tabs.route);
  }
  await pumpMs(tester, 2500);

  // ======================= CONNECT (offline) =====================
  switchTab(Tabs.Home);
  await pumpMs(tester, 800);
  unawaited(GetIt.instance<NetworkStore>().setOBSWebSocket(connection));
  final bool reached = await waitUntil(
    tester,
    () => find.byType(DashboardView).evaluate().isNotEmpty,
    timeoutMs: 25000,
  );
  if (!reached) {
    storeLog('ERROR: dashboard not reached - is the demo OBS up at $kObsHost?');
    return;
  }
  await pumpMs(tester, 3000);
  if (_dashboard.isLive || _dashboard.isRecording) {
    storeLog('WARN: demo OBS is already live - record.sh starts it offline');
  }
  final ScrollController? dashScroll = routeScroll(tester, DashboardView);
  void dashTop() {
    if (dashScroll != null && dashScroll.hasClients) dashScroll.jumpTo(0);
  }

  // Expand the scene preview (the warning is pre-dismissed by settings)
  final Finder previewTile = find.text('Current OBS scene preview');
  await scrollToTarget(tester, dashScroll, previewTile, topInset: 400);
  await deviceTap(tester, previewTile);
  await waitUntil(
    tester,
    () => _dashboard.scenePreviewImageBytes != null,
    timeoutMs: 10000,
  );
  dashTop();
  await pumpMs(tester, 3000);

  // =========================== GO LIVE ===========================
  final Finder controls = find.text('Exposed Controls');
  await rec.clip('golive', () async {
    await deviceTap(tester, controls);
    rec.cue('controls_open');
    await pumpMs(tester, 1300);
    await deviceTap(tester, find.text('Go Live'));
    rec.cue('confirm_live');
    await pumpMs(tester, 1500);
    await deviceTap(tester, find.text('Yes'));
    rec.cue('go_live');
    await waitUntil(tester, () => _dashboard.isLive, stepMs: 16);
    rec.cue('live');
    await pumpMs(tester, 2000);
    await deviceTap(tester, find.text('Start'));
    rec.cue('confirm_rec');
    await pumpMs(tester, 1300);
    await deviceTap(tester, find.text('Yes'));
    rec.cue('start_rec');
    await waitUntil(tester, () => _dashboard.isRecording, stepMs: 16);
    rec.cue('recording');
    await pumpMs(tester, 1500);
    await deviceTap(tester, controls);
    rec.cue('controls_closed');
    await pumpMs(tester, 5000);
  });

  // ============================ SCENES ===========================
  await rec.clip('scenes', () async {
    for (final String scene in ['Talk', 'BRB', 'Game']) {
      await pumpMs(tester, 1300);
      await deviceTap(tester, _scene(scene));
      rec.cue(scene.toLowerCase());
      await pumpMs(tester, 1200);
    }
    await pumpMs(tester, 1300);
  });

  // ============================ AUDIO ============================
  // Frame the scene content card on its Audio tab, the mixer scrolled
  // past the (empty) global block - off camera. The tab row sits just
  // below the pinned header (status bar, title, LIVE/REC pills)
  final Finder audioTab = find.text('Audio');
  await scrollToTarget(tester, dashScroll, audioTab, topInset: 190);
  await deviceTap(tester, audioTab);
  await pumpMs(tester, 1200);
  final Finder mixer = find.descendant(
    of: find.byType(AudioInputs),
    matching: find.byType(Scrollable),
  );
  final Finder noGlobal = find.textContaining('No Global Audio source');
  if (mixer.evaluate().isNotEmpty && noGlobal.evaluate().isNotEmpty) {
    final ScrollPosition position = tester
        .state<ScrollableState>(mixer.first)
        .position;
    final double past =
        tester.getBottomLeft(noGlobal.first).dy -
        tester.getTopLeft(mixer.first).dy;
    position.jumpTo(past.clamp(0.0, position.maxScrollExtent));
  }
  await pumpMs(tester, 1500);
  await rec.clip('audio', () async {
    rec.cue('meters');
    await pumpMs(tester, 4000);
    // Mic is the mixer's third entry (obs_demo.dart setup --video) - in
    // view on a phone; otherwise scroll the mixer alone (ensureVisible
    // would move the dashboard too, the tab row under the header)
    final Finder muteMic = semanticsLabeled('Mute Mic');
    if (muteMic.evaluate().isNotEmpty &&
        muteMic.hitTestable().evaluate().isEmpty &&
        mixer.evaluate().isNotEmpty) {
      rec.cue('scroll_mic');
      final ScrollPosition position = tester
          .state<ScrollableState>(mixer.first)
          .position;
      final double below =
          tester.getBottomLeft(muteMic.first).dy -
          tester.getBottomLeft(mixer.first).dy;
      await position.animateTo(
        (position.pixels + below + 12).clamp(0.0, position.maxScrollExtent),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
      await pumpMs(tester, 900);
    }
    await deviceTap(tester, muteMic);
    rec.cue('mic_muted');
    await pumpMs(tester, 1800);
    await deviceTap(tester, semanticsLabeled('Unmute Mic'));
    rec.cue('mic_unmuted');
    await pumpMs(tester, 1500);
    await deviceTap(tester, find.text('Scene Items'));
    rec.cue('sources');
    await pumpMs(tester, 1500);
    await deviceTap(tester, semanticsLabeled('Hide Webcam'));
    rec.cue('webcam_hidden');
    await pumpMs(tester, 2000);
    await deviceTap(tester, semanticsLabeled('Show Webcam'));
    rec.cue('webcam_shown');
    await pumpMs(tester, 1500);
  });
  dashTop();

  // ============================= CHAT ============================
  switchTab(Tabs.Chat);
  await pumpMs(tester, 3000);
  // Channel activation settles asynchronously - re-assert the seeded
  // state right before recording
  seedChatAccounts();
  seedChatMessages();
  await pumpMs(tester, 800);
  seedChatAccounts();
  await pumpMs(tester, 1200);
  await rec.clip('chat', () async {
    feeder.start();
    rec.cue('feed');
    await pumpMs(tester, 6000);
    final Finder input = find.byType(CombinedChatInput);
    if (input.evaluate().isEmpty) {
      storeLog('WARN: chat input not found');
    } else {
      final CombinedChatInput dock = tester.widget(input.first);
      // The field focuses (cursor, send state) but the system keyboard
      // stays down: the test's fake text input takes the channel - a
      // simulator keyboard is region-specific (and shows its own
      // onboarding sheet the first time)
      tester.testTextInput.register();
      dock.focusNode.requestFocus();
      rec.cue('focus');
      await pumpMs(tester, 900);
      rec.cue('typing');
      for (int i = 1; i <= _reply.runes.length; i++) {
        final String typed = String.fromCharCodes(_reply.runes.take(i));
        dock.controller.value = TextEditingValue(
          text: typed,
          selection: TextSelection.collapsed(offset: typed.length),
        );
        await pumpMs(tester, 45 + (i * 37) % 50);
      }
      await pumpMs(tester, 700);
      await deviceTap(
        tester,
        find
            .descendant(
              of: find.byType(NativeChatInput),
              matching: find.byType(Pressable),
            )
            .last,
      );
      rec.cue('sent');
      await pumpMs(tester, 350);
      // EventSub's echo of the own message
      addChatMessage((
        ChatType.Twitch,
        'NovaRush',
        '#FF4654',
        _reply,
      ), id: 'reply');
      await pumpMs(tester, 1200);
      FocusManager.instance.primaryFocus?.unfocus();
      rec.cue('unfocus');
      await tester.pump();
      tester.testTextInput.unregister();
    }
    await pumpMs(tester, 3500);
    feeder.stop();
  });

  // ============================ STATS ============================
  switchTab(Tabs.Home);
  await pumpMs(tester, 800);
  await scrollToTarget(
    tester,
    dashScroll,
    find.text('OBS Stats'),
    topInset: 160,
  );
  await pumpMs(tester, 1500);
  await rec.clip('stats', () async {
    rec.cue('tiles');
    await pumpMs(tester, 6000);
    _nameLiveSession();
    switchTab(Tabs.Statistics);
    rec.cue('statistics');
    await pumpMs(tester, 1800);
    final List<PastStreamData> streams = Hive.box<PastStreamData>(
      HiveKeys.PastStreamData.name,
    ).values.toList();
    final PastStreamData featured = streams.firstWhere(
      (s) => s.name == kFeaturedStream,
      orElse: () => streams.first,
    );
    pushInTab(
      Tabs.Statistics,
      StaticticsTabRoutingKeys.Detail.route,
      arguments: featured,
    );
    rec.cue('detail');
    await pumpMs(tester, 2800);
    final Finder detailScrollable = find.descendant(
      of: find.byType(StatisticDetailView),
      matching: find.byType(Scrollable),
    );
    if (detailScrollable.evaluate().isNotEmpty) {
      final ScrollPosition position = tester
          .state<ScrollableState>(detailScrollable.first)
          .position;
      rec.cue('charts');
      await position.animateTo(
        min(position.maxScrollExtent, 700.0),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
      );
    }
    await pumpMs(tester, 3500);
  });
  popInTab(Tabs.Statistics);
  await pumpMs(tester, 800);
  switchTab(Tabs.Settings);
  dashTop();
  await pumpMs(tester, 1500);

  // ========================== CUSTOMISE ==========================
  await rec.clip('customise', () async {
    await deviceTap(tester, _settingsSwitch('Studio Mode'));
    rec.cue('studio_mode');
    await pumpMs(tester, 1300);
    await deviceTap(tester, find.text('Customisation'));
    rec.cue('customisation');
    await pumpMs(tester, 1600);
    await deviceTap(tester, _settingsSwitch('Replay Controls'));
    rec.cue('replay_controls');
    await pumpMs(tester, 900);
    await deviceTap(tester, _settingsSwitch('Hotkeys'));
    rec.cue('hotkeys');
    await pumpMs(tester, 1400);
    switchTab(Tabs.Home);
    rec.cue('dashboard');
    await pumpMs(tester, 1500);
    await deviceTap(
      tester,
      find.descendant(
        of: find.byType(StudioModeCheckbox),
        matching: find.byType(Checkbox),
      ),
    );
    rec.cue('studio_on');
    await waitUntil(tester, () => _dashboard.studioMode, stepMs: 16);
    await pumpMs(tester, 1500);
    await deviceTap(tester, _scene('BRB'));
    rec.cue('preview_brb');
    await pumpMs(tester, 1600);
    await deviceTap(
      tester,
      find.descendant(
        of: find.byType(StudioModeTransitionButton),
        matching: find.text('Transition'),
      ),
    );
    rec.cue('transition');
    await pumpMs(tester, 2500);
  });
  // Back to the plain live dashboard for the rest (off camera)
  await _dashboard.sendMutation(
    RequestType.SetStudioModeEnabled,
    fields: {'studioModeEnabled': false},
    label: 'Studio mode',
  );
  await pumpMs(tester, 800);
  await _dashboard.sendMutation(
    RequestType.SetCurrentProgramScene,
    fields: {'sceneName': 'Game'},
    label: 'Scene switch',
  );
  await settingsBox.putAll({
    SettingsKeys.ExposeStudioControls.name: false,
    SettingsKeys.ExposeReplayBufferControls.name: false,
    SettingsKeys.ExposeHotkeys.name: false,
  });
  popInTab(Tabs.Settings);
  await pumpMs(tester, 1500);

  // ======================== STREAMING MODE =======================
  await settingsBox.put(SettingsKeys.StreamingMode.name, true);
  await pumpMs(tester, 1500);
  seedChatAccounts();
  await pumpMs(tester, 2500);
  await rec.clip('streaming_mode', () async {
    feeder.start();
    rec.cue('cockpit');
    await pumpMs(tester, 3500);
    await deviceTap(tester, _scene('BRB'));
    rec.cue('brb');
    await pumpMs(tester, 4000);
    await deviceTap(tester, _scene('Game'));
    rec.cue('game');
    await pumpMs(tester, 3500);
    feeder.stop();
  });
  await settingsBox.put(SettingsKeys.StreamingMode.name, false);
  await pumpMs(tester, 1500);
  dashTop();
  await pumpMs(tester, 1000);

  // ========================= STOP STREAM =========================
  await rec.clip('stopstream', () async {
    await deviceTap(tester, controls);
    rec.cue('controls_open');
    await pumpMs(tester, 1300);
    await deviceTap(tester, find.text('Go Offline'));
    rec.cue('confirm_offline');
    await pumpMs(tester, 1500);
    await deviceTap(tester, find.text('Yes'));
    rec.cue('go_offline');
    await waitUntil(tester, () => !_dashboard.isLive, stepMs: 16);
    rec.cue('offline');
    await pumpMs(tester, 1500);
    await deviceTap(tester, find.text('Stop'));
    rec.cue('confirm_stop_rec');
    await pumpMs(tester, 1300);
    await deviceTap(tester, find.text('Yes'));
    rec.cue('stop_rec');
    await waitUntil(tester, () => !_dashboard.isRecording, stepMs: 16);
    rec.cue('rec_stopped');
    await pumpMs(tester, 1500);
    await deviceTap(tester, controls);
    rec.cue('controls_closed');
    await pumpMs(tester, 2500);
  });

  storeLog('STORE-VIDEO: done');
}
