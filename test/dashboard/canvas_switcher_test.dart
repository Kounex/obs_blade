import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/canvas_view.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/obs_canvas.dart';
import 'package:obs_blade/types/classes/api/scene.dart';
import 'package:obs_blade/types/classes/api/scene_item.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/canvas/canvas_picker.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_buttons/scene_buttons.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/scene_items/scene_items.dart';

import '../persistence/support/hive_test_harness.dart';

const ObsCanvas _main = ObsCanvas(
  uuid: 'main',
  name: 'Main',
  isMain: true,
  baseWidth: 1920,
  baseHeight: 1080,
);
const ObsCanvas _vertical = ObsCanvas(
  uuid: 'vertical',
  name: 'Vertical',
  isMain: false,
  baseWidth: 1080,
  baseHeight: 1920,
);

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

/// The dashboard follows [CanvasViewStore]: picker only with more than one
/// canvas (and the setting on), scene buttons / items of the viewed canvas
/// instead of the program ones.
void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late DashboardStore dashboardStore;
  late CanvasViewStore canvasStore;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('canvas_switcher');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    dashboardStore = DashboardStore();
    canvasStore = CanvasViewStore();
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);
    GetIt.instance.registerSingleton<NetworkStore>(NetworkStore());
    GetIt.instance.registerSingleton<CanvasViewStore>(canvasStore);
    runInAction(() {
      dashboardStore.scenes = ObservableList.of([
        const Scene(sceneName: 'Program Scene', sceneIndex: 0),
      ]);
      dashboardStore.currentSceneItems = ObservableList.of([
        _item(9, 'program-cam'),
      ]);
    });
  });

  tearDown(() async {
    canvasStore.dispose();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Widget app(Widget child) => MaterialApp(
    theme: ThemeData(
      brightness: Brightness.dark,
      cupertinoOverrideTheme: const CupertinoThemeData(),
      extensions: const [AppStatusColors.standard, AppTextColors.standard],
    ),
    onGenerateRoute: (settings) => MaterialPageRoute(
      settings: RouteSettings(arguments: ScrollController()),
      builder: (_) => Scaffold(body: child),
    ),
  );

  /// No session in widget tests: the store's reads return nothing, the
  /// test fills in what OBS would have answered
  Future<void> viewVertical(WidgetTester tester) async {
    runInAction(() {
      canvasStore.canvases = ObservableList.of([_main, _vertical]);
    });
    canvasStore.viewCanvas(_vertical.uuid);
    await tester.pump();
    runInAction(() {
      canvasStore.scenes = ObservableList.of(const [
        CanvasScene(uuid: 'v-main', name: 'Vertical Main'),
        CanvasScene(uuid: 'v-brb', name: 'Vertical BRB'),
      ]);
      canvasStore.selectedSceneUuid = 'v-main';
      canvasStore.sceneItems = ObservableList.of([_item(1, 'vertical-cam')]);
    });
  }

  testWidgets('picker hides with a single canvas', (tester) async {
    runInAction(() => canvasStore.canvases = ObservableList.of([_main]));
    await tester.pumpWidget(app(const CanvasPicker()));
    await tester.pump();

    expect(find.text('Canvas'), findsNothing);
  });

  testWidgets('picker shows with two canvases, hides when switched off in '
      'settings', (tester) async {
    runInAction(
      () => canvasStore.canvases = ObservableList.of([_main, _vertical]),
    );
    await tester.pumpWidget(app(const CanvasPicker()));
    await tester.pump();

    expect(find.text('Canvas'), findsOneWidget);
    expect(find.text('Main · 1920×1080'), findsOneWidget);

    await tester.runAsync(
      () => Hive.box(
        HiveKeys.Settings.name,
      ).put(SettingsKeys.ExposeCanvasSwitcher.name, false),
    );
    await tester.pump();
    expect(find.text('Canvas'), findsNothing);
  });

  testWidgets('scene buttons show the viewed canvas, a tap only picks the '
      'scene to view', (tester) async {
    await tester.pumpWidget(app(const SceneButtons()));
    await tester.pump();
    expect(find.text('Program Scene'), findsOneWidget);

    await viewVertical(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Program Scene'), findsNothing);
    expect(find.text('Vertical Main'), findsOneWidget);
    expect(find.text('Vertical BRB'), findsOneWidget);

    await tester.tap(find.text('Vertical BRB'));
    await tester.pump();
    expect(canvasStore.selectedSceneUuid, 'v-brb');

    /// Back to main: the program scenes return
    canvasStore.viewCanvas(null);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Program Scene'), findsOneWidget);
  });

  testWidgets('scene items show the picked canvas scene', (tester) async {
    await tester.pumpWidget(app(const SceneItems()));
    await tester.pump();
    expect(find.text('program-cam'), findsOneWidget);

    await viewVertical(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('program-cam'), findsNothing);
    expect(find.text('vertical-cam'), findsOneWidget);
    expect(find.text('Vertical Main · Vertical canvas'), findsOneWidget);

    /// Stops the periodic re-read before the fake clock checks for timers
    canvasStore.viewCanvas(null);
    await tester.pump();
  });
}
