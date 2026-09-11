import 'package:flutter/foundation.dart';

import 'source_control.dart';

enum WorkspaceFocus { obs, balanced, chat }

enum ObsConnection { disconnected, connecting, connected, reconnecting, failed }

enum LabScenario { live, chatOnly, firstUse, authFailed, reconnecting }

class WorkspaceMessage {
  const WorkspaceMessage(this.author, this.text, {this.isYou = false});

  final String author;
  final String text;
  final bool isYou;
}

/// In-memory interaction model. No sockets, accounts, purchase APIs or Hive.
/// Command outcomes are simulated; this is not a production adapter contract.
class WorkspaceModel extends ChangeNotifier {
  WorkspaceModel({this.delay = const Duration(milliseconds: 650)});

  final Duration delay;
  WorkspaceFocus focus = WorkspaceFocus.obs;
  WorkspaceFocus _lastSingleFocus = WorkspaceFocus.obs;
  ObsConnection connection = ObsConnection.connected;
  bool hasSavedConnection = true;
  bool studioMode = true;
  String program = 'Main camera';
  String preview = 'Starting soon';
  String inspectedScene = 'Main camera';
  List<String> get scenes => const [
    'Main camera',
    'Starting soon',
    'Screen + camera',
    'A short break',
    'Closing conversation',
  ];
  double volume = .72;
  bool muted = false;
  final Map<String, bool> _sourceEnabledByScene = {};
  String? pendingCommand;
  String? commandError;
  String draft = '';
  String? replyTo;
  String? sendError;
  bool sending = false;
  bool chatPaused = false;
  bool showActivity = true;
  bool rejectNextCommand = false;
  bool rejectNextMessage = false;
  bool _disposed = false;
  int _obsEpoch = 0;
  int _chatEpoch = 0;

  final List<WorkspaceMessage> messages = [
    const WorkspaceMessage('Mira', 'That camera angle looks great!'),
    const WorkspaceMessage('pixelpilot', 'What are we working on today?'),
    const WorkspaceMessage(
      'Jules · mod',
      'Welcome in everyone. Make yourselves at home.',
    ),
    const WorkspaceMessage('Sam', 'Caught the last stream — loved the ending.'),
    const WorkspaceMessage('Mira', 'The tiny details make such a difference ✨'),
    const WorkspaceMessage('ellie', 'Sound is good here 👍'),
    const WorkspaceMessage(
      'pixelpilot',
      'Could we see the other view for a moment?',
    ),
    const WorkspaceMessage(
      'Jules · mod',
      'I put the link in chat for anyone joining now.',
    ),
    const WorkspaceMessage('river', 'First time here. This is so relaxing.'),
    const WorkspaceMessage('Sam', 'Welcome, river!'),
    const WorkspaceMessage('Mira', 'A little closer would be perfect.'),
    const WorkspaceMessage('ellie', 'Yes! We can see it clearly now.'),
  ];

  bool get isLiveObs => false;
  bool get hasAudioControls => true;
  List<SourceControl> get sourceControls => const [];
  bool get sourcesReady => true;
  String? get sourceProblem => null;
  Future<void> refreshSources() async {}
  Future<void> setSourceEnabled(ObsSourceTarget target, bool enabled) async {}
  bool get obsStateFresh => connection == ObsConnection.connected;
  String get connectionName => 'Studio OBS';
  String? get connectionProblem => null;
  Future<void> refreshObs() async {}

  bool get canControl => connection == ObsConnection.connected;
  bool get commandBusy => pendingCommand != null;
  bool get sourceEnabled => _sourceEnabledByScene[inspectedScene] ?? true;
  WorkspaceFocus get phoneFocus =>
      focus == WorkspaceFocus.balanced ? _lastSingleFocus : focus;

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void setFocus(WorkspaceFocus value) {
    focus = value;
    if (value != WorkspaceFocus.balanced) _lastSingleFocus = value;
    _changed();
  }

  void inspect(String scene) {
    inspectedScene = scene;
    _changed();
  }

