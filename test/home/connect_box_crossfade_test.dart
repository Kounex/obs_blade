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

  testWidgets(
    'pane/title crossfade is sequential (outgoing fully fades out before '
    'the incoming one fades in) instead of a simultaneous cross-dissolve',
    (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump(const Duration(seconds: 1));

      final HomeStore homeStore = GetIt.instance<HomeStore>();
      homeStore.setConnectMode(ConnectMode.Manual);

      /// FadeTransitions whose direct child carries a connect-mode key -
      /// scopes past unrelated fades elsewhere in the tree (e.g. the
      /// autodiscover spinner's own Fader) the same way the key-collision
      /// test above scopes its KeyedSubtree/Align search.
      List<double> fadesOfType(Type childType) => tester
          .widgetList<FadeTransition>(find.byType(FadeTransition))
          .where(
            (f) =>
                f.child.runtimeType == childType &&
                (f.child as dynamic).key.toString().contains('ConnectMode'),
          )
          .map((f) => f.opacity.value)
          .toList();

      bool atMostOneVisible(List<double> opacities) =>
          opacities.where((o) => o > 0.05).length <= 1;

      // AppMotion.medium is 250ms; sample every 16ms through the whole
      // transition.
      var elapsedMs = 0;
      for (var i = 0; i < 16; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        elapsedMs += 16;
        final paneFades = fadesOfType(KeyedSubtree);
        final titleFades = fadesOfType(Align);
        expect(
          atMostOneVisible(paneFades),
          isTrue,
          reason:
              't=${elapsedMs}ms: both connect-mode panes visible at once: $paneFades',
        );
        expect(
          atMostOneVisible(titleFades),
          isTrue,
          reason:
              't=${elapsedMs}ms: both connect-mode titles visible at once: $titleFades',
        );
      }

      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    },
  );
}
