import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/home.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/home/widgets/connect_box/connect_box.dart';

import '../persistence/support/hive_test_harness.dart';

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  Widget wrap() => MaterialApp(
    theme: ThemeData(
      cupertinoOverrideTheme: const CupertinoThemeData(),
      extensions: const [AppStatusColors.standard, AppTextColors.standard],
    ),
    home: const Scaffold(body: SingleChildScrollView(child: ConnectBox())),
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('connect_box_crossfade');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);

    GetIt.instance.registerLazySingleton<NetworkStore>(() => NetworkStore());
    GetIt.instance.registerLazySingleton<HomeStore>(() => HomeStore());
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets(
    'rapid mode switches never leave two panes sharing a key (AnimatedSwitcher '
    'would otherwise render an outgoing and incoming pane of the same mode '
    'on top of each other instead of a clean crossfade)',
    (tester) async {
      await tester.pumpWidget(wrap());
      // Bounded pump: the "Searching..." spinner shown while autodiscovery
      // has no result yet animates forever, so pumpAndSettle would time out.
      await tester.pump(const Duration(seconds: 1));

      final HomeStore homeStore = GetIt.instance<HomeStore>();

      // Switch through all three modes and back, each step faster than the
      // pane crossfade duration, so an outgoing pane is still animating out
      // when the next (or a revisited) mode's pane comes in.
      for (final mode in [
        ConnectMode.Manual,
        ConnectMode.QR,
        ConnectMode.Autodiscover,
        ConnectMode.Manual,
      ]) {
        homeStore.setConnectMode(mode);
        await tester.pump(const Duration(milliseconds: 60));
      }

      // Checked per AnimatedSwitcher (its own KeyedSubtree/Align child),
      // since uniqueness only matters among siblings under the same parent -
      // the pane key and the title key are allowed to equal each other, and
      // CupertinoSlidingSegmentedControl has its own unrelated internal keys
      // in this same tree.
      List<Key?> connectModeKeysOf<T extends Widget>() => tester
          .widgetList<T>(find.byType(T))
          .map((widget) => (widget as dynamic).key as Key?)
          .where((key) => key != null && key.toString().contains('ConnectMode'))
          .toList();

      final paneKeys = connectModeKeysOf<KeyedSubtree>();
      final titleKeys = connectModeKeysOf<Align>();

      expect(paneKeys, isNotEmpty);
      expect(
        paneKeys.toSet().length,
        paneKeys.length,
        reason:
            'two connect-mode panes are sharing an AnimatedSwitcher key: $paneKeys',
      );
      expect(titleKeys, isNotEmpty);
      expect(
        titleKeys.toSet().length,
        titleKeys.length,
        reason:
            'two connect-mode titles are sharing an AnimatedSwitcher key: $titleKeys',
      );

      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    },
  );
}
