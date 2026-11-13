import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/views/settings/settings.dart';

import 'support/shots_harness.dart';

/// Settings -> Theme -> Bars & Sheets (Glass / Clear / Solid): the settings
/// row at phone / narrow / tablet, and the top bar + tab bar + a sheet over
/// busy content in each style (issue #106)
void main() {
  final harness = ShotsHarness();

  setUpAll(ShotsHarness.loadFonts);
  setUp(harness.setUp);
  tearDown(harness.tearDown);

  Future<void> useStyle(WidgetTester tester, SurfaceStyle style) =>
      tester.runAsync(
        () => Hive.box(
          HiveKeys.Settings.name,
        ).put(SettingsKeys.SurfaceStyle.name, style.name),
      );

  /// Colorful rows so the blur / see-through difference shows
  Widget busyContent() => ListView(
    padding: const EdgeInsets.only(top: 40, bottom: 120),
    children: [
      for (var i = 0; i < 16; i++)
        Container(
          height: 56,
          color: Colors.primaries[i % Colors.primaries.length].shade700,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Scene ${i + 1} - Camera, Game Capture, Overlay',
            style: const TextStyle(color: Colors.white, fontSize: 17),
          ),
        ),
    ],
  );

  Widget bars() => Builder(
    builder: (context) => Stack(
      children: [
        Positioned.fill(child: busyContent()),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GlassBar(
            child: SizedBox(
              height: GlassBar.minContentHeight + 20,
              child: Center(
                child: Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: GlassBar(
            contentEdge: GlassBarEdge.top,
            color: CupertinoTheme.of(context).barBackgroundColor,
            child: GlassCupertinoTabBar(
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.chart_bar_alt_fill),
                  label: 'Statistics',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.settings),
                  label: 'Settings',
                ),
              ],
              activeColor: Theme.of(
                context,
              ).extension<AppTextColors>()!.accentText,
            ),
          ),
        ),
      ],
    ),
  );

  Widget sheetOverContent() => Builder(
    builder: (context) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          ModalHandler.showBaseBottomSheet(
            context: context,
            builder: (_) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Audio Settings\n\nA sheet over the dashboard - the rows '
                'behind it show through in Glass and Clear.',
              ),
            ),
          );
        }
      });
      return busyContent();
    },
  );

  for (final style in SurfaceStyle.values) {
    testWidgets('bars + sheet: ${style.name}', (tester) async {
      await useStyle(tester, style);
      for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
        debugDefaultTargetPlatformOverride = platform;
        try {
          await harness.shot(
            tester,
            'surface_bars_${style.name}_${platform.name}',
            bars(),
          );
          await harness.shot(
            tester,
            'surface_sheet_${style.name}_${platform.name}',
            sheetOverContent(),
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      }
    });
  }

  testWidgets('settings row', (tester) async {
    await useStyle(tester, SurfaceStyle.clear);
    for (final (tag, size) in [
      ('phone', const Size(390, 1700)),
      ('narrow', const Size(320, 1800)),
      ('tablet', const Size(1180, 1500)),
    ]) {
      await harness.shot(
        tester,
        'surface_settings_$tag',
        const SettingsView(),
        size: size,
      );
    }
  });
}
