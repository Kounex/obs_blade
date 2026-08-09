import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/modal_handler.dart';

void main() {
  testWidgets('barrier tap dismisses when Material wraps only the sheet',
      (tester) async {
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
                builder: (_) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('sheet body'),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('sheet body'), findsOneWidget);

    await tester.tapAt(const Offset(400, 50));
    await tester.pumpAndSettle();
    expect(find.text('sheet body'), findsNothing);
  });
}
