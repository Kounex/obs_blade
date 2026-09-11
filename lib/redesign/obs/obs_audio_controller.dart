import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../types/classes/api/input.dart';
import '../../types/classes/stream/events/base.dart';
import '../../types/enums/request_type.dart';
import '../../types/enums/web_socket_codes/request_status.dart';
import '../../types/interfaces/message.dart';
import '../workspace/audio_input_control.dart';
import 'obs_request_client.dart';

/// Global OBS input controls. Audio capability comes from OBS, not input names
/// or kinds. Each input has independent pending actions and confirmed values.
class ObsAudioController extends ChangeNotifier {
  ObsAudioController(this._client) {
    _subscription = _client.events.listen(_event, onDone: _offline);
  }

  final ObsRequestClient _client;
  late final StreamSubscription<Message> _subscription;
  Map<String, _Entry> _entries = {};
  final _busy = <String>{};
  final _queuedVolume = <String, double>{};
  final _errors = <String, String>{};
  final _muteEvents = <String, (int, bool)>{};
  final _volumeEvents = <String, (int, double)>{};
  Future<void> _refreshing = Future.value();
  String? _problem;
  bool _ready = false;
  bool _suspended = false;
  bool _disposed = false;
  int _generation = 0;
  int _load = 0;
  int _sequence = 0;

  bool get ready => _ready;
  String? get problem => _problem;
  List<AudioInputControl> get controls => List.unmodifiable(
    _entries.entries.map((e) {
      return AudioInputControl(
        name: e.key,
        volume: e.value.input.inputVolumeMul,
        muted: e.value.input.inputMuted,
        fresh: _ready && e.value.fresh,
        busy: _busy.contains(e.key),
        pendingVolume: _queuedVolume[e.key],
        error: _errors[e.key],
      );
    }),
  );

  Future<void> refresh() => _refreshing = _loadInputs();

  Future<void> _loadInputs() async {
    if (_disposed || _suspended || _client.isClosed) return;
    final load = ++_load;
    _ready = false;
    _problem = null;
    _changed();
    try {
      final result = await _client.request(RequestType.GetInputList);
      if (_disposed || load != _load) return;
      if (!result.accepted) throw StateError('Input list failed');
      final inputs = (result.data['inputs'] as List)
          .map((data) => Input.fromJson(Map<String, Object?>.from(data as Map)))
          .toList();
      if (inputs.any((input) => input.inputName == null)) {
        throw StateError('Missing input identity');
      }
      final results = await Future.wait(inputs.map(_readInput));
      if (_disposed || load != _load) return;
      _entries = {
        for (final entry in results.nonNulls)
          entry.input.inputName!: _withLatestEvents(entry),
      };
      _ready = true;
      if (_entries.values.any((entry) => !entry.fresh)) {
        _problem = 'Some audio inputs are unavailable. Refresh to check them.';
      }
    } catch (_) {
      if (_disposed || load != _load) return;
      _problem = 'Could not refresh OBS audio. Refresh to try again.';
    }
    _changed();
  }

  Future<_Entry?> _readInput(Input input) async {
    final name = input.inputName!;
    final fields = {'inputName': name};
    final muteSequence = _sequence;
    final muteFuture = _client.request(RequestType.GetInputMute, fields);
    final volumeSequence = _sequence;
    final volumeFuture = _client.request(RequestType.GetInputVolume, fields);
    final results = await Future.wait([muteFuture, volumeFuture]);
    // OBS's GetInputMute uses InvalidResourceState for non-audio inputs.
    if (results[0].outcome == ObsRequestOutcome.rejected &&
        results[0].code == RequestStatus.InvalidResourceState.identifier) {
      return null;
    }
    try {
      if (results.any((result) => !result.accepted)) {
        throw StateError('Audio read failed');
      }
      final muted = results[0].data['inputMuted'] as bool;
      final volume = (results[1].data['inputVolumeMul'] as num).toDouble();
      if (!volume.isFinite || volume < 0 || volume > 20) {
        throw StateError('Invalid audio volume');
      }
      return _withLatestEvents(
        _Entry(
          input.copyWith(inputMuted: muted, inputVolumeMul: volume),
          true,
          muteSequence,
          volumeSequence,
        ),
      );
    } catch (_) {
      return _Entry(
        _entries[name]?.input ?? input,
        false,
        muteSequence,
        volumeSequence,
      );
    }
  }

