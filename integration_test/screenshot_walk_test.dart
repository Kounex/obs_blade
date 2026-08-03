// Visual-QA screenshot walkthrough for OBS Blade (redesign branch).
//
// Boots the real app (with the simulator's real user data) and walks every
// screen, printing `SHOT: <name>` markers. A companion wrapper script
// (tool/visual_qa/capture_screenshots.sh) tails the flutter output and takes
// a `xcrun simctl` screenshot for each marker.
//
// READ-ONLY discipline: no clears, no deletes, no purchases, no settings
// toggles, nothing is saved. The only interactions are navigation, scrolling
// and opening/closing dialogs or sheets via their Cancel/close affordances.
// The intro's final "Start" buttons (which would persist
// `HasUserSeenIntro202208`) are deliberately NOT tapped - the test leaves the
// intro by replacing the root route, exactly like the settings entry does in
// reverse.

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:integration_test/integration_test.dart';
import 'package:obs_blade/main.dart' as app;
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/models/custom_theme.dart';
import 'package:obs_blade/models/past_record_data.dart';
import 'package:obs_blade/models/past_stream_data.dart';
import 'package:obs_blade/stores/shared/tabs.dart';
import 'package:obs_blade/stores/views/home.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/types/interfaces/past_stats_data.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/utils/routing_helper.dart';
import 'package:obs_blade/views/dashboard/dashboard.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_preview/scene_preview.dart';
import 'package:obs_blade/views/home/home.dart';
import 'package:obs_blade/views/home/widgets/connect_box/connect_form/connect_form.dart';
import 'package:obs_blade/views/intro/intro.dart';
import 'package:obs_blade/views/settings/about/about.dart';
import 'package:obs_blade/views/settings/custom_theme/custom_theme.dart';
import 'package:obs_blade/views/settings/custom_theme/widgets/add_edit_theme/add_edit_theme.dart';
import 'package:obs_blade/views/settings/logs/widgets/log_grid/log_tile.dart';
import 'package:obs_blade/views/settings/settings.dart';
import 'package:obs_blade/views/settings/widgets/support_dialog/support_dialog.dart';
import 'package:obs_blade/views/statistics/statistics.dart';

const String kObsWsPassword = String.fromEnvironment('OBS_WS_PASSWORD');

/// Port of the tiny ack server the test runs inside the app process. The
/// iOS simulator shares the host's loopback interface, so the wrapper script
/// on the host can reach this via 127.0.0.1 to confirm each capture - a
/// hard handshake instead of racy fixed delays (VM service log lines arrive
/// in bursts, which made plain marker+sleep captures lag behind).
const int kAckPort = 8977;

final Map<String, Completer<void>> _shotAcks = {};

/// In the live test binding (fadePointers frame policy) tickers only advance
/// on pump-driven frames, and a route's entrance animation only *starts*
/// ticking at the first drawn frame after the push. A single long pump
/// therefore leaves pushed routes at animation position 0 (off-screen) at
/// capture time. Chunking every wait into <=500ms frames lets transitions,
/// entrances and countdown animations actually complete.
Future<void> _pump(WidgetTester tester, int ms) async {
  int remaining = ms;
  while (remaining > 0) {
    final int stepMs = remaining > 500 ? 500 : remaining;
    await tester.pump(Duration(milliseconds: stepMs));
    remaining -= stepMs;
  }
}

/// Settle, then emit the marker the wrapper script is listening for and wait
/// until it confirms the screenshot (falls back to a timeout when the test
/// is run without the wrapper).
Future<void> _shot(
  WidgetTester tester,
  String name, {
  int settleMs = 1800,
}) async {
  await _pump(tester, settleMs);
  final Completer<void> ack = Completer<void>();
  _shotAcks[name] = ack;
  // ignore: avoid_print
  print('SHOT: $name');
  await ack.future.timeout(
    const Duration(seconds: 8),
    onTimeout: () {
      // ignore: avoid_print
      print('WARN: no capture ack for $name (wrapper not running?)');
    },
  );
  _shotAcks.remove(name);
}

