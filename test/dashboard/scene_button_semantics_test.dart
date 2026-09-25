import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show Tristate;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/scene.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_buttons/scene_button.dart';

import '../persistence/support/hive_test_harness.dart';

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late DashboardStore dashboardStore;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('scene_button_semantics');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    dashboardStore = DashboardStore();
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('a scene tile reads as one node with its live state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    dashboardStore.setActiveSceneName('Gameplay');

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          cupertinoOverrideTheme: const CupertinoThemeData(),
          extensions: const [AppStatusColors.standard, AppTextColors.standard],
        ),
        home: Scaffold(
          body: Center(
            child: SceneButton(
              scene: const Scene(sceneName: 'Gameplay', sceneIndex: 0),
              visible: true,
              onVisibilityTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Gameplay, on program'), findsOneWidget);
    final node = tester.getSemantics(
      find.bySemanticsLabel('Gameplay, on program'),
    );
    expect(node.hint, 'Switches to this scene live');
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.flagsCollection.isSelected, Tristate.isTrue);

    /// The raw name text is merged away - no second, fragmentary node
    expect(find.bySemanticsLabel('Gameplay'), findsNothing);
    handle.dispose();
  });
}
