import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_preview/scene_preview.dart';

import '../persistence/support/hive_test_harness.dart';

/// A real (decodable) PNG so [Image.memory] actually resolves a frame -
/// deliberately NOT 16:9, to prove the pane's height no longer follows the
/// image's own intrinsic size.
Future<Uint8List> makeSquarePng(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()..color = const Color(0xFF336699),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

void main() {
  const previewWidth = 350.0;

  late Directory tempDir;
  late HiveTestHarness harness;
  late DashboardStore dashboardStore;

  Widget wrap() => MaterialApp(
    theme: ThemeData(
      cupertinoOverrideTheme: const CupertinoThemeData(),
      extensions: const [AppStatusColors.standard, AppTextColors.standard],
    ),
    home: const Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: previewWidth,
          child: ScenePreview(expandable: true),
        ),
      ),
    ),
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('scene_preview_aspect');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    final settingsBox = await Hive.openBox(HiveKeys.Settings.name);
    await settingsBox.put(SettingsKeys.DontShowPreviewWarning.name, true);

    dashboardStore = DashboardStore();
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);
  });

  tearDown(() async {
    dashboardStore.disposeListeners();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('opening the preview settles at a fixed 16:9 height and does not '
      'resize again once the (non-16:9) screenshot decodes', (tester) async {
    final bytes = await tester.runAsync(() => makeSquarePng(800));

    // Pre-set so the header tap's toggle flips shouldRequestPreviewImage
    // false -> the real network re-request path (_requestPreviewImage)
    // is skipped; only fires when the flag flips to true.
    dashboardStore.shouldRequestPreviewImage = true;

    await tester.pumpWidget(wrap());
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Current OBS scene preview'));
    await tester.pump(const Duration(milliseconds: 16));
    // Long enough for the expand crossfade (300ms default) to fully settle
    // while still showing the "fetching" placeholder (no image bytes yet).
    await tester.pump(const Duration(milliseconds: 700));

    final settledHeight = tester.getSize(find.byType(ScenePreview)).height;

    dashboardStore.scenePreviewImageBytes = bytes;

    for (final ms in [16, 32, 66, 150, 300, 600]) {
      await tester.pump(Duration(milliseconds: ms));
      expect(
        tester.getSize(find.byType(ScenePreview)).height,
        moreOrLessEquals(settledHeight, epsilon: 0.5),
        reason: 'the pane must not resize once the image decodes',
      );
    }

    expect(tester.takeException(), isNull);
  });
}
