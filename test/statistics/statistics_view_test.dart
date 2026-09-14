import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:obs_blade/models/past_stream_data.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/views/statistics.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/statistics/statistics.dart';
import 'package:obs_blade/views/statistics/widgets/card_header/sort_filter_panel/filter_duration.dart';

import '../persistence/support/hive_test_harness.dart';

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  PastStreamData streamData(String name, int dateMS, int totalTimeS) =>
      PastStreamData()
        ..name = name
        ..totalTime = totalTimeS
        ..listEntryDateMS = [dateMS];

  /// The statistics route carries the tab's ScrollController as its route
  /// arguments (TabBase does this in real runs). labelSmall is shrunk because
  /// the Ahem test font's square glyphs overflow the fixed-width date chips.
  Widget wrap() => MaterialApp(
    theme: ThemeData(
      brightness: Brightness.dark,
      cupertinoOverrideTheme: const CupertinoThemeData(),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
      buttonTheme: ButtonThemeData(
        colorScheme: ColorScheme.fromSwatch(accentColor: Colors.redAccent),
      ),
      textTheme: ThemeData.dark().textTheme.copyWith(
        labelSmall: const TextStyle(fontSize: 8.0),
      ),
      extensions: const [AppStatusColors.standard, AppTextColors.standard],
    ),
    onGenerateRoute: (routeSettings) => MaterialPageRoute(
      builder: (_) => const StatisticsView(),
      settings: RouteSettings(name: '/', arguments: ScrollController()),
    ),
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('statistics_view_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();

    /// StatsEntry renders dates via intl DateFormat (initialized in
    /// main.dart in real runs)
    await initializeDateFormatting();

    GetIt.instance.registerLazySingleton<StatisticsStore>(
      () => StatisticsStore(),
    );

    /// Seeded here (real async) - Hive writes inside testWidgets' fake-async
    /// zone never complete
    final box = Hive.box<PastStreamData>(HiveKeys.PastStreamData.name);
    await box.add(streamData('alpha run', 1000, 100));
    await box.add(streamData('beta run', 2000, 200));
    await box.add(streamData('gamma run', 3000, 300));
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('active filters survive a detail navigation roundtrip', (
    tester,
  ) async {
    /// Phone-sized surface (default test window is too wide/short and
    /// overflows the stats entry date chip)
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    GetIt.instance<StatisticsStore>().setFilterName('alpha');
    await tester.pumpAndSettle();

    expect(find.text('alpha run'), findsOneWidget);
    expect(find.text('beta run'), findsNothing);

    /// Tapping an entry pushes the detail route on top; losing isCurrent
    /// rebuilds this view (ModalRoute.of dependency in build) and must not
    /// wipe the active filters
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute(builder: (_) => const Scaffold(body: Text('detail'))),
    );
    await tester.pumpAndSettle();

    expect(GetIt.instance<StatisticsStore>().filterName, 'alpha');

    navigator.pop();
    await tester.pumpAndSettle();

    expect(GetIt.instance<StatisticsStore>().filterName, 'alpha');
    expect(find.text('alpha run'), findsOneWidget);
    expect(find.text('beta run'), findsNothing);
  });

  test('duration filter exposes only implemented options', () {
    expect(DurationFilter.values.map((filter) => filter.name), [
      'Shorter',
      'Longer',
    ]);
    expect(kActiveDurationFilters.length, 3);
  });
}
