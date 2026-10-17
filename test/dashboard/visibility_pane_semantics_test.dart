import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/scene_item.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/scene_items/scene_items.dart';

import '../persistence/support/hive_test_harness.dart';

SceneItem _item(int id, String sourceName) => SceneItem(
  inputKind: 'image_source',
  isGroup: false,
  sceneItemBlendMode: null,
  sceneItemEnabled: true,
  sceneItemId: id,
  sceneItemIndex: id,
  sceneItemLocked: false,
  sceneItemTransform: null,
  sourceName: sourceName,
  sourceType: 'OBS_SOURCE_TYPE_INPUT',
);

/// The Edit Visibility pill is one control: a screen reader names the row,
/// its state and what a tap does (the pill text alone read "Visible,
/// button" on every row)
void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late DashboardStore dashboardStore;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('visibility_semantics');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    dashboardStore = DashboardStore();
    GetIt.instance.registerSingleton<NetworkStore>(NetworkStore());
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);
  });

  tearDown(() async {
    runInAction(() => dashboardStore.editSceneItemVisibility = false);
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('the pane names the row, its state and the tap', (tester) async {
    final semantics = tester.ensureSemantics();
    runInAction(() {
      dashboardStore.activeSceneName = 'Main';
      dashboardStore.sceneItemsSceneName = 'Main';
      dashboardStore.currentSceneItems = ObservableList.of([
        _item(1, 'Camera'),
      ]);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          cupertinoOverrideTheme: const CupertinoThemeData(),
          extensions: const [AppStatusColors.standard, AppTextColors.standard],
        ),
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: RouteSettings(arguments: ScrollController()),
          builder: (_) =>
              const Scaffold(body: SizedBox(height: 400, child: SceneItems())),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    /// The pane opens on the false -> true change after the first build
    runInAction(() => dashboardStore.editSceneItemVisibility = true);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final pane = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where(
          (widget) => widget.properties.label == 'Camera, visible in OBS Blade',
        );
    expect(pane, hasLength(1));
    expect(pane.single.properties.hint, 'Hides it from the dashboard');
    expect(pane.single.properties.toggled, isTrue);
    expect(pane.single.properties.button, isTrue);
    expect(pane.single.excludeSemantics, isTrue);

    semantics.dispose();
  });
}
