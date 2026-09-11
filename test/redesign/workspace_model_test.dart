import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/redesign/workspace/workspace_model.dart';

void main() {
  late WorkspaceModel model;

  setUp(() => model = WorkspaceModel(delay: Duration.zero));
  tearDown(() => model.dispose());

  test('inspection and focus never change program, preview or a draft', () {
    model.setDraft('Let me show you');
    model.setReply('Mira');
    model.setChatPaused(true);
    model.inspect('Screen + camera');
    model.setFocus(WorkspaceFocus.chat);
    model.setFocus(WorkspaceFocus.obs);

    expect(model.program, 'Main camera');
    expect(model.preview, 'Starting soon');
    expect(model.inspectedScene, 'Screen + camera');
    expect(model.draft, 'Let me show you');
    expect(model.replyTo, 'Mira');
    expect(model.chatPaused, isTrue);
  });

  test('together layout preserves the last deliberate phone focus', () {
    model.setFocus(WorkspaceFocus.chat);
    model.setFocus(WorkspaceFocus.balanced);
    expect(model.focus, WorkspaceFocus.balanced);
    expect(model.phoneFocus, WorkspaceFocus.chat);
  });

  test(
    'preview changes only on confirmation and preserves command target',
    () async {
      model.inspect('Screen + camera');
      final request = model.setPreview();
      model.inspect('A short break');
      expect(model.preview, 'Starting soon');
      expect(model.commandBusy, isTrue);
      await request;
      expect(model.preview, 'Screen + camera');
      expect(model.program, 'Main camera');
    },
  );

  test(
    'studio take uses preview while direct program uses inspected scene',
    () async {
      model.inspect('A short break');
      await model.takeScene();
      expect(model.program, 'Starting soon');
      model.setStudioMode(false);
      await model.takeScene();
      expect(model.program, 'A short break');
    },
  );

  test('rejected OBS command leaves the confirmed value intact', () async {
    model.rejectNextCommand = true;
    await model.toggleMute();
    expect(model.muted, isFalse);
    expect(model.commandBusy, isFalse);
    expect(model.commandError, contains('not accepted'));
  });

  test(
    'source command captures scene scope despite subsequent inspection',
    () async {
      model.inspect('Main camera');
      final request = model.toggleSource();
      model.inspect('Screen + camera');
      await request;
      expect(model.sourceEnabled, isTrue);
      model.inspect('Main camera');
      expect(model.sourceEnabled, isFalse);
    },
  );

  test(
    'leaving OBS invalidates in-flight commands without losing chat state',
    () async {
      model.setDraft('Still here');
      final request = model.toggleMute();
      model.disconnect();
      await request;
      expect(model.connection, ObsConnection.disconnected);
      expect(model.muted, isFalse);
      expect(model.pendingCommand, isNull);
      expect(model.draft, 'Still here');
    },
  );

  test('cancel during connect cannot resurrect the session', () async {
    model.setScenario(LabScenario.chatOnly);
    final request = model.connect();
    model.disconnect();
    await request;
    expect(model.connection, ObsConnection.disconnected);
  });

  test('chat can send independently while OBS reconnects', () async {
    model.setScenario(LabScenario.reconnecting);
    model.setDraft('We are still chatting');
    await model.sendMessage();
    expect(model.messages.last.text, 'We are still chatting');
    expect(model.connection, ObsConnection.reconnecting);
    expect(model.draft, isEmpty);
  });

  test('failed send preserves reply/draft and permits retry', () async {
    model.setReply('Mira');
    model.setDraft('Welcome back');
    model.rejectNextMessage = true;
    final count = model.messages.length;
    await model.sendMessage();
    expect(model.messages.length, count);
    expect(model.draft, 'Welcome back');
    expect(model.replyTo, 'Mira');
    expect(model.sendError, isNotNull);
    await model.sendMessage();
    expect(model.messages.length, count + 1);
    expect(model.replyTo, isNull);
  });

  test('an external OBS change supersedes a pending local command', () async {
    final request = model.takeScene();
    model.simulateExternalChange();
    await request;
    expect(model.program, 'Screen + camera');
    expect(model.commandBusy, isFalse);
  });
}
