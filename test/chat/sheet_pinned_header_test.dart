import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_options_sheet.dart';

import '../persistence/support/hive_test_harness.dart';

/// Rule: a sheet's drag handle / title / back chevron stay pinned while
/// its body scrolls (they live outside the scroll view).
void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sheet_header_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
  });

  tearDown(() async {
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('options sheet sub-page header stays put while scrolling', (
    tester,
  ) async {
    /// Short viewport so the Appearance page must scroll.
    tester.view.physicalSize = const Size(800, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ModalHandler.showBaseBottomSheet(
                context: context,
                barrierDismissible: true,
                enableDrag: true,
                maxHeightFraction: 0.72,
                builder: (_) =>
                    const NativeChatOptionsSheet(chatType: ChatType.Twitch),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();

    final chevron = find.byIcon(CupertinoIcons.chevron_back);
    final title = find.text('Appearance');
    final chevronBefore = tester.getTopLeft(chevron);
    final titleBefore = tester.getTopLeft(title);

    await tester.drag(find.text('Separators'), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(chevron), chevronBefore);
    expect(tester.getTopLeft(title), titleBefore);
    expect(
      find.ancestor(of: chevron, matching: find.byType(SingleChildScrollView)),
      findsNothing,
    );
  });
}
