import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../types/classes/api/scene_item.dart';
import '../../types/classes/stream/events/base.dart';
import '../../types/enums/request_type.dart';
import '../../types/interfaces/message.dart';
import '../workspace/source_control.dart';
import 'obs_request_client.dart';

/// Visibility in the locally inspected scene. Owns neither scene output nor
/// audio; mutations are scoped to (owner scene/group, item ID).
class ObsSourceController extends ChangeNotifier {
  ObsSourceController(this._client) {
    _subscription = _client.events.listen(_event, onDone: _offline);
  }

  final ObsRequestClient _client;
  late final StreamSubscription<Message> _subscription;
  List<_Entry> _entries = const [];
  final _busy = <ObsSourceTarget>{};
  final _errors = <ObsSourceTarget, String>{};
  final _events = <ObsSourceTarget, (int, bool)>{};
  String? _scene;
  String? _problem;
  bool _ready = false;
  bool _suspended = false;
  bool _disposed = false;
  int _load = 0;
  int _collection = 0;
  int _eventSequence = 0;

  String? get scene => _scene;
  bool get ready => _ready;
  String? get problem => _problem;
  List<SourceControl> get controls => List.unmodifiable(
    _entries.map((entry) {
      return SourceControl(
        target: entry.target,
        name: entry.item.sourceName!,
        depth: entry.parents.length,
        isGroup: entry.item.isGroup == true,
        enabled: entry.item.sceneItemEnabled,
        hiddenByGroup: entry.parents.any(
          (parent) => _entries.any(
            (e) => e.target == parent && e.item.sceneItemEnabled == false,
          ),
        ),
        canChange:
            _ready &&
            !_busy.contains(entry.target) &&
            entry.item.sceneItemEnabled != null,
        busy: _busy.contains(entry.target),
        error: _errors[entry.target],
      );
    }),
  );

  Future<void> selectScene(String? scene) async {
    if (_disposed || scene == _scene) return;
    _load++;
    _scene = scene;
    _entries = const [];
    _events.clear();
    _ready = false;
    _problem = null;
    _changed();
    if (scene != null) await refresh();
  }

  Future<void> refresh() async {
    final scene = _scene;
    if (_disposed || _suspended || _client.isClosed || scene == null) return;
    final load = ++_load;
    _ready = false;
    _problem = null;
    _changed();
    try {
      final entries = await _readOwner(scene, false, const [], const {}, load);
      if (_disposed || load != _load) return;
      _entries = entries;
      _ready = true;
    } catch (_) {
      if (_disposed || load != _load) return;
      _problem = 'Could not refresh source visibility. Refresh to try again.';
    }
    _changed();
  }

  Future<List<_Entry>> _readOwner(
    String owner,
    bool group,
    List<ObsSourceTarget> parents,
    Set<String> ancestors,
    int load,
  ) async {
    if (ancestors.contains(owner)) throw StateError('Cyclic group');
    final sequence = _eventSequence;
    final result = await _client.request(
      group ? RequestType.GetGroupSceneItemList : RequestType.GetSceneItemList,
      {'sceneName': owner},
    );
    if (_disposed || load != _load) return const [];
    if (!result.accepted) throw StateError('Source read failed');
    final items =
        (result.data['sceneItems'] as List)
            .map(
              (item) =>
                  SceneItem.fromJson(Map<String, Object?>.from(item as Map)),
            )
            .toList()
          ..sort(
            (a, b) => (b.sceneItemIndex ?? 0).compareTo(a.sceneItemIndex ?? 0),
          );
    final branches = await Future.wait(
      items.map((item) async {
        if (item.sceneItemId == null || item.sourceName == null) {
          throw StateError('Incomplete source identity');
        }
        final target = (owner: owner, id: item.sceneItemId!);
        final event = _events[target];
        final confirmed = event != null && event.$1 > sequence
            ? item.copyWith(sceneItemEnabled: event.$2)
            : item;
        return [
          _Entry(target, confirmed, parents, sequence),
          if (item.isGroup == true)
            ...await _readOwner(
              item.sourceName!,
              true,
              [...parents, target],
              {...ancestors, owner},
              load,
            ),
        ];
      }),
    );
    // A parent may receive an event while child groups are being fetched.
    return branches.expand((branch) => branch).map((entry) {
      final event = _events[entry.target];
      return event != null && event.$1 > entry.readSequence
          ? entry.withEnabled(event.$2)
          : entry;
    }).toList();
  }

  Future<void> setEnabled(ObsSourceTarget target, bool enabled) async {
    if (!_ready ||
        _busy.contains(target) ||
        !_entries.any(
          (entry) =>
              entry.target == target && entry.item.sceneItemEnabled != null,
        )) {
      return;
    }
    final collection = _collection;
    final scene = _scene;
    _busy.add(target);
    _errors.remove(target);
    _changed();
    final result = await _client.request(RequestType.SetSceneItemEnabled, {
      'sceneName': target.owner,
      'sceneItemId': target.id,
      'sceneItemEnabled': enabled,
    });
    if (_disposed || collection != _collection) return;
    if (!result.accepted) {
      _errors[target] = result.outcome == ObsRequestOutcome.rejected
          ? 'OBS rejected this visibility change.'
          : 'No confirmation. Check source visibility before trying again.';
    }
    // Never assign the requested value on acknowledgement, or refresh an
    // unrelated newly inspected scene because an earlier command completed.
    if (scene == _scene) await refresh();
    if (_disposed || collection != _collection) return;
    _busy.remove(target);
    _changed();
  }

  void _event(Message message) {
    if (_disposed || message is! BaseEvent) return;
    final data = message.json;
    switch (message.jsonRAW['d']['eventType']) {
      case 'SceneItemEnableStateChanged':
        final target = (
          owner: data['sceneName'] as String,
          id: data['sceneItemId'] as int,
        );
        final enabled = data['sceneItemEnabled'] as bool;
        _events[target] = (++_eventSequence, enabled);
        _entries = _entries
            .map(
              (entry) =>
                  entry.target == target ? entry.withEnabled(enabled) : entry,
            )
            .toList();
      case 'CurrentSceneCollectionChanging':
        _invalidate();
        _suspended = true;
      case 'CurrentSceneCollectionChanged':
        _suspended = false;
      case 'SceneItemCreated':
      case 'SceneItemRemoved':
      case 'SceneItemListReindexed':
        if (data['sceneName'] == _scene ||
            _entries.any((entry) => entry.target.owner == data['sceneName'])) {
          unawaited(refresh());
        }
      case 'InputNameChanged':
        unawaited(refresh());
      default:
        return;
    }
    _changed();
  }

  void _invalidate() {
    _collection++;
    _load++;
    _ready = false;
    _scene = null;
    _entries = const [];
    _events.clear();
    _busy.clear();
    _errors.clear();
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
  const _Entry(this.target, this.item, this.parents, this.readSequence);
  final ObsSourceTarget target;
  final SceneItem item;
  final List<ObsSourceTarget> parents;
  final int readSequence;

  _Entry withEnabled(bool enabled) => _Entry(
    target,
    item.copyWith(sceneItemEnabled: enabled),
    parents,
    readSequence,
  );
}
