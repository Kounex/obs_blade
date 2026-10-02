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
import 'package:obs_blade/models/enums/dashboard_element.dart';
import 'package:obs_blade/types/classes/api/aitum_vertical.dart';
import 'package:obs_blade/types/classes/api/obs_canvas.dart';
import 'package:obs_blade/types/classes/api/scene.dart';
import 'package:obs_blade/types/classes/api/scene_item.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/canvas/canvas_output_controls.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/canvas/canvas_picker.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/dashboard_element_layout.dart';
import 'package:obs_blade/views/dashboard/widgets/status_app_bar/on_air_status_cluster.dart';
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
const ObsCanvas _aitum = ObsCanvas(
  uuid: 'aitum',
  name: kAitumCanvasName,
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
  Future<void> viewVertical(
    WidgetTester tester, {
    ObsCanvas canvas = _vertical,
  }) async {
    runInAction(() {
      canvasStore.canvases = ObservableList.of([_main, canvas]);
    });
    canvasStore.viewCanvas(canvas.uuid);
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

  /// Lets the status overlay (delay + show + animations) run out
  Future<void> drainOverlay(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  /// What `_checkAitum` / `_loadAitumState` would have read from OBS
  void aitumAnswers({
    AitumSupport support = AitumSupport.available,
    String? liveScene,
    AitumOutputStatus status = const AitumOutputStatus(),
  }) => runInAction(() {
    canvasStore.aitumSupport = support;
    canvasStore.aitumLiveSceneName = liveScene;
    canvasStore.aitumStatus = status;
  });

  testWidgets('scene buttons show the viewed canvas, a tap only picks the '
      'scene to view', (tester) async {
    await tester.pumpWidget(app(const SceneButtons()));
    await tester.pump();
    expect(find.text('Program Scene'), findsOneWidget);

    await viewVertical(tester);
    aitumAnswers(support: AitumSupport.missing);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Program Scene'), findsNothing);
    expect(find.text('Vertical Main'), findsOneWidget);
    expect(find.text('Vertical BRB'), findsOneWidget);

    await tester.tap(find.text('Vertical BRB'));
    await tester.pump();
    expect(canvasStore.selectedSceneUuid, 'v-brb');

    /// The first view-only tap explains what live switching would need
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Shown in the app only'), findsOneWidget);
    expect(
      find.textContaining('need the Aitum Vertical plugin'),
      findsOneWidget,
    );
    await drainOverlay(tester);

    /// ... once per session
    await tester.tap(find.text('Vertical Main'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Shown in the app only'), findsNothing);
    await drainOverlay(tester);

    /// Back to main: the program scenes return
    canvasStore.viewCanvas(null);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Program Scene'), findsOneWidget);
  });

  testWidgets('Aitum Vertical: the live scene wears the tally, a tap '
      'switches it live', (tester) async {
    await tester.pumpWidget(app(const SceneButtons()));
    await viewVertical(tester, canvas: _aitum);
    aitumAnswers(liveScene: 'Vertical Main');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final Semantics tile = tester.widget(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Vertical Main, live',
      ),
    );
    expect(
      tile.properties.hint,
      'Switches the $kAitumCanvasName canvas to this scene live',
    );

    await tester.tap(find.text('Vertical BRB'));
    await tester.pump();

    /// Optimistic switch (no session to send on here), no view-only hint
    expect(canvasStore.aitumLiveSceneName, 'Vertical BRB');
    expect(canvasStore.selectedSceneUuid, 'v-brb');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Shown in the app only'), findsNothing);

    canvasStore.viewCanvas(null);
    await drainOverlay(tester);
  });

  test(
    'the studio-mode transition hides while another canvas is shown',
    () async {
      final settingsBox = Hive.box(HiveKeys.Settings.name);
      await settingsBox.put(SettingsKeys.ExposeStudioControls.name, true);

      int blocks({required bool viewingOtherCanvas}) =>
          (buildOrderedDashboardSlivers(
                    const [DashboardElement.StudioModeTransition],
                    settingsBox: settingsBox,
                    studioModeActive: true,
                    viewingOtherCanvas: viewingOtherCanvas,
                  ).single
                  as Column)
              .children
              .length;

      /// Leading gap + the transition row vs. the leading gap only
      expect(blocks(viewingOtherCanvas: false), 2);
      expect(blocks(viewingOtherCanvas: true), 1);
    },
  );

  testWidgets('output controls: hidden on main, live with Aitum Vertical', (
    tester,
  ) async {
    await tester.pumpWidget(app(const CanvasOutputControls()));
    await tester.pump();
    expect(find.text('Stream'), findsNothing);

    await viewVertical(tester, canvas: _aitum);
    aitumAnswers(
      liveScene: 'Vertical Main',
      status: const AitumOutputStatus(streaming: true, backtrack: true),
    );
    await tester.pump();

    expect(find.text('$kAitumCanvasName outputs'), findsOneWidget);
    expect(find.text('Stream'), findsOneWidget);
    expect(find.text('Recording'), findsOneWidget);
    expect(find.text('Backtrack'), findsOneWidget);
    expect(find.textContaining('View only'), findsNothing);
    expect(
      find.bySemanticsLabel('Stop $kAitumCanvasName stream'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Start $kAitumCanvasName recording'),
      findsOneWidget,
    );

    /// Save only while the backtrack runs
    expect(
      find.bySemanticsLabel('Save $kAitumCanvasName backtrack'),
      findsOneWidget,
    );

    expect(find.text('Virtual camera'), findsOneWidget);

    /// Pause + chapter only while the vertical recording runs
    expect(
      find.bySemanticsLabel('Pause $kAitumCanvasName recording'),
      findsNothing,
    );
    aitumAnswers(
      liveScene: 'Vertical Main',
      status: const AitumOutputStatus(
        streaming: true,
        backtrack: true,
        recording: true,
        recordingPaused: true,
      ),
    );
    await tester.pump();
    expect(
      find.bySemanticsLabel('Resume $kAitumCanvasName recording'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Add a chapter marker to the $kAitumCanvasName recording',
      ),
      findsOneWidget,
    );

    /// Stop asks first, naming the canvas
    await tester.tap(find.bySemanticsLabel('Stop $kAitumCanvasName stream'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Stop Streaming'), findsOneWidget);
    expect(find.textContaining('$kAitumCanvasName canvas'), findsOneWidget);

    canvasStore.viewCanvas(null);
    await tester.pump();
  });

  testWidgets('output controls without the plugin: muted, a tap says why', (
    tester,
  ) async {
    await tester.pumpWidget(app(const CanvasOutputControls()));
    await viewVertical(tester);
    aitumAnswers(support: AitumSupport.missing);
    await tester.pump();

    expect(find.textContaining('View only'), findsOneWidget);

    /// Never "Stop" or "Save" while nothing can be read from the plugin
    expect(find.text('Stop'), findsNothing);
    expect(find.text('Save'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Start Vertical stream'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.textContaining('need the Aitum Vertical plugin'),
      findsOneWidget,
    );

    /// No confirmation dialog - nothing would be sent
    expect(find.text('Start Streaming'), findsNothing);

    canvasStore.viewCanvas(null);
    await drainOverlay(tester);
  });

  testWidgets('canvas groups expand on tap', (tester) async {
    await tester.pumpWidget(app(const SceneItems()));
    await viewVertical(tester);
    runInAction(() {
      canvasStore.sceneItems = ObservableList.of([
        _item(5, 'Overlay Group').copyWith(isGroup: true),
        _item(1, 'Alert box').copyWith(parentGroupName: 'Overlay Group'),
        _item(2, 'vertical-cam'),
      ]);
    });
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Overlay Group'), findsOneWidget);
    expect(find.text('Alert box'), findsNothing);

    await tester.tap(find.text('Overlay Group'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Alert box'), findsOneWidget);

    await tester.tap(find.text('Overlay Group'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Alert box'), findsNothing);

    canvasStore.viewCanvas(null);
    await tester.pump();
  });

  testWidgets('app bar: the vertical pill only while Aitum\'s output runs, '
      'a tap shows that canvas', (tester) async {
    /// Narrow phone - three pills scale down instead of overflowing
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    runInAction(() {
      canvasStore.canvases = ObservableList.of([_main, _aitum]);
    });
    await tester.pumpWidget(app(const OnAirStatusCluster()));
    aitumAnswers();
    await tester.pump();
    final pill = find.bySemanticsLabel('$kAitumCanvasName: live, recording');
    expect(find.byType(ExtraCanvasOnAirPill), findsNothing);

    aitumAnswers(
      status: const AitumOutputStatus(streaming: true, recording: true),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(pill, findsOneWidget);
    expect(find.text('LIVE · REC'), findsOneWidget);
    expect(tester.takeException(), isNull);

    /// Unknown while reconnecting
    runInAction(() => dashboardStore.reconnecting = true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ExtraCanvasOnAirPill), findsNothing);
    runInAction(() => dashboardStore.reconnecting = false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byType(ExtraCanvasOnAirPill));
    await tester.pump();
    expect(canvasStore.viewedCanvasUuid, _aitum.uuid);

    canvasStore.viewCanvas(null);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('app bar: a Dual Format canvas shows while the main stream is '
      'live; its shape picks the glyph', (tester) async {
    const landscape = ObsCanvas(
      uuid: 'wide',
      name: 'Clean Feed',
      isMain: false,
      baseWidth: 2560,
      baseHeight: 1440,
    );
    runInAction(() {
      canvasStore.canvases = ObservableList.of([_main, _vertical, landscape]);
      canvasStore.dualFormatCanvasUuid = _vertical.uuid;
    });
    await tester.pumpWidget(app(const OnAirStatusCluster()));
    await tester.pump();
    expect(find.byType(ExtraCanvasOnAirPill), findsNothing);

    runInAction(() => dashboardStore.isLive = true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.bySemanticsLabel('Vertical: live with the main stream'),
      findsOneWidget,
    );
    expect(find.byIcon(CupertinoIcons.device_phone_portrait), findsOneWidget);

    runInAction(() => canvasStore.dualFormatCanvasUuid = landscape.uuid);
    await tester.pump();
    expect(find.byIcon(CupertinoIcons.rectangle_on_rectangle), findsOneWidget);

    runInAction(() => dashboardStore.isLive = false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('outputs: Dual Format caption, Aitum\'s own stream asks first', (
    tester,
  ) async {
    await tester.pumpWidget(app(const CanvasOutputControls()));
    await viewVertical(tester, canvas: _aitum);
    aitumAnswers(liveScene: 'Vertical Main');
    runInAction(() => canvasStore.dualFormatCanvasUuid = _aitum.uuid);
    await tester.pump();
    expect(
      find.text('Goes live with the main stream (Dual Format)'),
      findsOneWidget,
    );

    runInAction(() => dashboardStore.isLive = true);
    await tester.pump();
    expect(
      find.text('Live with the main stream (Dual Format)'),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel('Start $kAitumCanvasName stream'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Separate Stream'), findsOneWidget);
    expect(find.textContaining('e.g. TikTok'), findsOneWidget);

    runInAction(() => dashboardStore.isLive = false);
    canvasStore.viewCanvas(null);
    await tester.pump();
  });

  test('labels name a canvas by its shape', () {
    expect(_vertical.outputLabel, 'vertical');
    expect(
      const ObsCanvas(
        uuid: 'a',
        name: kAitumCanvasName,
        isMain: false,
        baseWidth: 1080,
        baseHeight: 1350,
      ).outputLabel,
      'vertical',
    );

    /// Aitum's canvas keeps its name when set to landscape
    expect(
      const ObsCanvas(
        uuid: 'a',
        name: kAitumCanvasName,
        isMain: false,
        baseWidth: 1920,
        baseHeight: 1080,
      ).outputLabel,
      kAitumCanvasName,
    );
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
