import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/hidden_scene.dart';
import 'package:obs_blade/models/enums/scene_item_type.dart';
import 'package:obs_blade/models/hidden_scene_item.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/canvas_view.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/aitum_vertical.dart';
import 'package:obs_blade/types/classes/api/obs_canvas.dart';
import 'package:obs_blade/types/classes/api/scene.dart';
import 'package:obs_blade/types/classes/api/scene_item.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/utils/network_helper.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_buttons/scene_buttons.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/scene_items/scene_items.dart';

import '../persistence/support/hive_test_harness.dart';
import '../websocket/support/fake_obs_peer.dart';

const ObsCanvas _main = ObsCanvas(uuid: 'main', name: 'Main', isMain: true);
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

/// Edit Scene Visibility on another canvas: entries are stored with the
/// canvas name, so a same-named main scene / item keeps its own state, and
/// a tap while editing never switches the canvas live.
void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeObsPeer peer;
  late NetworkStore networkStore;
  late DashboardStore dashboardStore;
  late CanvasViewStore canvasStore;

  Box<HiddenScene> hiddenScenes() =>
      Hive.box<HiddenScene>(HiveKeys.HiddenScene.name);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('canvas_hidden_scenes');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    await hiddenScenes().clear();
    await Hive.box<HiddenSceneItem>(HiveKeys.HiddenSceneItem.name).clear();

    peer = await FakeObsPeer.start();
    networkStore = NetworkStore();
    dashboardStore = DashboardStore();
    canvasStore = CanvasViewStore();
    GetIt.instance.registerSingleton<NetworkStore>(networkStore);
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);
    GetIt.instance.registerSingleton<CanvasViewStore>(canvasStore);
    expect(
      await networkStore.setOBSWebSocket(peer.connection),
      WebSocketCloseCode.DontClose,
    );
    runInAction(() {
      dashboardStore.scenes = ObservableList.of(const [
        Scene(sceneName: 'Chat', sceneIndex: 0),
      ]);
    });
  });

  tearDown(() async {
    canvasStore.dispose();
    NetworkHelper.failAllPendingAcks();
    networkStore.closeSession();
    await peer.close();
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

  /// Aitum canvas viewed with live control, "Chat" live - a same-named
  /// scene exists on main
  Future<void> viewAitum(WidgetTester tester) async {
    /// Set directly, not via viewCanvas - that would read the canvas from
    /// the (fake) OBS and overwrite what the test fills in
    runInAction(() {
      canvasStore.canvases = ObservableList.of([_main, _aitum]);
      canvasStore.viewedCanvasUuid = _aitum.uuid;
      canvasStore.scenes = ObservableList.of(const [
        CanvasScene(uuid: 'v-chat', name: 'Chat'),
        CanvasScene(uuid: 'v-brb', name: 'BRB'),
      ]);
      canvasStore.selectedSceneUuid = 'v-chat';
      canvasStore.sceneItems = ObservableList.of([_item(1, 'Cam')]);
      canvasStore.aitumSupport = AitumSupport.available;
      canvasStore.aitumLiveSceneName = 'Chat';
    });
  }

  testWidgets('a tap while editing hides the canvas scene for that canvas '
      'only, never switches live', (tester) async {
    await tester.pumpWidget(app(const SceneButtons()));
    await viewAitum(tester);
    dashboardStore.setEditSceneVisibility(true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.runAsync(() async {
      await tester.tap(find.text('BRB'));
      await hiddenScenes().flush();
    });
    await tester.pump();

    expect(canvasStore.aitumLiveSceneName, 'Chat');
    final entry = hiddenScenes().values.single;
    expect(entry.sceneName, 'BRB');
    expect(entry.canvasName, kAitumCanvasName);

    /// Still listed while editing (with the hidden badge), gone after
    expect(find.text('BRB'), findsOneWidget);
    dashboardStore.setEditSceneVisibility(false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('BRB'), findsNothing);
    expect(find.text('Chat'), findsOneWidget);

    canvasStore.viewCanvas(null);
    await tester.pump();
  });

  testWidgets('main and canvas entries never leak into each other', (
    tester,
  ) async {
    final connection = networkStore.activeSession!.connection;

    /// Hidden on main (pre-canvas entry: no canvas name) - same name as the
    /// canvas' live scene
    await tester.runAsync(() async {
      await hiddenScenes().add(
        HiddenScene('Chat', connection.name, connection.host),
      );
      await hiddenScenes().flush();
    });
    expect(
      hiddenScenes().values.single.isScene(
        'Chat',
        connection.name,
        connection.host,
        canvasName: kAitumCanvasName,
      ),
      isFalse,
    );

    await tester.pumpWidget(app(const SceneButtons()));
    await viewAitum(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    /// The canvas' "Chat" stays - only main's "Chat" is hidden
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('BRB'), findsOneWidget);

    canvasStore.viewCanvas(null);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    /// Main view: its "Chat" is the hidden one
    expect(find.text('Chat'), findsNothing);
  });

  testWidgets('canvas scene items hide per canvas too', (tester) async {
    final connection = networkStore.activeSession!.connection;
    await tester.runAsync(() async {
      await Hive.box<HiddenSceneItem>(HiveKeys.HiddenSceneItem.name).add(
        HiddenSceneItem(
          'Chat',
          SceneItemType.Source,
          1,
          'Cam',
          'OBS_SOURCE_TYPE_INPUT',
          connection.name,
          connection.host,
          kAitumCanvasName,
        ),
      );
    });

    await tester.pumpWidget(app(const SceneItems()));
    await viewAitum(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Cam'), findsNothing);

    dashboardStore.setEditSceneItemVisibility(true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Cam'), findsOneWidget);

    /// The slide pane closes on a 50 ms delay
    dashboardStore.setEditSceneItemVisibility(false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Cam'), findsNothing);
    canvasStore.viewCanvas(null);
    await tester.pump();
  });
}
