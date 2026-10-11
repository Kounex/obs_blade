import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/enums/scene_item_type.dart';
import 'package:obs_blade/models/hidden_scene_item.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/input.dart';
import 'package:obs_blade/types/classes/api/scene_item.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/scene_item_color.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/audio_inputs/audio_inputs.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/scene_items/scene_items.dart';

import 'support/shots_harness.dart';

/// Visibility / mute toggles in the iOS glyph family next to the lock and
/// filter icons: the Edit Visibility slide pane as a status pill (visible
/// lit, hidden neutral) on phone, a narrow 320 pt phone and tablet, the
/// row eyes beside the lock and the audio mute speaker + its edit pane.
/// The Filters sheet polls OBS on a timer (needs a session), so its eye -
/// the same glyph swap as the row - has no shot here
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
    runInAction(() {
      dashboardStore.editSceneItemVisibility = false;
      dashboardStore.editAudioVisibility = false;
    });
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

  Input input(String name, {bool muted = false, double volume = 0.7}) => Input(
    inputKind: 'wasapi_input_capture',
    inputName: name,
    unversionedInputKind: 'wasapi_input_capture',
    inputVolumeMul: volume,
    inputVolumeDb: -3.1,
    inputMuted: muted,
  );

  final List<SceneItem> sceneItems = [
    item(4, 'Old overlay'),
    item(3, 'Camera'),
    item(1, 'Overlay Group', isGroup: true, displayGroup: true),
    item(2, 'Alert box', group: 'Overlay Group'),
  ];

  void state(List<SceneItem> items, [Map<String, Color> colors = const {}]) =>
      runInAction(() {
        dashboardStore.activeSceneName = 'Main';
        dashboardStore.sceneItemsSceneName = 'Main';
        dashboardStore.currentSceneItems = ObservableList.of(items);
        dashboardStore.sceneItemColors
          ..clear()
          ..addAll(colors);
      });

  /// 'Old overlay' (scene item) / 'Music' (audio) were hidden by the user
  /// earlier - their panes show the hidden pill. Real I/O stays outside
  /// the fake-async zone (runAsync)
  Future<void> hide(
    WidgetTester tester,
    String name,
    SceneItemType type, [
    int? sceneItemId,
  ]) => tester.runAsync(
    () => Hive.box<HiddenSceneItem>(
      HiveKeys.HiddenSceneItem.name,
    ).add(HiddenSceneItem('Main', type, sceneItemId, name, null, null, null)),
  );

  Widget items() => const SizedBox(height: 420, child: SceneItems());

  /// The wrapper's reaction only opens the pane on the false -> true
  /// change, so the flag flips after the first build (the harness pumps
  /// run the delayed open + slide animation to completion)
  for (final (name, size) in [
    ('visibility_edit_pane', kShotPhone),
    ('visibility_edit_pane_narrow', const Size(320, 640)),
    ('visibility_edit_pane_tablet', kShotTablet),
  ]) {
    testWidgets('edit scene visibility pane: $name', (tester) async {
      state(sceneItems, {
        sceneItemColorKey('Main', 3): const Color(0x54FF4444),
      });
      await hide(tester, 'Old overlay', SceneItemType.Source, 4);
      Future(
        () => runInAction(() => dashboardStore.editSceneItemVisibility = true),
      );
      await harness.shot(tester, name, items(), size: size);
    });
  }

  testWidgets('row eyes beside the lock: visible, invisible, locked', (
    tester,
  ) async {
    state([
      item(4, 'Old overlay', enabled: false),
      item(3, 'Camera', locked: true),
      item(1, 'Overlay Group', isGroup: true, displayGroup: true),
      item(2, 'Alert box', group: 'Overlay Group', enabled: false),
    ]);
    await harness.shot(tester, 'visibility_rows', items());
  });

  void audio() => runInAction(() {
    dashboardStore.activeSceneName = 'Main';
    dashboardStore.globalInputNames = ObservableList.of(['Desktop', 'Mic']);
    dashboardStore.allInputs = ObservableList.of([
      input('Desktop'),
      input('Mic', muted: true, volume: 0.45),
      input('Music', volume: 0.3),
      input('Game capture'),
    ]);
  });

  testWidgets('audio rows: speaker on / muted', (tester) async {
    audio();
    await harness.shot(
      tester,
      'visibility_audio_rows',
      const SizedBox(height: 760, child: AudioInputs()),
    );
  });

  testWidgets('edit audio visibility pane', (tester) async {
    audio();
    await hide(tester, 'Music', SceneItemType.Audio);
    Future(() => runInAction(() => dashboardStore.editAudioVisibility = true));
    await harness.shot(
      tester,
      'visibility_audio_edit_pane',
      const SizedBox(height: 760, child: AudioInputs()),
    );
  });
}
