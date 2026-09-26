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
  inputKind: 'text_ft2_source_v2',
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

/// Scene switches between two scenes that both have items used to swap
/// the rows instantly - the entrance only ran out of an empty list. The
/// rows are keyed per scene now, so every switch replays a fade-only
/// entrance.
void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late DashboardStore dashboardStore;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('scene_items_entrance');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    dashboardStore = DashboardStore();
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);
    GetIt.instance.registerSingleton<NetworkStore>(NetworkStore());
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  void showScene(String sceneName, List<SceneItem> items) {
    runInAction(() {
      dashboardStore.activeSceneName = sceneName;
      dashboardStore.currentSceneItems = ObservableList.of(items);
      dashboardStore.sceneItemsSceneName = sceneName;
    });
  }

  /// The entrance's own Opacity: the first one below the first
  /// StaggeredEntrance (the rows' StaleGuard / slidable fades sit deeper)
  double firstRowOpacity(WidgetTester tester) {
    final Element entrance = tester.element(
      find.byType(StaggeredEntrance).first,
    );
    Opacity? found;
    void visit(Element element) {
      if (found != null) return;
      if (element.widget is Opacity) {
        found = element.widget as Opacity;
        return;
      }
      element.visitChildren(visit);
    }

    entrance.visitChildren(visit);
    return found!.opacity;
  }

  testWidgets('switching between two scenes with items replays a fade-only '
      'entrance', (tester) async {
    showScene('Camera', [_item(1, 'webcam')]);

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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(seconds: 1));
    expect(firstRowOpacity(tester), 1.0);

    /// Same item id in the next scene - without the per-scene key the row
    /// state would be reused and nothing would animate
    showScene('Break', [_item(1, 'brb-slate')]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 100));

    final double midFade = firstRowOpacity(tester);
    expect(midFade, greaterThan(0.0));
    expect(midFade, lessThan(1.0));

    /// Fade only: no vertical rise
    final Transform translate = tester.widget<Transform>(
      find
          .descendant(
            of: find.byType(StaggeredEntrance),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(translate.transform.getTranslation().y, 0.0);

    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(seconds: 1));
    expect(firstRowOpacity(tester), 1.0);
    expect(find.text('brb-slate'), findsOneWidget);
  });
}
