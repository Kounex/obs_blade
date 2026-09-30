import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/enumeration_block/enumeration_block.dart';
import 'package:obs_blade/shared/general/enumeration_block/enumeration_entry.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/settings/logs/widgets/level_dot.dart';
import 'package:obs_blade/views/settings/logs/widgets/log_explanation.dart';

import '../persistence/support/hive_test_harness.dart';

/// Lists in the FAQ and the log explanation card: one text size per list,
/// one marker per entry.
Widget wrap(Widget child) {
  final base = ThemeData(brightness: Brightness.dark);
  return MaterialApp(
    theme: base.copyWith(
      textTheme: buildAppTextTheme(
        base.textTheme,
        textSecondary: AppTextColors.standard.textSecondary,
        textTertiary: AppTextColors.standard.textTertiary,
      ),
      extensions: const [AppStatusColors.standard, AppTextColors.standard],
    ),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

double? fontSizeOf(WidgetTester tester, String text) {
  final richText = tester.widget<RichText>(
    find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().startsWith(text),
    ),
  );
  return richText.text.style?.fontSize;
}

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  /// [BaseCard] reads the settings box
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('enumeration_block_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
  });

  tearDown(() async {
    await harness.close();
    tempDir.deleteSync(recursive: true);
  });

  testWidgets('title, entries and markers share the body size', (tester) async {
    await tester.pumpWidget(
      wrap(const EnumerationBlock(title: 'Lead-in', entries: ['First entry'])),
    );

    final body = Theme.of(
      tester.element(find.byType(EnumerationBlock)),
    ).textTheme.bodyMedium!.fontSize;

    expect(fontSizeOf(tester, 'Lead-in'), body);
    expect(fontSizeOf(tester, 'First entry'), body);
    expect(fontSizeOf(tester, '•'), body);
  });

  testWidgets('nested entries get a hollow bullet', (tester) async {
    await tester.pumpWidget(
      wrap(
        const EnumerationBlock(
          customEntries: [
            EnumerationEntry(text: 'Top'),
            EnumerationEntry(text: 'Nested', level: 2),
          ],
        ),
      ),
    );

    expect(find.text('•'), findsOneWidget);
    expect(find.text('◦'), findsOneWidget);
  });

  testWidgets('a custom marker replaces the bullet', (tester) async {
    await tester.pumpWidget(
      wrap(
        const EnumerationBlock(
          customEntries: [
            EnumerationEntry(marker: SizedBox(width: 8), text: 'Marked'),
          ],
        ),
      ),
    );

    expect(find.text('•'), findsNothing);
  });

  testWidgets('log explanation: one level dot per type, no bullets', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const LogExplanation()));
    await tester.tap(find.text('Information about logs'));
    await tester.pumpAndSettle();

    expect(find.byType(LevelDot), findsNWidgets(3));
    expect(find.text('•'), findsNothing);
  });
}
