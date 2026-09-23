import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/chat_autocomplete.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_autocomplete_strip.dart';

void main() {
  Iterable<ChatCompletionCandidate> source(ChatCompletionKind kind) =>
      kind == ChatCompletionKind.mention
      ? const [
          ChatCompletionCandidate(label: 'Alice', insertText: '@Alice'),
          ChatCompletionCandidate(label: 'Albert', insertText: '@Albert'),
        ]
      : const [ChatCompletionCandidate(label: 'Kappa', insertText: 'Kappa')];

  Future<TextEditingController> pump(WidgetTester tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatAutocompleteStrip(controller: controller, source: source),
        ),
      ),
    );
    return controller;
  }

  void type(TextEditingController controller, String text) {
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  testWidgets('shows matching chatters and completes on tap', (tester) async {
    final controller = await pump(tester);
    expect(find.text('Alice'), findsNothing);

    type(controller, 'hey @al');
    await tester.pumpAndSettle();
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Albert'), findsOneWidget);

    await tester.tap(find.text('Albert'));
    await tester.pumpAndSettle();
    expect(controller.text, 'hey @Albert ');
    expect(controller.selection.baseOffset, controller.text.length);
    expect(find.text('Alice'), findsNothing);
  });

  testWidgets('bare-word emote completion', (tester) async {
    final controller = await pump(tester);
    type(controller, 'so Kap');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kappa'));
    await tester.pumpAndSettle();
    expect(controller.text, 'so Kappa ');
  });

  testWidgets('collapses when nothing matches', (tester) async {
    final controller = await pump(tester);
    type(controller, '@zz');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chat-autocomplete-strip')), findsNothing);
  });
}
