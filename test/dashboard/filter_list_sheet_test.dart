import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/app.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/filter.dart';
import 'package:obs_blade/types/classes/api/scene_item.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/scene_items/filter_list/filter_list.dart';

import '../persistence/support/hive_test_harness.dart';

const SceneItem _facecam = SceneItem(
  inputKind: 'dshow_input',
  isGroup: false,
  sceneItemBlendMode: null,
  sceneItemEnabled: true,
  sceneItemId: 7,
  sceneItemIndex: 0,
  sceneItemLocked: false,
  sceneItemTransform: null,
  sourceName: 'Facecam',
  sourceType: 'OBS_SOURCE_TYPE_INPUT',
  filters: [
    Filter(
      filterEnabled: true,
      filterIndex: 0,
      filterKind: 'color_filter_v2',
      filterName: 'Color Correction',
      filterSettings: {'brightness': 0.05},
    ),
  ],
);

/// The Filters sheet: its item can vanish while it's open (scene switched
/// in OBS, item removed), and OBS can quit after it closed
void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late DashboardStore dashboardStore;
  late NetworkStore networkStore;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('filter_list_sheet');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    dashboardStore = DashboardStore();
    networkStore = NetworkStore();
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);
    GetIt.instance.registerSingleton<NetworkStore>(networkStore);
    runInAction(
      () => dashboardStore.currentSceneItems = ObservableList.of([_facecam]),
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: App.buildTheme(Hive.box(HiveKeys.Settings.name)),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ModalHandler.showBaseBottomSheet(
                context: context,
                height: BaseSheetHeight.tall,
                builder: (_) => const FilterList(sceneItem: _facecam),
              ),
              child: const Text('filters'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('filters'));
    await tester.pumpAndSettle();
    expect(find.text('Color Correction'), findsOneWidget);
  }

  testWidgets('the item disappearing closes the sheet without an error', (
    tester,
  ) async {
    await open(tester);

    runInAction(() => dashboardStore.currentSceneItems = ObservableList());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Color Correction'), findsNothing);
    expect(find.text('filters'), findsOneWidget);
  });

  testWidgets('OBS quitting after the sheet closed pops nothing else', (
    tester,
  ) async {
    await open(tester);
    Navigator.of(tester.element(find.text('Color Correction'))).pop();
    await tester.pumpAndSettle();

    runInAction(() => networkStore.obsTerminated = true);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('filters'), findsOneWidget);
  });

  testWidgets('OBS quitting while it is open closes it', (tester) async {
    await open(tester);

    runInAction(() => networkStore.obsTerminated = true);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Color Correction'), findsNothing);
    expect(find.text('filters'), findsOneWidget);
  });
}
