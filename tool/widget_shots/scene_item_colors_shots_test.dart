import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/scene_item.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/scene_items/scene_items.dart';

import 'support/shots_harness.dart';

/// Source colors (OBS 32+, Sources dock -> Set Color) tinting the Scene
/// Items rows: the built-in presets at 33% alpha, custom HexArgb colors,
/// tinted group rows + their indented children, and the combination with
/// locked / hidden rows - plus the untinted baseline old OBS keeps
void main() {
  final harness = ShotsHarness();
  late DashboardStore dashboardStore;

  setUpAll(ShotsHarness.loadFonts);

  setUp(() async {
    await harness.setUp();
    dashboardStore = DashboardStore();
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);
    GetIt.instance.registerSingleton<NetworkStore>(NetworkStore());
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.tearDown();
  });

  SceneItem item(
    int id,
    String name, {
    String? group,
    bool isGroup = false,
    bool displayGroup = false,
    bool enabled = true,
    bool locked = false,
  }) => SceneItem(
    inputKind: 'image_source',
    isGroup: isGroup,
    sceneItemBlendMode: null,
    sceneItemEnabled: enabled,
    sceneItemId: id,
    sceneItemIndex: id,
    sceneItemLocked: locked,
    sceneItemTransform: null,
    sourceName: name,
    sourceType: 'OBS_SOURCE_TYPE_INPUT',
    parentGroupName: group,
    displayGroup: displayGroup,
  );

  /// What OBS would have told the store: the 'Main' scene's items plus the
  /// source colors it carries in their private settings
  void state(List<SceneItem> items, Map<String, Color> colors) =>
      runInAction(() {
        dashboardStore.activeSceneName = 'Main';
        dashboardStore.sceneItemsSceneName = 'Main';
        dashboardStore.currentSceneItems = ObservableList.of(items);
        dashboardStore.sceneItemColors = ObservableMap.of(colors);
      });

  Widget items() => const SizedBox(height: 420, child: SceneItems());

  testWidgets('no colors (old OBS / none assigned): untinted baseline', (
    tester,
  ) async {
    state([
      item(3, 'Camera'),
      item(1, 'Overlay Group', isGroup: true, displayGroup: true),
      item(2, 'Alert box', group: 'Overlay Group'),
    ], {});
    await harness.shot(tester, 'scene_item_colors_none', items());
  });

  testWidgets('built-in presets at 33% alpha, gaps stay untinted', (
    tester,
  ) async {
    state(
      [
        item(4, 'BRB card'),
        item(3, 'Camera'),
        item(2, 'Chat overlay'),
        item(1, 'Gameplay'),
      ],
      {
        'Main|1': const Color(0x54FF4444), // red
        'Main|2': const Color(0x544444FF), // blue
        // BRB card untinted on purpose
        'Main|4': const Color(0x54FFFFFF), // white
      },
    );
    await harness.shot(tester, 'scene_item_colors_presets', items());
  });

  testWidgets('custom colors: translucent and opaque HexArgb', (tester) async {
    state(
      [item(2, 'Facecam border'), item(1, 'Camera')],
      {
        'Main|1': const Color(0x55FF0000), // custom #55FF0000
        'Main|2': const Color(0xFF7A3DF0), // custom, fully opaque
      },
    );
    await harness.shot(tester, 'scene_item_colors_custom', items());
  });

  testWidgets('tinted group row and its tinted, indented child', (
    tester,
  ) async {
    state(
      [
        item(3, 'Camera'),
        item(1, 'Overlay Group', isGroup: true, displayGroup: true),
        item(2, 'Alert box', group: 'Overlay Group'),
      ],
      {
        'Main|1': const Color(0x5444FF44), // green group row
        'Overlay Group|2': const Color(0x54FF4444), // red child
      },
    );
    await harness.shot(tester, 'scene_item_colors_group', items());
  });

  testWidgets('tinted row that is locked and hidden (invisible)', (
    tester,
  ) async {
    state(
      [item(2, 'Old overlay', enabled: false, locked: true), item(1, 'Camera')],
      {
        'Main|1': const Color(0x54FF4444),
        'Main|2': const Color(0x54FF44FF), // magenta
      },
    );
    await harness.shot(tester, 'scene_item_colors_locked_hidden', items());
  });

  testWidgets('tablet: tinted group + child', (tester) async {
    state(
      [
        item(3, 'Camera'),
        item(1, 'Overlay Group', isGroup: true, displayGroup: true),
        item(2, 'Alert box', group: 'Overlay Group'),
      ],
      {
        'Main|1': const Color(0x5444FF44),
        'Overlay Group|2': const Color(0x54FF4444),
        'Main|3': const Color(0x54FFFF44), // yellow
      },
    );
    await harness.shot(
      tester,
      'scene_item_colors_group_tablet',
      items(),
      size: kShotTablet,
    );
  });
}
