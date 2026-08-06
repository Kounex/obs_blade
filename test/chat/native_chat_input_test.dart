import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_input.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

NativeChatInput buildInput({
  bool canSend = true,
  bool inFlight = false,
  String? errorText,
  TextEditingController? controller,
  FocusNode? focusNode,
  Widget? leading,
  Future<bool> Function(String)? onSend,
  VoidCallback? onRelogin,
}) =>
    NativeChatInput(
      controller: controller,
      focusNode: focusNode,
      leading: leading,
      canSend: canSend,
      inFlight: inFlight,
      errorText: errorText,
      accentColor: Colors.purple,
      onSend: onSend ?? (_) async => true,
      onRelogin: onRelogin ?? () {},
    );

void main() {
  testWidgets('ready state renders the field; read-only the lock strip',
      (tester) async {
    await tester.pumpWidget(wrap(buildInput()));
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Logged in read-only'), findsNothing);

    await tester.pumpWidget(wrap(buildInput(canSend: false)));
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Logged in read-only'), findsOneWidget);
  });

  testWidgets('read-only strip fires onRelogin', (tester) async {
    var relogin = false;
    await tester.pumpWidget(
      wrap(buildInput(canSend: false, onRelogin: () => relogin = true)),
    );

    await tester.tap(find.text('Re-login to chat'));
    expect(relogin, isTrue);
  });

  testWidgets('send submits trimmed text and clears on success',
      (tester) async {
    String? sent;
    await tester.pumpWidget(
      wrap(
        buildInput(
          onSend: (text) async {
            sent = text;
            return true;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '  hello chat  ');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    expect(sent, 'hello chat');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('failed send keeps the text', (tester) async {
    await tester.pumpWidget(
      wrap(buildInput(onSend: (_) async => false)),
    );

    await tester.enterText(find.byType(TextField), 'keep me');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'keep me',
    );
  });

  testWidgets('empty submit never calls onSend', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      wrap(buildInput(onSend: (_) async {
        calls++;
        return true;
      })),
    );

    await tester.enterText(find.byType(TextField), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    expect(calls, 0);
  });

  testWidgets('inFlight disables the field and the send button',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      wrap(
        buildInput(
          inFlight: true,
          onSend: (_) async {
            calls++;
            return true;
          },
        ),
      ),
    );

    expect(
      tester.widget<TextField>(find.byType(TextField)).enabled,
      isFalse,
    );

    await tester.tap(find.byType(NativeChatInput));
    await tester.pump();
    expect(calls, 0);
  });

  testWidgets('error text renders above the dock', (tester) async {
    await tester.pumpWidget(wrap(buildInput(errorText: 'boom')));
    expect(find.text('boom'), findsOneWidget);
  });

  testWidgets('field is hard-capped at 500 chars', (tester) async {
    await tester.pumpWidget(wrap(buildInput()));
    expect(tester.widget<TextField>(find.byType(TextField)).maxLength, 500);
  });

  testWidgets('uses an external controller and never disposes it',
      (tester) async {
    final controller = TextEditingController(text: 'hello');
    await tester.pumpWidget(wrap(buildInput(controller: controller)));

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller,
      same(controller),
    );

    /// Unmount the dock — an external controller must survive (an
    /// internal one is disposed with the state).
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    expect(() => controller.text = 'still alive', returnsNormally);
  });

  testWidgets('clear-on-success works with an external controller',
      (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(wrap(buildInput(controller: controller)));

    await tester.enterText(find.byType(TextField), 'picker inserted');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    expect(controller.text, isEmpty);
  });

  testWidgets('renders the leading slot left of the field', (tester) async {
    await tester.pumpWidget(wrap(buildInput(leading: const Text('PICK'))));

    expect(find.text('PICK'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('uses an external focus node', (tester) async {
    final node = FocusNode();
    await tester.pumpWidget(wrap(buildInput(focusNode: node)));

    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode,
      same(node),
    );
  });
}