Future<bool> _tryTap(
  WidgetTester tester,
  Finder finder, {
  int settleMs = 1200,
  bool warnIfMissed = true,
  String? warnOnMissing,
}) async {
  if (finder.evaluate().isEmpty) {
    // ignore: avoid_print
    print('WARN: finder empty, tap skipped (${warnOnMissing ?? finder})');
    return false;
  }
  try {
    await tester.tap(finder.first, warnIfMissed: warnIfMissed);
    await _pump(tester, settleMs);
    return true;
  } catch (e) {
    // ignore: avoid_print
    print('WARN: tap failed (${warnOnMissing ?? finder}): $e');
    return false;
  }
}

/// Deterministic scroll-into-view: jump the first [Scrollable] inside
/// [within] in fixed steps until [target] is actually hittable (i.e. not
/// clipped and not hidden under a translucent nav bar), then let the caller
/// tap it. Never awaits animation futures - plain jumpTo only, so it cannot
/// stall inside the live test binding.
Future<bool> _scrollUntilHittable(
  WidgetTester tester,
  Finder target, {
  required Finder within,
  double step = 220.0,
  int maxSteps = 10,
}) async {
  final Finder scrollableFinder = find.descendant(
    of: within,
    matching: find.byType(Scrollable),
  );
  for (int i = 0; i <= maxSteps; i++) {
    // NOTE: no early-out on an empty finder - sliver-based lists only build
    // children near the viewport, so the target may not exist in the tree
    // until we have scrolled far enough
    if (target.hitTestable().evaluate().isNotEmpty) return true;
    if (scrollableFinder.evaluate().isEmpty) break;
    final ScrollableState state =
        tester.state<ScrollableState>(scrollableFinder.first);
    final ScrollPosition position = state.position;
    if (!position.hasPixels ||
        position.pixels >= position.maxScrollExtent) {
      break;
    }
    position.jumpTo(position.pixels + step);
    await _pump(tester, 500);
  }
  final bool hittable = target.hitTestable().evaluate().isNotEmpty;
  if (!hittable) {
    // ignore: avoid_print
    print('WARN: target not hittable after scrolling: $target');
  }
  return hittable;
}

/// Poll until a finder matches (used for the intro slide lock countdowns,
/// whose real duration is not reliably predictable under test load).
Future<bool> _waitFor(
  WidgetTester tester,
  Finder finder, {
  int timeoutMs = 25000,
  int stepMs = 500,
}) async {
  final int steps = (timeoutMs / stepMs).ceil();
  for (int i = 0; i < steps; i++) {
    if (finder.evaluate().isNotEmpty) return true;
    await _pump(tester, stepMs);
  }
  // ignore: avoid_print
  print('WARN: timed out waiting for $finder');
  return false;
}

void _switchTab(Tabs tab) =>
    GetIt.instance<TabsStore>().setActiveTab(tab);

void _pushInTab(Tabs tab, String route, {Object? arguments}) {
  GetIt.instance<TabsStore>()
      .navigatorKeys[tab]!
      .currentState!
      .pushNamed(route, arguments: arguments);
}

void _popInTab(Tabs tab) =>
    GetIt.instance<TabsStore>().navigatorKeys[tab]!.currentState!.pop();

ScrollController? _routeScrollController(WidgetTester tester, Finder view) {
  if (view.evaluate().isEmpty) return null;
  final BuildContext context = tester.element(view.first);
  final Object? args = ModalRoute.of(context)?.settings.arguments;
  return args is ScrollController ? args : null;
}

Future<void> _jumpTo(
  WidgetTester tester,
  ScrollController? controller,
  double offset,
) async {
  if (controller != null && controller.hasClients) {
    controller.jumpTo(offset);
    await _pump(tester, 900);
  }
}

/// Relative scroll nudge (clamped by the position itself) used to frame
/// dashboard sections after a tab has been made visible / selected.
Future<void> _nudge(
  WidgetTester tester,
  ScrollController? controller,
  double delta,
) async {
  if (controller != null && controller.hasClients) {
    controller.jumpTo(controller.offset + delta);
    await _pump(tester, 600);
  }
}

