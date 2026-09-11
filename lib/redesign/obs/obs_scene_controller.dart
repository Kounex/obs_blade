import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../types/classes/api/scene.dart';
import '../../types/classes/stream/events/base.dart';
import '../../types/enums/request_type.dart';
import '../../types/interfaces/message.dart';
import 'obs_request_client.dart';

enum ObsScenePhase { synchronizing, ready, unavailable, offline }

/// Confirmed scene projection for a single identified OBS connection. This
/// bounded adapter does not own chat, settings, DashboardStore or the socket.
class ObsSceneController extends ChangeNotifier {
  ObsSceneController(this._client) {
    _subscription = _client.events.listen(_event, onDone: _disconnected);
  }

  final ObsRequestClient _client;
  late final StreamSubscription<Message> _subscription;
  ObsScenePhase _phase = ObsScenePhase.synchronizing;
  List<String> _scenes = const [];
  String? _program;
  String? _preview;
  String? _inspected;
  bool _studioMode = false;
  bool _pending = false;
  String? _feedback;
  int _epoch = 0;
  int _refresh = 0;
  int _programRevision = 0;
  int _previewRevision = 0;
  int _studioRevision = 0;
  bool _disposed = false;
  bool _collectionChanging = false;

  ObsScenePhase get phase => _phase;
  List<String> get scenes => _scenes;
  String? get program => _program;
  String? get preview => _preview;
  String? get inspected => _inspected;
  bool get studioMode => _studioMode;
  bool get commandPending => _pending;
  String? get feedback => _feedback;
  bool get canCommand => _phase == ObsScenePhase.ready && !_pending;

  void inspect(String scene) {
    if (!_scenes.contains(scene)) return;
    _inspected = scene;
    _changed();
  }

  Future<void> refresh() async {
    if (_disposed || _client.isClosed || _collectionChanging) return;
    final epoch = _epoch;
    final refresh = ++_refresh;
    final programRevision = _programRevision;
    final previewRevision = _previewRevision;
    final studioRevision = _studioRevision;
    final results = await Future.wait([
      _client.request(RequestType.GetSceneList),
      _client.request(RequestType.GetStudioModeEnabled),
    ]);
    if (_disposed || epoch != _epoch || refresh != _refresh) return;
    if (results.any((result) => !result.accepted)) {
      _phase = _client.isClosed
          ? ObsScenePhase.offline
          : ObsScenePhase.unavailable;
      _feedback =
          'Could not refresh OBS state. Refresh before sending a scene.';
      _changed();
      return;
    }
    try {
      final sceneData = results[0].data;
      final sceneObjects =
          (sceneData['scenes'] as List)
              .map(
                (scene) =>
                    Scene.fromJson(Map<String, Object?>.from(scene as Map)),
              )
              .toList()
            ..sort((a, b) => b.sceneIndex.compareTo(a.sceneIndex));
      final scenes = sceneObjects.map((scene) => scene.sceneName).toList();
      final program = sceneData['currentProgramSceneName'] as String;
      final preview = sceneData['currentPreviewSceneName'] as String?;
      final studioMode = results[1].data['studioModeEnabled'] as bool;
      _scenes = List.unmodifiable(scenes);
      if (programRevision == _programRevision) _program = program;
      if (previewRevision == _previewRevision) _preview = preview;
      if (studioRevision == _studioRevision) _studioMode = studioMode;
      if (!_scenes.contains(_inspected)) {
        _inspected = _scenes.contains(_program)
            ? _program
            : _scenes.firstOrNull;
      }
      _phase = ObsScenePhase.ready;
    } catch (_) {
      _phase = ObsScenePhase.unavailable;
      _feedback =
          'OBS returned incomplete scene information. Refresh to retry.';
    }
    _changed();
  }

  Future<void> previewScene(String scene) async {
    if (!canCommand || !_studioMode || !_scenes.contains(scene)) return;
    await _command(RequestType.SetCurrentPreviewScene, {'sceneName': scene});
  }

  Future<void> sendScene(String scene) async {
    if (!canCommand || _studioMode || !_scenes.contains(scene)) return;
    await _command(RequestType.SetCurrentProgramScene, {'sceneName': scene});
  }

  Future<void> take() async {
    if (!canCommand || !_studioMode || !_scenes.contains(_preview)) return;
    await _command(RequestType.TriggerStudioModeTransition, const {});
  }

  Future<void> _command(RequestType type, Map<String, dynamic> data) async {
    final epoch = _epoch;
    _pending = true;
    _feedback = null;
    _changed();
    final result = await _client.request(type, data);
    if (_disposed || epoch != _epoch) return;
    _feedback = switch (result.outcome) {
      ObsRequestOutcome.accepted => null,
      ObsRequestOutcome.rejected =>
        'OBS rejected the command (${result.code}).',
      ObsRequestOutcome.timedOut =>
        'No reply from OBS. The action may have happened; refreshing state.',
      ObsRequestOutcome.disconnected =>
        'OBS disconnected. Check its output before trying the action again.',
    };
    _changed();
    // Acknowledgements never assign program/preview. Re-read even on rejection:
    // another operator may have changed OBS while this request was in flight.
    await refresh();
    if (_disposed || epoch != _epoch) return;
    _pending = false;
    _changed();
  }

  void _event(Message message) {
    if (_disposed || message is! BaseEvent) return;
    switch (message.jsonRAW['d']['eventType']) {
      case 'CurrentProgramSceneChanged':
        _programRevision++;
        _program = message.json['sceneName'] as String;
      case 'CurrentPreviewSceneChanged':
        _previewRevision++;
        _preview = message.json['sceneName'] as String;
      case 'StudioModeStateChanged':
        _studioRevision++;
        _studioMode = message.json['studioModeEnabled'] as bool;
        _previewRevision++;
        _preview = null;
        _phase = ObsScenePhase.synchronizing;
        unawaited(refresh());
      case 'CurrentSceneCollectionChanging':
        _collectionChanging = true;
        _epoch++;
        _pending = false;
        _phase = ObsScenePhase.synchronizing;
        _scenes = const [];
        _program = _preview = _inspected = null;
        _feedback = 'OBS is changing scene collections.';
      case 'CurrentSceneCollectionChanged':
        _collectionChanging = false;
        _feedback = null;
        _epoch++;
        _pending = false;
        _phase = ObsScenePhase.synchronizing;
        unawaited(refresh());
      case 'SceneListChanged':
      case 'SceneNameChanged':
        if (_collectionChanging) return;
        _feedback = null;
        _epoch++;
        _pending = false;
        _phase = ObsScenePhase.synchronizing;
        unawaited(refresh());
      default:
        return;
    }
    _changed();
  }

  void _disconnected() {
    if (_disposed) return;
    _epoch++;
    _pending = false;
    _phase = ObsScenePhase.offline;
    _feedback = 'OBS disconnected. Displayed values are the last known state.';
    _changed();
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
