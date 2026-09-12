import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/redesign/workspace/workspace_app.dart';
import 'package:obs_blade/redesign/workspace/workspace_chat_fixture.dart';
import 'package:obs_blade/redesign/workspace/workspace_model.dart';

void main() {
  testWidgets(
    'Pro gate replaces native content without losing draft or focus',
    (tester) async {
      final model = WorkspaceModel(delay: Duration.zero);
      addTearDown(model.dispose);
      model.setFocus(WorkspaceFocus.chat);
      model.setDraft('Keep my thought');
      model.setReply('Mira');
      await tester.pumpWidget(WorkspaceApp(model: model));
      await tester.pumpAndSettle();
      model.setChatScenario(LabChatScenario.pro);
      await tester.pumpAndSettle();
      expect(find.text('Native chat with Pro'), findsOneWidget);
      expect(find.text('Use WebView chat'), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-timeline')), findsNothing);
      await model.sendMessage();
      expect(model.draft, 'Keep my thought');
      model.disconnect();
      model.setChatScenario(LabChatScenario.ready);
      await tester.pumpAndSettle();
      expect(find.text('Keep my thought'), findsOneWidget);
      expect(model.replyTo, 'Mira');
      expect(model.phoneFocus, WorkspaceFocus.chat);
    },
  );

  testWidgets('read-only and reconnecting states retain reading and drafting', (
    tester,
  ) async {
    final model = WorkspaceModel(delay: Duration.zero);
    addTearDown(model.dispose);
    model.setFocus(WorkspaceFocus.chat);
    model.setChatScenario(LabChatScenario.readOnly);
    await tester.pumpWidget(WorkspaceApp(model: model));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chat-timeline')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('chat-composer')),
      'Ready when chat returns',
    );
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('send-message')))
          .onPressed,
      isNull,
    );
    expect(find.text('Update chat permissions'), findsOneWidget);
    model.setChatScenario(LabChatScenario.reconnecting);
    await tester.pumpAndSettle();
    expect(model.draft, 'Ready when chat returns');
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('send-message')))
          .onPressed,
      isNull,
    );
  });

  for (final scenario in LabChatScenario.values) {
    testWidgets('small phone, large text: ${scenario.label}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final model = WorkspaceModel();
      addTearDown(model.dispose);
      model.setFocus(WorkspaceFocus.chat);
      model.setChatScenario(scenario);
      await tester.pumpWidget(WorkspaceApp(model: model));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
