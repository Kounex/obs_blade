import '../../models/connection.dart';
import '../workspace/workspace_model.dart';
import '../workspace/source_control.dart';
import 'obs_scene_controller.dart';
import 'obs_workspace_session.dart';

/// Development-only binding: real OBS scenes plus explicitly simulated chat.
/// Reuses the prototype's local focus/chat fixture, not a production chat adapter.
class LiveWorkspaceModel extends WorkspaceModel {
  LiveWorkspaceModel({required this.host, this.port = 4455}) {
    hasSavedConnection = false;
    _session.addListener(_sync);
    _sync();
  }

  final String host;
  final int port;
  final _session = ObsWorkspaceSession();

  @override
  bool get isLiveObs => true;
  @override
  bool get hasAudioControls => false;
  @override
  List<SourceControl> get sourceControls =>
      _session.sources?.controls ?? const [];
  @override
  bool get sourcesReady => _session.sources?.ready ?? false;
  @override
  String? get sourceProblem => _session.sources?.problem;
  @override
  Future<void> refreshSources() async => _session.sources?.refresh();
  @override
  Future<void> setSourceEnabled(ObsSourceTarget target, bool enabled) async =>
      _session.sources?.setEnabled(target, enabled);
  @override
  bool get obsStateFresh => _session.scenes?.phase == ObsScenePhase.ready;
  @override
  String get connectionName => '$host:$port';
  @override
  String? get connectionProblem => _session.failure?.userMessage;
  @override
  List<String> get scenes => _session.scenes?.scenes ?? const [];
  @override
  bool get canControl => _session.scenes?.canCommand ?? false;

  void _sync() {
    final state = _session.scenes;
    connection = _session.connecting
        ? ObsConnection.connecting
        : _session.failure?.isAuthenticationFailure == true
        ? ObsConnection.failed
        : switch (state?.phase) {
            ObsScenePhase.ready ||
            ObsScenePhase.unavailable => ObsConnection.connected,
            ObsScenePhase.synchronizing => ObsConnection.connecting,
            _ => ObsConnection.disconnected,
          };
    program = state?.program ?? 'Unknown';
    preview = state?.preview ?? 'Not available';
    studioMode = state?.studioMode ?? false;
    inspectedScene = state?.inspected ?? 'No scene selected';
    pendingCommand = state?.commandPending == true ? 'Scene command' : null;
    commandError = state?.feedback;
    notifyListeners();
  }

  @override
  Future<void> connect({String password = ''}) {
    return _session.connect(Connection(host, port, password));
  }

  @override
  void disconnect() => _session.disconnect();
  @override
  void inspect(String scene) => _session.scenes?.inspect(scene);
  @override
  Future<void> setPreview() async =>
      _session.scenes?.previewScene(inspectedScene);
  @override
  Future<void> takeScene() async {
    final scenes = _session.scenes;
    if (scenes == null) return;
    if (scenes.studioMode) {
      await scenes.take();
    } else if (scenes.inspected != null) {
      await scenes.sendScene(scenes.inspected!);
    }
  }

  @override
  Future<void> refreshObs() async => _session.scenes?.refresh();

  // Unsupported fixture commands must never appear to change real OBS.
  @override
  void setStudioMode(bool value) {}
  @override
  void setScenario(LabScenario scenario) {}
  @override
  void simulateExternalChange() {}
  @override
  Future<void> toggleMute() async {}
  @override
  Future<void> setVolume(double value) async {}
  @override
  Future<void> toggleSource() async {}

  @override
  void dispose() {
    _session.removeListener(_sync);
    _session.dispose();
    super.dispose();
  }
}