  _Entry _withLatestEvents(_Entry entry) {
    final name = entry.input.inputName!;
    final mute = _muteEvents[name];
    final volume = _volumeEvents[name];
    return _Entry(
      entry.input.copyWith(
        inputMuted: mute != null && mute.$1 > entry.muteSequence
            ? mute.$2
            : entry.input.inputMuted,
        inputVolumeMul: volume != null && volume.$1 > entry.volumeSequence
            ? volume.$2
            : entry.input.inputVolumeMul,
      ),
      entry.fresh,
      entry.muteSequence,
      entry.volumeSequence,
    );
  }

  Future<void> setMuted(String name, bool muted) => _command(
    name,
    RequestType.SetInputMute,
    {'inputName': name, 'inputMuted': muted},
  );

  Future<void> setVolume(String name, double volume) async {
    if (!volume.isFinite || volume < 0 || volume > 20) return;
    await _command(name, RequestType.SetInputVolume, {
      'inputName': name,
      'inputVolumeMul': volume,
    });
  }

  Future<void> _command(
    String name,
    RequestType type,
    Map<String, dynamic> fields,
  ) async {
    if (!_ready || _entries[name]?.fresh != true || _busy.contains(name)) {
      return;
    }
    final generation = _generation;
    _busy.add(name);
    _errors.remove(name);
    if (type == RequestType.SetInputVolume) {
      _queuedVolume[name] = fields['inputVolumeMul'] as double;
    }
    _changed();
    final result = await _client.request(type, fields);
    if (_disposed || generation != _generation) return;
    if (!result.accepted) {
      _errors[name] = result.outcome == ObsRequestOutcome.rejected
          ? 'OBS rejected this audio change.'
          : 'No confirmation. Check this input before trying again.';
      _changed();
    }
    // Let an in-progress discovery finish, then confirm this input specifically.
    // A later discovery supersedes this read rather than being overwritten by it.
    await _refreshing;
    if (_disposed || generation != _generation) return;
    final load = _load;
    final input = _entries[name]?.input;
    if (input != null) {
      final confirmed = await _readInput(input);
      if (_disposed || generation != _generation) return;
      if (load == _load) {
        if (confirmed == null) {
          _entries.remove(name);
        } else {
          _entries[name] = _withLatestEvents(confirmed);
        }
      }
    }
    _busy.remove(name);
    _queuedVolume.remove(name);
    _changed();
  }

  void _event(Message message) {
    if (_disposed || message is! BaseEvent) return;
    final data = message.json;
    switch (message.jsonRAW['d']['eventType']) {
      case 'InputMuteStateChanged':
        final name = data['inputName'] as String;
        _muteEvents[name] = (++_sequence, data['inputMuted'] as bool);
        final entry = _entries[name];
        if (entry != null) _entries[name] = _withLatestEvents(entry);
      case 'InputVolumeChanged':
        final name = data['inputName'] as String;
        _volumeEvents[name] = (
          ++_sequence,
          (data['inputVolumeMul'] as num).toDouble(),
        );
        final entry = _entries[name];
        if (entry != null) _entries[name] = _withLatestEvents(entry);
      case 'CurrentSceneCollectionChanging':
        _invalidate();
        _suspended = true;
      case 'CurrentSceneCollectionChanged':
        _suspended = false;
        unawaited(refresh());
      case 'InputCreated':
      case 'InputRemoved':
      case 'InputNameChanged':
        _invalidate();
        unawaited(refresh());
      default:
        return;
    }
    _changed();
  }

  void _invalidate() {
    _generation++;
    _load++;
    _ready = false;
    _entries = {};
    _busy.clear();
    _queuedVolume.clear();
    _errors.clear();
    _muteEvents.clear();
    _volumeEvents.clear();
  }

  void _offline() {
    if (_disposed) return;
    _invalidate();
    _problem = 'OBS disconnected.';
    _changed();
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _invalidate();
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

class _Entry {
  const _Entry(this.input, this.fresh, this.muteSequence, this.volumeSequence);
  final Input input;
  final bool fresh;
  final int muteSequence;
  final int volumeSequence;
}
