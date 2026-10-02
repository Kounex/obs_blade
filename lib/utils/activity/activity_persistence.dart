import 'dart:convert';

import 'package:hive_ce/hive.dart';

import '../../types/classes/activity/activity_event.dart';
import '../../types/enums/hive_keys.dart';
import '../general_helper.dart';

/// Where the activity feed keeps its rows and bookkeeping. Two untyped
/// boxes of JSON strings - no TypeID, no adapter, so a schema change can
/// never make Hive fail to open them (`docs/persistence-risk.md`).
abstract class ActivityPersistence {
  Future<void> open();
  Iterable<ActivityEvent> loadEvents();
  Object? loadMeta(String key);
  Future<void> putEvent(ActivityEvent event);
  Future<void> deleteEvents(Iterable<String> ids);
  Future<void> putMeta(String key, Object? value);
  Future<void> clearEvents();
}

class HiveActivityPersistence implements ActivityPersistence {
  Box<String>? _events;
  Box<String>? _meta;

  @override
  Future<void> open() async {
    this._events ??= await Hive.openBox<String>(
      HiveKeys.ActivityEvents.name,
      compactionStrategy: (entries, deletedEntries) => deletedEntries > 200,
    );
    this._meta ??= await Hive.openBox<String>(HiveKeys.ActivityMeta.name);
  }

  @override
  Iterable<ActivityEvent> loadEvents() sync* {
    final box = this._events;
    if (box == null) return;
    for (final raw in box.values) {
      try {
        final event = ActivityEvent.fromJson(json.decode(raw));
        if (event != null) yield event;
      } catch (e) {
        GeneralHelper.advLog('Activity feed: unreadable row skipped - $e');
      }
    }
  }

  @override
  Object? loadMeta(String key) {
    final raw = this._meta?.get(key);
    if (raw == null) return null;
    try {
      return json.decode(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> putEvent(ActivityEvent event) async =>
      this._events?.put(event.id, json.encode(event.toJson()));

  @override
  Future<void> deleteEvents(Iterable<String> ids) async =>
      this._events?.deleteAll(ids.toList());

  @override
  Future<void> putMeta(String key, Object? value) async {
    final box = this._meta;
    if (box == null) return;
    if (value == null) {
      await box.delete(key);
    } else {
      await box.put(key, json.encode(value));
    }
  }

  @override
  Future<void> clearEvents() async => this._events?.clear();
}

/// Test / preview double.
class MemoryActivityPersistence implements ActivityPersistence {
  final Map<String, String> events = {};
  final Map<String, String> meta = {};

  @override
  Future<void> open() async {}

  @override
  Iterable<ActivityEvent> loadEvents() => [
    for (final raw in this.events.values)
      ?ActivityEvent.fromJson(json.decode(raw)),
  ];

  @override
  Object? loadMeta(String key) {
    final raw = this.meta[key];
    return raw == null ? null : json.decode(raw);
  }

  @override
  Future<void> putEvent(ActivityEvent event) async =>
      this.events[event.id] = json.encode(event.toJson());

  @override
  Future<void> deleteEvents(Iterable<String> ids) async =>
      ids.forEach(this.events.remove);

  @override
  Future<void> putMeta(String key, Object? value) async {
    if (value == null) {
      this.meta.remove(key);
    } else {
      this.meta[key] = json.encode(value);
    }
  }

  @override
  Future<void> clearEvents() async => this.events.clear();
}
