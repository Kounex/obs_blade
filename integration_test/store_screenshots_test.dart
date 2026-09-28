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
// tests use) with fictional viewers - no network, no real accounts. The
// seeding is shared with store_video_test.dart (store_capture_support.dart).

import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:integration_test/integration_test.dart';
import 'package:obs_blade/main.dart' as app;
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/models/past_stream_data.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/combined_chat.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/stores/views/home.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/routing_helper.dart';
import 'package:obs_blade/views/dashboard/dashboard.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/audio_inputs/audio_inputs.dart';
import 'package:obs_blade/views/intro/intro.dart';
import 'package:obs_blade/views/statistics/statistic_detail/statistic_detail.dart';

import 'store_capture_support.dart';

/// Comma-separated shot names to capture (empty = all) - lets a re-run
/// grab just the frames that need another take.
const String kOnly = String.fromEnvironment('STORE_SHOTS_ONLY');

late CaptureAcks _acks;

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
    await pumpMs(tester, min(settleMs, 800));
    return;
  }
  await pumpMs(tester, settleMs);
  crops.forEach((key, finders) => _crop(tester, name, key, finders));
  await _acks.request(
    'SHOT: $name',
    name,
    warning: 'WARN: no capture ack for $name',
  );
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
    storeLog('WARN: crop $shot/$key - nothing found');
    return;
  }
  final Size screen = tester.view.physicalSize / tester.view.devicePixelRatio;
  final Rect clamped = rect.inflate(pad).intersect(Offset.zero & screen);
  String f(double v) => v.toStringAsFixed(4);
  storeLog(
    'CROP: $shot $key ${f(clamped.left / screen.width)} '
    '${f(clamped.top / screen.height)} ${f(clamped.width / screen.width)} '
    '${f(clamped.height / screen.height)}',
  );
}