  void setDraft(String value) {
    if (sending) return;
    draft = value;
    sendError = null;
    _changed();
  }

  void setReply(String? author) {
    replyTo = author;
    _changed();
  }

  void setChatPaused(bool value) {
    if (chatPaused == value) return;
    chatPaused = value;
    _changed();
  }

  void toggleActivity() {
    showActivity = !showActivity;
    _changed();
  }

  void setStudioMode(bool value) {
    if (!canControl || commandBusy) return;
    studioMode = value;
    _changed();
  }

  void setScenario(LabScenario scenario) {
    _obsEpoch++;
    pendingCommand = null;
    commandError = null;
    hasSavedConnection = scenario != LabScenario.firstUse;
    connection = switch (scenario) {
      LabScenario.live => ObsConnection.connected,
      LabScenario.chatOnly ||
      LabScenario.firstUse => ObsConnection.disconnected,
      LabScenario.authFailed => ObsConnection.failed,
      LabScenario.reconnecting => ObsConnection.reconnecting,
    };
    // Scenario controls affect OBS availability, never the independent chat.
    _changed();
  }

  Future<void> connect({String password = ''}) async {
    if (connection == ObsConnection.connecting) return;
    final epoch = ++_obsEpoch;
    final needsPassword = connection == ObsConnection.failed;
    connection = ObsConnection.connecting;
    pendingCommand = null;
    commandError = null;
    _changed();
    await Future<void>.delayed(delay);
    if (_disposed || epoch != _obsEpoch) return;
    connection = needsPassword && password.trim().isEmpty
        ? ObsConnection.failed
        : ObsConnection.connected;
    _changed();
  }

  void disconnect() {
    _obsEpoch++;
    connection = ObsConnection.disconnected;
    pendingCommand = null;
    commandError = null;
    _changed();
  }

  Future<void> _command(String label, VoidCallback apply) async {
    if (!canControl || commandBusy) return;
    final epoch = _obsEpoch;
    final reject = rejectNextCommand;
    rejectNextCommand = false;
    pendingCommand = label;
    commandError = null;
    _changed();
    await Future<void>.delayed(delay);
    if (_disposed || epoch != _obsEpoch) return;
    pendingCommand = null;
    if (reject) {
      commandError = '$label was not accepted. Your OBS state is unchanged.';
    } else {
      apply();
    }
    _changed();
  }

  Future<void> setPreview() {
    final target = inspectedScene;
    return _command('Preview change', () => preview = target);
  }

  Future<void> takeScene() {
    final target = studioMode ? preview : inspectedScene;
    return _command('Program change', () => program = target);
  }

  Future<void> toggleMute() =>
      _command('Microphone change', () => muted = !muted);

  Future<void> setVolume(double value) =>
      _command('Volume change', () => volume = value.clamp(0, 1));

  Future<void> toggleSource() {
    final scene = inspectedScene;
    final wasEnabled = sourceEnabled;
    return _command(
      'Camera visibility change',
      () => _sourceEnabledByScene[scene] = !wasEnabled,
    );
  }

  void simulateExternalChange() {
    if (!canControl) return;
    _obsEpoch++;
    pendingCommand = null;
    commandError = null;
    program = 'Screen + camera';
    _changed();
  }

  Future<void> sendMessage() async {
    final text = draft.trim();
    if (text.isEmpty || sending) return;
    final epoch = ++_chatEpoch;
    final reject = rejectNextMessage;
    rejectNextMessage = false;
    sending = true;
    sendError = null;
    _changed();
    await Future<void>.delayed(delay);
    if (_disposed || epoch != _chatEpoch) return;
    sending = false;
    if (reject) {
      sendError = 'Message not sent. Your draft is saved — try again.';
    } else {
      messages.add(WorkspaceMessage('You', text, isYou: true));
      draft = '';
      replyTo = null;
    }
    _changed();
  }

  @override
  void dispose() {
    _disposed = true;
    _obsEpoch++;
    _chatEpoch++;
    super.dispose();
  }
}
