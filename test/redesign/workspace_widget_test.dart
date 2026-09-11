import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/redesign/workspace/workspace_app.dart';
import 'package:obs_blade/redesign/workspace/workspace_model.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    WorkspaceModel model, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(WorkspaceApp(model: model));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'draft, reply and scroll survive focus changes and tablet resize',
    (tester) async {
      final model = WorkspaceModel(delay: Duration.zero);
      addTearDown(model.dispose);
      model.setFocus(WorkspaceFocus.chat);
      model.setReply('Mira');
      await mount(tester, model);

      final composer = find.byKey(const ValueKey('chat-composer'));
      await tester.enterText(composer, 'Let me adjust the sound');
      final timeline = find.byKey(const ValueKey('chat-timeline'));
      final list = tester.widget<ListView>(timeline);
      final controller = list.controller!;
      controller.jumpTo(controller.position.minScrollExtent);
      await tester.pumpAndSettle();
      final offset = controller.offset;

      await tester.tap(find.byKey(const ValueKey('workspace-focus-obs')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('workspace-focus-chat')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(composer).controller!.text,
        'Let me adjust the sound',
      );
      expect(model.replyTo, 'Mira');
      expect(tester.widget<ListView>(timeline).controller, same(controller));
      expect(controller.offset, closeTo(offset, 1));

      tester.view.physicalSize = const Size(1180, 820);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(composer).controller!.text,
        'Let me adjust the sound',
      );
      expect(tester.widget<ListView>(timeline).controller, same(controller));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('chat-only workspace sends without connecting OBS', (
    tester,
  ) async {
    final model = WorkspaceModel(delay: Duration.zero);
    addTearDown(model.dispose);
    model.setScenario(LabScenario.chatOnly);
    model.setFocus(WorkspaceFocus.chat);
    await mount(tester, model);
    await tester.enterText(
      find.byKey(const ValueKey('chat-composer')),
      'Hello!',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('send-message')));
    await tester.pumpAndSettle();
    expect(model.messages.last.text, 'Hello!');
    expect(model.connection, ObsConnection.disconnected);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reply and failed draft remain usable above a phone keyboard', (
    tester,
  ) async {
    final model = WorkspaceModel(delay: Duration.zero);
    addTearDown(model.dispose);
    model.setFocus(WorkspaceFocus.chat);
    model.setReply('Mira');
    model.setDraft('Thanks for joining us');
    model.sendError = 'Message not sent. Your draft is saved — try again.';
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await mount(tester, model);
    expect(
      find.byKey(const ValueKey('chat-composer')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('send-message')).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets(
    'output action stays reachable and scene inspection opens details',
    (tester) async {
      final model = WorkspaceModel(delay: Duration.zero);
      addTearDown(model.dispose);
      await mount(tester, model, size: const Size(360, 640));
      final take = find.byKey(const ValueKey('take-scene'));
      expect(take.hitTestable(), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('scene-Main camera')));
      await tester.pumpAndSettle();
      expect(find.text('Back to scenes'), findsOneWidget);
      expect(find.text('Camera source'), findsOneWidget);
      expect(model.program, 'Main camera');
      expect(model.preview, 'Starting soon');
      expect(take.hitTestable(), findsOneWidget);
    },
  );

  testWidgets('tablet together returns to the last phone focus on resize', (
    tester,
  ) async {
    final model = WorkspaceModel(delay: Duration.zero);
    addTearDown(model.dispose);
    model.setFocus(WorkspaceFocus.chat);
    model.setFocus(WorkspaceFocus.balanced);
    await mount(tester, model, size: const Size(1180, 820));
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('chat-composer')).hitTestable(),
      findsOneWidget,
    );
    expect(model.phoneFocus, WorkspaceFocus.chat);
  });

  for (final size in [
    const Size(360, 640),
    const Size(390, 844),
    const Size(820, 1180),
    const Size(900, 700),
    const Size(1180, 820),
  ]) {
    for (final focus in [WorkspaceFocus.obs, WorkspaceFocus.chat]) {
      testWidgets('no overflow at $size in ${focus.name} with large text', (
        tester,
      ) async {
        final model = WorkspaceModel(delay: Duration.zero);
        addTearDown(model.dispose);
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        model.setFocus(focus);
        await mount(tester, model, size: size);
      });
    }
  }
}
