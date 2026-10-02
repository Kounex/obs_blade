import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/base/divider.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/canvas_view.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/aitum_vertical.dart';
import 'package:obs_blade/types/classes/api/obs_canvas.dart';
import 'package:obs_blade/types/classes/api/scene.dart';
import 'package:obs_blade/types/classes/api/scene_item.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/canvas/canvas_output_controls.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/canvas/canvas_picker.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_buttons/scene_buttons.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/scene_items/scene_items.dart';
import 'package:obs_blade/views/dashboard/widgets/status_app_bar/on_air_status_cluster.dart';

import 'support/shots_harness.dart';

/// Canvas view states (picker, outputs card, scene buttons, items, the app
/// bar's extra-canvas pill) - the template for a feature's shot spec: fill
/// the stores the way OBS would, then shoot each state a user can reach.
void main() {
  final harness = ShotsHarness();
  late DashboardStore dashboardStore;
  late CanvasViewStore canvasStore;

  setUpAll(ShotsHarness.loadFonts);

  setUp(() async {
    await harness.setUp();
    dashboardStore = DashboardStore();
    canvasStore = CanvasViewStore();
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);
    GetIt.instance.registerSingleton<NetworkStore>(NetworkStore());
    GetIt.instance.registerSingleton<CanvasViewStore>(canvasStore);
  });

  tearDown(() async {
    runInAction(() => dashboardStore.editSceneVisibility = false);
    canvasStore.dispose();
    await GetIt.instance.reset();
    await harness.tearDown();
  });

  const main = ObsCanvas(
    uuid: 'main',
    name: 'Main',
    isMain: true,
    baseWidth: 1920,
    baseHeight: 1080,
  );
  const aitum = ObsCanvas(
    uuid: 'aitum',
    name: kAitumCanvasName,
    isMain: false,
    baseWidth: 1080,
    baseHeight: 1920,
  );
  const aitumLandscape = ObsCanvas(
    uuid: 'aitum',
    name: kAitumCanvasName,
    isMain: false,
    baseWidth: 1920,
    baseHeight: 1080,
  );
  const otherPlugin = ObsCanvas(
    uuid: 'other',
    name: 'Vertical',
    isMain: false,
    baseWidth: 1080,
    baseHeight: 1920,
  );

  SceneItem item(int id, String name, {String? group, bool isGroup = false}) =>
      SceneItem(
        inputKind: 'image_source',
        isGroup: isGroup,
        sceneItemBlendMode: null,
        sceneItemEnabled: true,
        sceneItemId: id,
        sceneItemIndex: id,
        sceneItemLocked: false,
        sceneItemTransform: null,
        sourceName: name,
        sourceType: 'OBS_SOURCE_TYPE_INPUT',
        parentGroupName: group,
      );

  /// What OBS (+ Aitum) would have told the stores
  void state(
    ObsCanvas canvas, {
    required bool viewed,
    bool mainLive = true,
    bool dualFormat = false,
    AitumSupport support = AitumSupport.available,
    AitumOutputStatus status = const AitumOutputStatus(),
  }) => runInAction(() {
    dashboardStore.isLive = mainLive;
    dashboardStore.latestStreamTimeDurationMS = mainLive ? 3725000 : 0;
    dashboardStore.scenes = ObservableList.of(const [
      Scene(sceneName: 'Main', sceneIndex: 0),
      Scene(sceneName: 'BRB', sceneIndex: 1),
    ]);
    canvasStore.canvases = ObservableList.of([main, canvas]);
    canvasStore.viewedCanvasUuid = viewed ? canvas.uuid : null;
    canvasStore.scenes = ObservableList.of(const [
      CanvasScene(uuid: 'v1', name: 'Vertical Main'),
      CanvasScene(uuid: 'v2', name: 'Vertical Chat'),
      CanvasScene(uuid: 'v3', name: 'BRB'),
    ]);
    canvasStore.selectedSceneUuid = 'v1';
    canvasStore.aitumSupport = support;
    canvasStore.aitumLiveSceneName = 'Vertical Main';
    canvasStore.aitumStatus = status;
    canvasStore.dualFormatCanvasUuid = dualFormat ? canvas.uuid : null;
    canvasStore.sceneItems = ObservableList.of([
      item(5, 'Overlay Group', isGroup: true),
      item(1, 'Alert box', group: 'Overlay Group'),
      item(2, 'Ticker', group: 'Overlay Group'),
      item(3, 'Camera'),
    ]);
    canvasStore.expandedGroups = ObservableSet.of({'Overlay Group'});
  });

  /// The dashboard's top: status row, canvas picker, outputs, scene buttons
  Widget dashboardTop({bool items = false}) => ListView(
    children: [
      const BaseDivider(),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: OnAirStatusCluster(),
      ),
      const SizedBox(height: AppSpacing.md),
      if (items)
        const SizedBox(height: 360, child: SceneItems())
      else ...const [
        CanvasPicker(),
        CanvasOutputControls(),
        Padding(
          padding: EdgeInsets.only(
            top: AppSpacing.xxl,
            left: AppSpacing.md,
            right: AppSpacing.md,
          ),
          child: SceneButtons(),
        ),
      ],
    ],
  );

  testWidgets('main view, Dual Format live', (tester) async {
    state(aitum, viewed: false, dualFormat: true);
    await harness.shot(tester, 'canvas_main_dual_format', dashboardTop());
  });

  testWidgets('Aitum canvas: live control, recording paused', (tester) async {
    state(
      aitum,
      viewed: true,
      status: const AitumOutputStatus(
        streaming: true,
        recording: true,
        recordingPaused: true,
      ),
    );
    await harness.shot(tester, 'canvas_aitum_live', dashboardTop());
  });

  testWidgets('Aitum canvas with Dual Format', (tester) async {
    state(aitum, viewed: true, dualFormat: true);
    await harness.shot(tester, 'canvas_aitum_dual_format', dashboardTop());
  });

  testWidgets('landscape Aitum canvas on air (main view)', (tester) async {
    state(
      aitumLandscape,
      viewed: false,
      mainLive: false,
      status: const AitumOutputStatus(streaming: true),
    );
    await harness.shot(tester, 'canvas_landscape_pill', dashboardTop());
  });

  testWidgets('another plugin\'s canvas, no Aitum: view only', (tester) async {
    state(otherPlugin, viewed: true, support: AitumSupport.missing);
    await harness.shot(tester, 'canvas_view_only', dashboardTop());
  });

  testWidgets('editing scene visibility on a canvas', (tester) async {
    state(aitum, viewed: true);
    runInAction(() => dashboardStore.editSceneVisibility = true);
    await harness.shot(tester, 'canvas_edit_visibility', dashboardTop());
  });

  testWidgets('canvas scene items, group expanded', (tester) async {
    state(aitum, viewed: true);
    await harness.shot(tester, 'canvas_items', dashboardTop(items: true));
  });

  testWidgets('tablet: Aitum canvas', (tester) async {
    state(
      aitum,
      viewed: true,
      status: const AitumOutputStatus(streaming: true),
    );
    await harness.shot(
      tester,
      'canvas_tablet',
      dashboardTop(),
      size: kShotTablet,
    );
  });
}