// ------------------------------------------------------------------- test

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('store screenshots', (WidgetTester tester) async {
    app.main();
    await pumpMs(tester, 5000);

    _acks = await CaptureAcks.bind();

    // Seed while the intro is still the root route: the tab shell (every
    // tab is built eagerly) must not exist yet when the chat stores are
    // swapped, or its observers stay bound to the real stores.
    if (find.byType(IntroView).evaluate().isEmpty) {
      storeLog('ERROR: expected a fresh install booting into the intro');
    }
    // The test connects to its seeded connection directly - no need for an
    // autodiscover scan (and its LAN address) on screen
    GetIt.instance<HomeStore>().setConnectMode(ConnectMode.Manual);
    seedSettings();
    await seedStats();
    final Connection connection = await seedConnection();
    await seedChatAuth();
    installFakeChatStores();
    await settingsBox.put(
      SettingsKeys.SelectedChatType.name,
      ChatType.Combined,
    );
    seedChatAccounts();
    seedChatMessages();
    await pumpMs(tester, 1500);

    await _shot(tester, 'intro_welcome', settleMs: 1500);
    if (find.byType(IntroView).evaluate().isNotEmpty) {
      Navigator.of(
        tester.element(find.byType(IntroView).first),
        rootNavigator: true,
      ).pushReplacementNamed(AppRoutingKeys.Tabs.route);
    }
    await pumpMs(tester, 3000);

    // ========================= STATISTICS =========================
    // Before connecting: a live session adds its own (unnamed) entries.
    switchTab(Tabs.Statistics);
    await _shot(tester, 'stats_landing', settleMs: 2500);
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
    popInTab(Tabs.Statistics);
    await pumpMs(tester, 1000);

    // ========================== SETTINGS ==========================
    switchTab(Tabs.Settings);
    await _shot(tester, 'settings', settleMs: 2000);
    pushInTab(
      Tabs.Settings,
      SettingsTabRoutingKeys.DashboardCustomisation.route,
    );
    await _shot(tester, 'customisation', settleMs: 2200);
    pushInTab(
      Tabs.Settings,
      SettingsTabRoutingKeys.DashboardCustomisationOrder.route,
    );
    await _shot(tester, 'customisation_order', settleMs: 2200);
    popInTab(Tabs.Settings);
    await pumpMs(tester, 800);
    popInTab(Tabs.Settings);
    await pumpMs(tester, 800);
    pushInTab(Tabs.Settings, SettingsTabRoutingKeys.CustomTheme.route);
    await _shot(tester, 'themes', settleMs: 2200);
    popInTab(Tabs.Settings);
    await pumpMs(tester, 800);

    // ============================ CHAT ============================
    seedChatAccounts();
    seedChatMessages();
    switchTab(Tabs.Chat);
    await pumpMs(tester, 3000);
    // Channel activation settles asynchronously - re-assert the seeded
    // state right before the capture
    seedChatAccounts();
    seedChatMessages();
    await pumpMs(tester, 800);
    seedChatAccounts();
    final CombinedChatStore combined = GetIt.instance<CombinedChatStore>();
    storeLog(
      'STATE-INFO: combined active=${combined.active} '
      'sources=${combined.activeSources.length} '
      'live=${combined.liveSources}',
    );
    storeLog(
      'STATE-INFO: same twitch=${identical(GetIt.instance<TwitchChatStore>(), fakeTwitch)} '
      'twitchLoggedIn=${fakeTwitch.isLoggedIn} user=${fakeTwitch.user?.login} '
      'ytOwn=${fakeYouTube.ownChannel?.label} kick=${fakeKick.ownChannelSlug} '
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
    switchTab(Tabs.Home);
    await pumpMs(tester, 800);
    unawaited(GetIt.instance<NetworkStore>().setOBSWebSocket(connection));
    final bool dashboard = await waitUntil(
      tester,
      () => find.byType(DashboardView).evaluate().isNotEmpty,
      timeoutMs: 25000,
    );
    if (!dashboard) {
      storeLog(
        'ERROR: dashboard not reached - is the demo OBS up at $kObsHost?',
      );
      await _shot(tester, 'error_connect', settleMs: 500);
      await _acks.close();
      return;
    }
    await pumpMs(tester, 3000);
    final ScrollController? dashScroll = routeScroll(tester, DashboardView);

    // Expand the scene preview (the warning is pre-dismissed by settings)
    final Finder previewTile = find.text('Current OBS scene preview');
    await scrollToTarget(tester, dashScroll, previewTile, topInset: 400);
    if (previewTile.hitTestable().evaluate().isNotEmpty) {
      await tester.tap(previewTile.hitTestable().first);
      await pumpMs(tester, 1000);
    }
    await waitUntil(
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
      await pumpMs(tester, 1000);
      await _shot(tester, 'dashboard_controls', settleMs: 1500);
      await tester.tap(controls.hitTestable().first);
      await pumpMs(tester, 800);
    }

    await scrollToTarget(tester, dashScroll, previewTile, topInset: 110);
    await _shot(tester, 'dashboard_preview', settleMs: 2000);

    await scrollToTarget(
      tester,
      dashScroll,
      find.text('Scene Items'),
      topInset: 160,
    );
    await _shot(tester, 'dashboard_scene_items', settleMs: 1200);
    final Finder audioTab = find.text('Audio').hitTestable();
    if (audioTab.evaluate().isNotEmpty) {
      await tester.tap(audioTab.first);
      await pumpMs(tester, 1000);
    } else {
      storeLog('WARN: Audio tab not hittable');
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
        // scoped to the mixer: the scene item list and the Media Hub have a
        // 'Music' too (side by side on tablets)
        'fader': [
          find.descendant(
            of: find.byType(AudioInputs),
            matching: find.text('Music'),
          ),
          find.byWidgetPredicate((w) => w is Slider || w is CupertinoSlider),
        ],
      },
    );
    await scrollToTarget(
      tester,
      dashScroll,
      find.text('OBS Stats'),
      topInset: 160,
    );
    await _shot(tester, 'dashboard_stats', settleMs: 2500);
    if (dashScroll != null && dashScroll.hasClients) dashScroll.jumpTo(0);
    await pumpMs(tester, 800);

    // ======================= STREAMING MODE =======================
    await settingsBox.put(SettingsKeys.StreamingMode.name, true);
    await pumpMs(tester, 1500);
    seedChatAccounts();
    seedChatMessages();
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
    await settingsBox.put(SettingsKeys.StreamingMode.name, false);
    await pumpMs(tester, 1200);

    await _acks.close();
    storeLog('STORE-SHOTS: done');
  });
}