Future<void> _dismissBarrierDialog(WidgetTester tester) async {
  // Tap well outside any centered dialog / above a bottom sheet.
  await tester.tapAt(const Offset(24.0, 72.0));
  await _pump(tester, 1000);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'visual QA screenshot walk',
    (WidgetTester tester) async {
      app.main();
      await _pump(tester, 5000); // native splash + app boot + entrances

      // Fresh install (no HasUserSeenIntro202208): the app boots into the
      // intro instead of the tabs. Move to the tabs exactly like the
      // intro's own Start button does - minus the settings write.
      if (find.byType(IntroView).evaluate().isNotEmpty) {
        // ignore: avoid_print
        print('STATE-INFO: app booted into intro (fresh install) - '
            'replacing root route with /tabs');
        final BuildContext bootIntroContext =
            tester.element(find.byType(IntroView).first);
        Navigator.of(bootIntroContext, rootNavigator: true)
            .pushReplacementNamed(AppRoutingKeys.Tabs.route);
        await _pump(tester, 3500);
      }

      // A StoreKit restore on boot may surface the Blacksmith-restored
      // dialog - dismiss it (it is informational only).
      if (find
          .text('Your Blacksmith purchase has been restored!\n\nEnjoy!')
          .evaluate()
          .isNotEmpty) {
        // ignore: avoid_print
        print('STATE-INFO: Blacksmith restore dialog shown - dismissing');
        await _tryTap(tester, find.text('OK'),
            warnOnMissing: 'blacksmith restored OK');
        await _pump(tester, 800);
      }

      // Ack server: the wrapper script calls /ack?name=<shot> after each
      // simctl capture so the walk only continues once the PNG exists.
      final HttpServer ackServer =
          await HttpServer.bind(InternetAddress.loopbackIPv4, kAckPort);
      ackServer.listen((HttpRequest request) {
        final String? name = request.uri.queryParameters['name'];
        final Completer<void>? ack = name != null ? _shotAcks[name] : null;
        if (ack != null && !ack.isCompleted) ack.complete();
        request.response.statusCode = HttpStatus.ok;
        request.response.close();
      });

      // ---- State snapshot (for the post-walk integrity check) ----
      final Box settingsBox = Hive.box(HiveKeys.Settings.name);
      final Map<dynamic, dynamic> settingsSnapshot =
          Map<dynamic, dynamic>.from(settingsBox.toMap());
      final bool hadPreviewWarningKey =
          settingsBox.containsKey(SettingsKeys.DontShowPreviewWarning.name);
      final int savedConnectionsCount =
          Hive.box<Connection>(HiveKeys.SavedConnections.name).length;
      final int customThemeCount =
          Hive.box<CustomTheme>(HiveKeys.CustomTheme.name).length;
      final int statsCount =
          Hive.box<PastStreamData>(HiveKeys.PastStreamData.name).length +
              Hive.box<PastRecordData>(HiveKeys.PastRecordData.name).length;
      // ignore: avoid_print
      print(
          'STATE-INFO: connections=$savedConnectionsCount themes=$customThemeCount stats=$statsCount settingsKeys=${settingsSnapshot.length}');

      // ============================ HOME ============================
      // ignore: avoid_print
      print('=== SECTION: home ===');
      _switchTab(Tabs.Home);
      await _shot(tester, '01_home_top', settleMs: 2500);

      final ScrollController? homeScroll =
          _routeScrollController(tester, find.byType(HomeView));

      GetIt.instance<HomeStore>().setConnectMode(ConnectMode.Manual);
      await _shot(tester, '02_home_connect_manual');

      GetIt.instance<HomeStore>().setConnectMode(ConnectMode.QR);
      // NOTE: the camera is never opened - the "Scan" button is not tapped.
      await _shot(tester, '03_home_connect_qr');

      GetIt.instance<HomeStore>().setConnectMode(ConnectMode.Autodiscover);
      await _pump(tester, 1500);
      if (homeScroll != null && homeScroll.hasClients) {
        await _jumpTo(tester, homeScroll, homeScroll.position.maxScrollExtent);
      }
      await _shot(tester, '04_home_saved_connections', settleMs: 900);
      await _jumpTo(tester, homeScroll, 0.0);

      // ========================= STATISTICS =========================
      // ignore: avoid_print
      print('=== SECTION: statistics ===');
      _switchTab(Tabs.Statistics);
      await _shot(tester, '10_statistics_landing', settleMs: 2600);

      final bool panelOpened = await _scrollUntilHittable(
            tester,
            find.text('Sort and filter panel'),
            within: find.byType(StatisticsView),
          ) &&
          await _tryTap(
            tester,
            find.text('Sort and filter panel'),
            warnOnMissing: 'sort/filter panel header',
          );
      if (panelOpened) {
        await _shot(tester, '11_statistics_sort_filter', settleMs: 700);
        await _tryTap(tester, find.text('Sort and filter panel'),
            warnOnMissing: 'sort/filter panel header (collapse)');
      }

      // Statistic detail for the most recent entry (if any exist)
      final List<PastStatsData> allStats = [
        ...Hive.box<PastStreamData>(HiveKeys.PastStreamData.name).values,
        ...Hive.box<PastRecordData>(HiveKeys.PastRecordData.name).values,
      ];
      if (allStats.isNotEmpty) {
        allStats.sort((a, b) => a.listEntryDateMS.last
            .compareTo(b.listEntryDateMS.last));
        _pushInTab(
          Tabs.Statistics,
          StaticticsTabRoutingKeys.Detail.route,
          arguments: allStats.last,
        );
        await _shot(tester, '12_statistics_detail', settleMs: 2600);
        _popInTab(Tabs.Statistics);
        await _pump(tester, 1200);
      } else {
        // ignore: avoid_print
        print('INFO: no past statistics - detail shot skipped');
      }

      // ========================== SETTINGS ==========================
      // ignore: avoid_print
      print('=== SECTION: settings ===');
      _switchTab(Tabs.Settings);
      await _shot(tester, '20_settings_top', settleMs: 2600);

      final ScrollController? settingsScroll =
          _routeScrollController(tester, find.byType(SettingsView));
      if (settingsScroll != null && settingsScroll.hasClients) {
        await _jumpTo(
            tester, settingsScroll, settingsScroll.position.maxScrollExtent);
      }
      await _shot(tester, '21_settings_bottom', settleMs: 700);
      await _jumpTo(tester, settingsScroll, 0.0);

      // Dashboard Customisation + Order editor
      _pushInTab(
          Tabs.Settings, SettingsTabRoutingKeys.DashboardCustomisation.route);
      await _shot(tester, '22_settings_dashboard_customisation',
          settleMs: 2200);
      _pushInTab(Tabs.Settings,
          SettingsTabRoutingKeys.DashboardCustomisationOrder.route);
      await _shot(tester, '23_settings_customisation_order', settleMs: 2200);
      _popInTab(Tabs.Settings);
      await _pump(tester, 1000);
      _popInTab(Tabs.Settings);
      await _pump(tester, 1000);

      // Custom Theme list
      _pushInTab(Tabs.Settings, SettingsTabRoutingKeys.CustomTheme.route);
      await _shot(tester, '24_settings_custom_theme', settleMs: 2200);

      // Add/Edit theme editor. Without the Blacksmith purchase this shows the
      // support dialog instead - captured and dismissed without buying.
      final bool addThemeTapped = await _scrollUntilHittable(
            tester,
            find.text('Add Theme'),
            within: find.byType(CustomThemeView),
          ) &&
          await _tryTap(
            tester,
            find.text('Add Theme'),
            warnOnMissing: 'Add Theme button',
          );
      if (addThemeTapped) {
        await _pump(tester, 1500);
        if (find.byType(AddEditTheme).evaluate().isNotEmpty) {
          await _shot(tester, '25_theme_editor', settleMs: 1800);

          // Open the Color Picker via the "Card Color" row (Cancel - no save)
          final bool colorRowTapped = await _scrollUntilHittable(
                tester,
                find.text('Card Color'),
                within: find.byType(AddEditTheme),
              ) &&
              await _tryTap(
                tester,
                find.text('Card Color'),
                warnOnMissing: 'Card Color theme row',
              );
          if (colorRowTapped) {
            await _shot(tester, '26_theme_color_picker', settleMs: 1800);
            await _tryTap(tester, find.text('Cancel'),
                warnOnMissing: 'color picker Cancel');
            await _pump(tester, 800);
          }
          // Close the editor sheet without saving (top-right close button)
          await _tryTap(
            tester,
            find.byIcon(CupertinoIcons.clear_circled_solid),
            warnOnMissing: 'theme editor close button',
          );
          await _pump(tester, 800);
        } else if (find.byType(SupportDialog).evaluate().isNotEmpty) {
          await _shot(tester, '25_theme_editor_locked_by_blacksmith',
              settleMs: 900);
          await _dismissBarrierDialog(tester);
          // ignore: avoid_print
          print(
              'INFO: theme editor requires the Blacksmith purchase - editor shots skipped');
        } else {
          // ignore: avoid_print
          print('WARN: neither theme editor nor support dialog appeared');
        }
      }
      _popInTab(Tabs.Settings);
      await _pump(tester, 1000);

      // Data Management - list only, nothing is tapped inside
      _pushInTab(Tabs.Settings, SettingsTabRoutingKeys.DataManagement.route);
      await _shot(tester, '27_settings_data_management', settleMs: 2200);
      _popInTab(Tabs.Settings);
      await _pump(tester, 1000);

      // Logs + one log detail
      _pushInTab(Tabs.Settings, SettingsTabRoutingKeys.Logs.route);
      await _shot(tester, '28_settings_logs', settleMs: 2200);
      if (find.byType(LogTile).evaluate().isNotEmpty) {
        await _tryTap(tester, find.byType(LogTile),
            warnOnMissing: 'first log tile');
        await _shot(tester, '29_settings_log_detail', settleMs: 1400);
        _popInTab(Tabs.Settings);
        await _pump(tester, 900);
      } else {
        // ignore: avoid_print
        print('INFO: no log entries - log detail shot skipped');
      }
      _popInTab(Tabs.Settings);
      await _pump(tester, 1000);

      // About + Credits (license modal)
      _pushInTab(Tabs.Settings, SettingsTabRoutingKeys.About.route);
      await _shot(tester, '30_settings_about', settleMs: 2200);
      final bool creditsTapped = await _scrollUntilHittable(
            tester,
            find.text('Credits'),
            within: find.byType(AboutView),
          ) &&
          await _tryTap(
            tester,
            find.text('Credits'),
            warnOnMissing: 'Credits button',
          );
      if (creditsTapped) {
        await _shot(tester, '31_settings_about_credits', settleMs: 1800);
        await _dismissBarrierDialog(tester);
      }
      _popInTab(Tabs.Settings);
      await _pump(tester, 1000);

      // FAQ
      _pushInTab(Tabs.Settings, SettingsTabRoutingKeys.FAQ.route);
      await _shot(tester, '32_settings_faq', settleMs: 2200);
      _popInTab(Tabs.Settings);
      await _pump(tester, 1000);

      // Privacy Policy
      _pushInTab(Tabs.Settings, SettingsTabRoutingKeys.PrivacyPolicy.route);
      await _shot(tester, '33_settings_privacy_policy', settleMs: 2200);
      _popInTab(Tabs.Settings);
      await _pump(tester, 1200);

      // Support dialog (Tip Jar) - open, capture, dismiss. NO purchase.
      if (settingsScroll != null && settingsScroll.hasClients) {
        await _jumpTo(
            tester, settingsScroll, settingsScroll.position.maxScrollExtent);
      }
      final bool tipJarTapped = await _tryTap(
        tester,
        find.text('Tip Jar'),
        warnOnMissing: 'Tip Jar entry',
      );
      if (tipJarTapped) {
        await _shot(tester, '34_settings_support_dialog', settleMs: 2500);
        await _dismissBarrierDialog(tester);
      }
      await _jumpTo(tester, settingsScroll, 0.0);

      // ============================ INTRO ===========================
      // ignore: avoid_print
      print('=== SECTION: intro ===');
      // Same call the "Intro Slides" settings entry makes (rootNavigation).
      // The route change can take a moment to become visible, so every step
      // below is gated on its expected finder instead of fixed delays.
      final BuildContext settingsContext =
          tester.element(find.byType(SettingsView).first);
      Navigator.of(settingsContext, rootNavigator: true)
          .pushReplacementNamed(AppRoutingKeys.Intro.route);
      await _waitFor(tester, find.byType(IntroView), timeoutMs: 15000);
      await _waitFor(tester, find.text('Start'), timeoutMs: 10000);
      await _shot(tester, '40_intro_welcome', settleMs: 1500);

      await _tryTap(tester, find.text('Start'),
          warnOnMissing: 'intro Start button');
      // Unified slides: first two are WS setup (locked 5s for first-time),
      // then a light app tour. Poll for the unlocked Next / Start button.
      await _waitFor(tester, find.text('Getting Started'), timeoutMs: 10000);
      await _waitFor(tester, find.text('Next'));
      await _shot(tester, '41_intro_ws_setup_1', settleMs: 400);
      await _tryTap(tester, find.text('Next'),
          warnOnMissing: 'slide 1 Next');
      await _pump(tester, 900);
      await _waitFor(tester, find.text('Next'));
      await _shot(tester, '42_intro_ws_setup_2', settleMs: 400);
      await _tryTap(tester, find.text('Next'),
          warnOnMissing: 'slide 2 Next');
      await _pump(tester, 900);
      await _waitFor(tester, find.text('Next'));
      await _shot(tester, '43_intro_tour_home', settleMs: 400);
      await _tryTap(tester, find.text('Next'),
          warnOnMissing: 'slide 3 Next');
      await _pump(tester, 600);
      await _waitFor(tester, find.text('Next'));
      await _shot(tester, '44_intro_tour_dashboard', settleMs: 400);
      await _tryTap(tester, find.text('Next'),
          warnOnMissing: 'slide 4 Next');
      await _pump(tester, 600);
      // Last slide: the primary button reads "Start"
      await _waitFor(tester, find.text('Start'));
      await _shot(tester, '45_intro_tour_ready', settleMs: 400);

      // Leave the intro WITHOUT tapping the final "Start" (it would persist
      // HasUserSeenIntro202208). Route replacement mirrors the entry path.
      final BuildContext introContext =
          tester.element(find.byType(IntroView).first);
      Navigator.of(introContext, rootNavigator: true)
          .pushReplacementNamed(AppRoutingKeys.Tabs.route);
      await _waitFor(tester, find.byType(CupertinoTabBar), timeoutMs: 30000);
      await _pump(tester, 1500);

      // ========================== DASHBOARD =========================
      // ignore: avoid_print
      print('=== SECTION: dashboard ===');
      _switchTab(Tabs.Home);
      await _pump(tester, 1500);

      GetIt.instance<HomeStore>().setConnectMode(ConnectMode.Manual);
      await _waitFor(tester, find.byType(ConnectForm), timeoutMs: 20000);
      await _pump(tester, 1000);

      bool dashboardReached = false;
      final Finder formFields = find.descendant(
        of: find.byType(ConnectForm),
        matching: find.byType(TextFormField),
      );
      if (formFields.evaluate().length < 3) {
        // ignore: avoid_print
        print(
            'ERROR: connect form fields not found (${formFields.evaluate().length}) - dashboard section degraded');
        await _shot(tester, '50_connect_form_error', settleMs: 500);
      } else {
        await tester.enterText(formFields.at(0), '127.0.0.1');
        await _pump(tester, 400);
        await tester.enterText(formFields.at(1), '4455');
        await _pump(tester, 400);
        if (kObsWsPassword.isNotEmpty) {
          await tester.enterText(formFields.at(2), kObsWsPassword);
          await _pump(tester, 400);
        }
        FocusManager.instance.primaryFocus?.unfocus();
        await _pump(tester, 900);

        final Finder connectButton = find.descendant(
          of: find.byType(ConnectForm),
          matching: find.text('Connect'),
        );
        if (await _tryTap(tester, connectButton,
            settleMs: 200, warnOnMissing: 'Connect button')) {
          // Best effort: the "Connecting..." overlay is short-lived on a
          // local connection; the wrapper grabs whatever is on screen.
          final Completer<void> ack = Completer<void>();
          _shotAcks['50_connecting_overlay'] = ack;
          // ignore: avoid_print
          print('SHOT: 50_connecting_overlay');
          await ack.future.timeout(const Duration(seconds: 5),
              onTimeout: () {});
          _shotAcks.remove('50_connecting_overlay');
        }

        // Wait for the dashboard route (or an error overlay)
        for (int i = 0; i < 12 && !dashboardReached; i++) {
          await _pump(tester, 1000);
          dashboardReached = find.byType(DashboardView).evaluate().isNotEmpty;
        }
      }

      if (!dashboardReached) {
        // ignore: avoid_print
        print('ERROR: dashboard not reached - capturing error state');
        await _shot(tester, '51_connect_error_state', settleMs: 400);
      } else {
        // "Save Connection" dialog (unnamed manual connection) - dismissed
        // with "No", nothing is saved.
        for (int i = 0; i < 6; i++) {
          if (find.text('Save Connection').evaluate().isNotEmpty) break;
          await _pump(tester, 800);
        }
        if (find.text('Save Connection').evaluate().isNotEmpty) {
          await _shot(tester, '51_dashboard_save_connection_dialog',
              settleMs: 600);
          await _tryTap(tester, find.text('No'),
              warnOnMissing: 'Save Connection No');
          await _pump(tester, 1000);
        }

        await _shot(tester, '52_dashboard_main', settleMs: 3500);

        final ScrollController? dashScroll =
            _routeScrollController(tester, find.byType(DashboardView));

        // Scene items area: bring the tab bar into view, then frame the
        // scene item list itself
        await _scrollUntilHittable(tester, find.widgetWithText(Tab, 'Scene Items'),
            within: find.byType(DashboardView));
        await _nudge(tester, dashScroll, 320.0);
        await _shot(tester, '53_dashboard_scene_items', settleMs: 500);

        // Audio mixer: back up so the tab bar is tappable, select Audio,
        // then frame the mixer
        await _nudge(tester, dashScroll, -320.0);
        await _tryTap(tester, find.widgetWithText(Tab, 'Audio'),
            warnOnMissing: 'Audio tab');
        await _nudge(tester, dashScroll, 320.0);
        await _shot(tester, '54_dashboard_audio_mixer', settleMs: 900);

        // Widgets section - Chat (default) then Stats
        await _scrollUntilHittable(tester, find.widgetWithText(Tab, 'Chat'),
            within: find.byType(DashboardView));
        await _nudge(tester, dashScroll, 80.0);
        await _shot(tester, '55_dashboard_widgets_chat', settleMs: 1800);
        await _tryTap(tester, find.widgetWithText(Tab, 'Stats'),
            warnOnMissing: 'Stats tab');
        await _nudge(tester, dashScroll, 340.0);
        await _shot(tester, '56_dashboard_widgets_stats', settleMs: 1800);

        // Back to the top, open the status app bar actions menu
        await _jumpTo(tester, dashScroll, 0.0);
        await _tryTap(tester, find.byIcon(CupertinoIcons.ellipsis),
            warnOnMissing: 'dashboard actions menu');
        await _shot(tester, '57_dashboard_actions_menu', settleMs: 900);
        await _tryTap(tester, find.text('Cancel'),
            warnOnMissing: 'action sheet Cancel');
        await _pump(tester, 800);

        // Scene preview: the "Current OBS scene preview" expansion tile is
        // shown by default. Expanding it starts the preview image requests
        // (in-memory only). First expansion surfaces a warning dialog whose
        // "Ok" writes DontShowPreviewWarning=false if left unchecked - that
        // key is restored in the integrity phase below.
        final bool previewTileTapped = await _scrollUntilHittable(
              tester,
              find.text('Current OBS scene preview'),
              within: find.byType(DashboardView),
            ) &&
            await _tryTap(
              tester,
              find.text('Current OBS scene preview'),
              warnOnMissing: 'scene preview expansion tile',
            );
        if (previewTileTapped) {
          if (find.text('Warning on scene preview').evaluate().isNotEmpty) {
            await _shot(tester, '58_dashboard_preview_warning', settleMs: 700);
            await _tryTap(tester, find.text('Ok'),
                warnOnMissing: 'preview warning Ok');
            await _pump(tester, 800);
          }
          // Preview images tick in once per second
          final DashboardStore dashboardStore =
              GetIt.instance<DashboardStore>();
          for (int i = 0;
              i < 10 && dashboardStore.scenePreviewImageBytes == null;
              i++) {
            await _pump(tester, 1000);
          }
          await _shot(tester, '59_dashboard_preview_expanded', settleMs: 1200);

          if (dashboardStore.scenePreviewImageBytes != null &&
              find.byType(ScenePreview).evaluate().isNotEmpty) {
            // The fullscreen button sits at the bottom edge of the preview -
            // make sure the whole preview clears the tab bar, otherwise the
            // tap lands on a tab bar item instead (and switches tabs!)
            for (int i = 0; i < 6; i++) {
              final Rect previewRect =
                  tester.getRect(find.byType(ScenePreview));
              if (previewRect.bottom < 770.0) break;
              if (dashScroll != null && dashScroll.hasClients) {
                dashScroll.jumpTo(dashScroll.offset + 140.0);
                await _pump(tester, 400);
              } else {
                break;
              }
            }
            // First tap on the image only reveals the overlay UI; the
            // fullscreen button auto-hides after 3s, so tap it promptly.
            await _tryTap(
              tester,
              find.descendant(
                of: find.byType(ScenePreview),
                matching: find.byType(Image),
              ),
              settleMs: 600,
              warnOnMissing: 'scene preview image',
            );
            await _tryTap(
              tester,
              find.byIcon(CupertinoIcons.fullscreen),
              settleMs: 1500,
              warnOnMissing: 'scene preview fullscreen button',
            );
            // The fullscreen route has its own close button (top right) -
            // its presence proves the route opened and closes it cleanly.
            if (find.byIcon(CupertinoIcons.clear).evaluate().isNotEmpty) {
              await _shot(tester, '60_dashboard_preview_fullscreen',
                  settleMs: 700);
              await _tryTap(
                tester,
                find.byIcon(CupertinoIcons.clear),
                warnOnMissing: 'fullscreen close button',
              );
              await _pump(tester, 1000);
            } else {
              // ignore: avoid_print
              print('INFO: scene preview fullscreen did not open');
            }
          }
        } else {
          // ignore: avoid_print
          print('INFO: scene preview tile not found - preview shots skipped');
        }
      }

      // ---- Leave the dashboard as found: not connected ----
      if (dashboardReached) {
        _switchTab(Tabs.Home);
        await _pump(tester, 1000);
        final ScrollController? dashScroll =
            _routeScrollController(tester, find.byType(DashboardView));
        await _jumpTo(tester, dashScroll, 0.0);
        await _tryTap(tester, find.text('Close'),
            warnOnMissing: 'dashboard Close');
        await _pump(tester, 600);
        // Confirmation: closing the websocket session is the normal flow and
        // restores the "not connected" state the app started in.
        await _tryTap(tester, find.text('Yes'),
            warnOnMissing: 'Close Connection Yes');
        await _pump(tester, 3000);
        await _shot(tester, '61_home_after_disconnect', settleMs: 1200);
      }

      // ===================== INTEGRITY CHECK ========================
      // The scene preview warning writes DontShowPreviewWarning (false when
      // left unchecked). If the key did not exist before the walk, remove it
      // again so the container is byte-identical to how we found it.
      if (!hadPreviewWarningKey &&
          settingsBox.containsKey(SettingsKeys.DontShowPreviewWarning.name) &&
          settingsBox.get(SettingsKeys.DontShowPreviewWarning.name) == false) {
        settingsBox.delete(SettingsKeys.DontShowPreviewWarning.name);
        // ignore: avoid_print
        print('STATE-INFO: removed newly written DontShowPreviewWarning key');
      }
      final Map<dynamic, dynamic> settingsAfter =
          Map<dynamic, dynamic>.from(settingsBox.toMap());
      final List<String> diffs = [];
      final Set<dynamic> allKeys = {
        ...settingsSnapshot.keys,
        ...settingsAfter.keys
      };
      for (final dynamic key in allKeys) {
        final String before = '${settingsSnapshot[key]}';
        final String after = '${settingsAfter[key]}';
        if (before != after) {
          diffs.add('$key: "$before" -> "$after"');
        }
      }
      final int savedConnectionsAfter =
          Hive.box<Connection>(HiveKeys.SavedConnections.name).length;
      final int customThemesAfter =
          Hive.box<CustomTheme>(HiveKeys.CustomTheme.name).length;
      if (savedConnectionsAfter != savedConnectionsCount) {
        diffs.add(
            'SavedConnections count: $savedConnectionsCount -> $savedConnectionsAfter');
      }
      if (customThemesAfter != customThemeCount) {
        diffs.add('CustomTheme count: $customThemeCount -> $customThemesAfter');
      }
      // ignore: avoid_print
      print(diffs.isEmpty
          ? 'STATE-CHECK: OK (no settings/connection/theme changes)'
          : 'STATE-CHECK: DIFFS -> ${diffs.join(' | ')}');
      // ignore: avoid_print
      print('WALK COMPLETE');
      await ackServer.close(force: true);
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
