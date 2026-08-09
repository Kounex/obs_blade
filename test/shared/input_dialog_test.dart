import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/shared/dialogs/input.dart';

void main() {
  testWidgets('InputDialog opens without inputCheck (rename path)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => InputDialog(
                    title: 'Rename entry',
                    body: 'Please enter a new name for this entry',
                    inputPlaceholder: 'Entry name',
                    inputText: 'Stream 1',
                    onSave: (_) {},
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Rename entry'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
