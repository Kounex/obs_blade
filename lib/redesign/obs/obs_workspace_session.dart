import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/connection.dart';
import '../../stores/shared/network.dart';
import '../../types/classes/connection_attempt_result.dart';
import '../../utils/network_helper.dart';
import 'obs_request_client.dart';
import 'obs_audio_controller.dart';
import 'obs_scene_controller.dart';
import 'obs_source_controller.dart';

/// Volatile session owner for the isolated live lab. Each attempt has its own
/// NetworkStore so completion of an old handshake cannot touch a newer socket.
/// No global DI, persisted connection, DashboardStore or chat lifetime is owned.
class ObsWorkspaceSession extends ChangeNotifier {
  NetworkStore? _network;
  ObsRequestClient? _client;
  ObsSceneController? _scenes;
  ObsSourceController? _sources;
  ObsAudioController? _audio;
  Future<void> _sourceLoad = Future.value();
  bool _connecting = false;
  bool _disposed = false;
  int _attempt = 0;
  ConnectionAttemptResult? _failure;

  ObsSceneController? get scenes => _scenes;
  ObsSourceController? get sources => _sources;
  ObsAudioController? get audio => _audio;
  bool get connecting => _connecting;
  ConnectionAttemptResult? get failure => _failure;

  Future<void> connect(
    Connection connection, {
    Duration timeout = kObsHandshakeTimeout,
  }) async {
    if (_disposed) return;
    final attempt = ++_attempt;
    _retire();
    final network = NetworkStore();
    _network = network;
    _failure = null;
    _connecting = true;
    notifyListeners();
    await network.setOBSWebSocket(connection, timeout: timeout);
    if (_disposed || attempt != _attempt) {
      network.closeSession();
      return;
    }
    _connecting = false;
    final result = network.lastConnectionResult;
    final session = network.activeSession;
    if (result?.isSuccess != true || session == null) {
      _failure = result;
      network.closeSession();
      notifyListeners();
      return;
    }
    final client = ObsRequestClient(
      messages: network.watchOBSStream(),
      send: (id, type, data) => NetworkHelper.makeRequest(
        session.socket,
        type,
        {'requestType': type.name, 'requestId': id, 'requestData': data},
        true,
      ),
    );
    _client = client;
    final scenes = ObsSceneController(client)..addListener(_sceneChanged);
    _scenes = scenes;
    _sources = ObsSourceController(client)..addListener(_changed);
    final audio = ObsAudioController(client)..addListener(_changed);
    _audio = audio;
    final audioLoad = audio.refresh();
    notifyListeners();
    await scenes.refresh();
    if (_disposed || attempt != _attempt) return;
    await Future.wait([_sourceLoad, audioLoad]);
  }

  void disconnect() {
    if (_disposed) return;
    _attempt++;
    _retire();
    _connecting = false;
    _failure = null;
    notifyListeners();
  }

  void _sceneChanged() {
    final scenes = _scenes;
    final sources = _sources;
    if (scenes?.phase == ObsScenePhase.ready &&
        sources != null &&
        sources.scene != scenes!.inspected) {
      _sourceLoad = sources.selectScene(scenes.inspected);
      unawaited(_sourceLoad);
    }
    _changed();
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void _retire() {
    _scenes?.removeListener(_sceneChanged);
    _scenes?.dispose();
    _scenes = null;
    _sources?.removeListener(_changed);
    _sources?.dispose();
    _sources = null;
    _audio?.removeListener(_changed);
    _audio?.dispose();
    _audio = null;
    _sourceLoad = Future.value();
    _client?.close();
    _client = null;
    _network?.closeSession();
    _network = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _attempt++;
    _retire();
    super.dispose();
  }
}
