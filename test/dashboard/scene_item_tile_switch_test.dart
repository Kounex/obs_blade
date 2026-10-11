import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/scene_item.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/utils/scene_item_color.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/scene_items/scene_item_tile.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/scene_items/scene_items.dart';

import '../persistence/support/hive_test_harness.dart';
import '../websocket/support/fake_obs_peer.dart';

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

const Color _red = Color(0x54FF4444);

/// Dogfood (2026-10-11): tapping another scene tinted a row of the old
/// list with the next scene's color before the next list arrived. A
/// switch moves the active scene (or the studio preview) at once, the
/// rows stay until the new GetSceneItemList answer, and item ids repeat
/// across scenes - so rows keyed by the active scene picked up the next
/// scene's item with the same id. Its toggles did too: a tap in that
/// window hid / locked the next scene's item instead of the row's own
void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late NetworkStore networkStore;
  late DashboardStore dashboardStore;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('scene_item_tile_switch');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    networkStore = NetworkStore();
    dashboardStore = DashboardStore();
    GetIt.instance.registerSingleton<NetworkStore>(networkStore);
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  /// 'Gameplay' shows its list (#1 Camera, uncolored); 'Break' has its own
  /// #1 (Slate) colored red - its color batch can land before its list
  void gameplayShownBreakColored() => runInAction(() {
    dashboardStore.activeSceneName = 'Gameplay';
    dashboardStore.currentSceneItems = ObservableList.of([_item(1, 'Camera')]);
    dashboardStore.sceneItemsSceneName = 'Gameplay';
    dashboardStore.sceneItemColors[sceneItemColorKey('Break', 1)] = _red;
  });

  Future<void> pumpItems(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          cupertinoOverrideTheme: const CupertinoThemeData(),
          extensions: const [AppStatusColors.standard, AppTextColors.standard],
        ),
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: RouteSettings(arguments: ScrollController()),
          builder: (_) => const Scaffold(body: SceneItems()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  Color? tintOf(WidgetTester tester, String sourceName) => tester
      .widgetList<Container>(
        find.descendant(
          of: find.ancestor(
            of: find.text(sourceName),
            matching: find.byType(SceneItemTile),
          ),
          matching: find.byType(Container),
        ),
      )
      .map((container) => container.color)
      .firstWhere((color) => color != null, orElse: () => null);

  testWidgets('a switch in flight keeps the old rows untinted until the next '
      'list arrives', (tester) async {
    gameplayShownBreakColored();
    await pumpItems(tester);
    expect(tintOf(tester, 'Camera'), isNull);

    /// Scene tile tapped: the active scene moves at once
    runInAction(() => dashboardStore.setActiveSceneName('Break'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Camera'), findsOneWidget);
    expect(tintOf(tester, 'Camera'), isNull);

    /// The next scene's list lands - now its #1 is tinted
    runInAction(() {
      dashboardStore.currentSceneItems = ObservableList.of([_item(1, 'Slate')]);
      dashboardStore.sceneItemsSceneName = 'Break';
    });
    await tester.pump(const Duration(seconds: 1));
    expect(tintOf(tester, 'Slate'), _red);
  });

  testWidgets('exposed studio mode: picking another preview scene does not '
      'tint the old preview rows', (tester) async {
    /// Real I/O stays outside the fake-async zone (runAsync)
    await tester.runAsync(
      () => Hive.box(
        HiveKeys.Settings.name,
      ).put(SettingsKeys.ExposeStudioControls.name, true),
    );
    gameplayShownBreakColored();
    runInAction(() {
      dashboardStore.studioMode = true;
      dashboardStore.studioModePreviewSceneName = 'Gameplay';
    });
    await pumpItems(tester);

    runInAction(() => dashboardStore.setStudioModePreviewSceneName('Break'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tintOf(tester, 'Camera'), isNull);
  });

  testWidgets('the eye of an old row toggles that row in its own scene, not '
      'the next scene\'s item with the same id', (tester) async {
    final FakeObsPeer peer =
        await tester.runAsync(FakeObsPeer.start) as FakeObsPeer;
    addTearDown(() async {
      dashboardStore.disposeListeners();
      networkStore.closeSession();
      await tester.runAsync(peer.close);
    });
    await tester.runAsync(() async {
      final closeCode = await networkStore.setOBSWebSocket(peer.connection);
      expect(closeCode, WebSocketCloseCode.DontClose);
    });

    gameplayShownBreakColored();
    await pumpItems(tester);
    runInAction(() => dashboardStore.setActiveSceneName('Break'));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.runAsync(() async {
      await tester.tap(find.bySemanticsLabel('Hide Camera'));
      for (var i = 0; i < 250; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        if (peer.requests.any(
          (request) => request['requestType'] == 'SetSceneItemEnabled',
        )) {
          break;
        }
      }
    });

    final set = peer.requests.lastWhere(
      (request) => request['requestType'] == 'SetSceneItemEnabled',
    );
    expect(set['requestData'], {
      'sceneName': 'Gameplay',
      'sceneItemId': 1,
      'sceneItemEnabled': false,
    });
  });
}
