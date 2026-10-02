import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/stores/views/activity.dart';
import 'package:obs_blade/types/classes/activity/activity_event.dart';
import 'package:obs_blade/utils/activity/activity_persistence.dart';
import 'package:obs_blade/utils/kick/kick_events_relay_client.dart';

class _NoRelay extends KickEventsRelayClient {
  @override
  Future<void> stop() async {}
}

ActivityEvent _event(
  String id, {
  ActivityKind kind = ActivityKind.sub,
  ActivityPlatform platform = ActivityPlatform.twitch,
  String channel = '1',
  String actor = 'Fan',
  ActivityAmount? amount,
  required DateTime at,
  ActivitySource source = ActivitySource.native,
}) => ActivityEvent(
  id: id,
  platform: platform,
  channelId: channel,
  kind: kind,
  actor: ActivityActor(
    id: actor.toLowerCase(),
    login: actor.toLowerCase(),
    name: actor,
  ),
  amount: amount,
  timestamp: at,
  sources: {source: id},
  primarySource: source,
);

void main() {
  late MemoryActivityPersistence persistence;
  late DateTime now;
  late ActivityStore store;

  ActivityStore build() => ActivityStore(
    persistence: persistence,
    isProResolver: () => true,
    clock: () => now,
    relayClient: _NoRelay(),
    relayEnabledResolver: () => true,
    attachPlatformStores: false,
  );

  setUp(() async {
    persistence = MemoryActivityPersistence();
    now = DateTime.utc(2026, 10, 2, 20);
    store = build();
    await store.init();
  });

  tearDown(() => store.dispose());

  test('rows survive a restart with seq, seen marks and thanked', () async {
    store.ingest(_event('a', at: now));
    store.ingest(_event('b', at: now, actor: 'Other'));
    store.setThanked(store.allEvents.firstWhere((e) => e.id == 'a'), true);
    store.markAllSeen();
    await store.dispose();

    store = build();
    await store.init();
    expect(store.allEvents.map((e) => e.id), containsAll(['a', 'b']));
    expect(store.allEvents.firstWhere((e) => e.id == 'a').thanked, isTrue);
    expect(store.unseenCount, 0);

    store.ingest(_event('c', at: now, actor: 'Third'));
    expect(store.allEvents.firstWhere((e) => e.id == 'c').seq, 3);
    expect(store.unseenCount, 1);
  });

  test('events arriving before init are kept', () async {
    final early = build();
    early.ingest(_event('early', at: now));
    expect(early.allEvents, isEmpty);
    await early.init();
    expect(early.allEvents.single.id, 'early');
    await early.dispose();
  });

  test('visit: divider holds still, leaving marks everything seen', () {
    store.ingest(_event('a', at: now));
    expect(store.unseenCount, 1);
    store.beginVisit();
    final a = store.allEvents.single;
    expect(store.isNew(a), isTrue);

    /// Arrives while the feed is open - new as well, the old one stays new
    store.ingest(
      _event('b', at: now.add(const Duration(seconds: 5)), actor: 'B'),
    );
    expect(store.isNew(store.allEvents.first), isTrue);
    expect(store.isNew(a), isTrue);

    store.endVisit();
    expect(store.unseenCount, 0);
    expect(store.allEvents.any(store.isNew), isFalse);
  });

  test('visits are counted: the divider holds until the last feed leaves', () {
    store.ingest(_event('a', at: now));
    store.beginVisit();
    store.beginVisit();
    store.endVisit();
    expect(store.unseenCount, 1);
    expect(store.visitMarks, isNotNull);
    store.endVisit();
    expect(store.unseenCount, 0);
    store.endVisit(); // extra end is ignored
    expect(store.visitMarks, isNull);
  });

  test(
    'a feed opened before the marks loaded gets the loaded snapshot',
    () async {
      store.ingest(_event('a', at: now));
      store.markAllSeen();
      await store.dispose();
      store = build();
      store.beginVisit();
      await store.init();
      expect(store.allEvents.any(store.isNew), isFalse);
      store.endVisit();
    },
  );

  test('hype trains are not in the to-thank queue', () {
    store.ingest(_event('h', kind: ActivityKind.hypeTrain, at: now));
    expect(store.toThankCount, 0);
  });

  test('delete all data forgets rows, sessions and marks', () async {
    store.ingest(_event('a', at: now));
    store.setLiveForTest('twitch', true);
    await store.deleteAllData();
    expect(store.allEvents, isEmpty);
    expect(store.sessions, isEmpty);
    expect(persistence.events, isEmpty);
    expect(persistence.meta.containsKey('sessions'), isFalse);
  });

  test('backfilled old rows still count as new (seq, not time)', () {
    store.ingest(_event('fresh', at: now));
    store.markAllSeen();
    store.ingest(
      _event('old', at: now.subtract(const Duration(hours: 3)), actor: 'Late'),
    );
    expect(store.unseenCount, 1);
    expect(store.isNew(store.allEvents.last), isTrue);
  });

  test('to-thank: big rows only, thanked ones leave the queue', () {
    store.ingest(_event('sub', at: now));
    store.ingest(
      _event('follow', kind: ActivityKind.follow, at: now, actor: 'F'),
    );
    store.ingest(
      _event(
        'cheer',
        kind: ActivityKind.cheer,
        amount: const ActivityAmount(500, ActivityUnit.bits),
        at: now,
        actor: 'C',
      ),
    );
    expect(store.toThankCount, 2);
    store.setToThankOnly(true);
    expect(
      store.visibleEvents.map((e) => e.id),
      unorderedEquals(['sub', 'cheer']),
    );
    store.setThanked(store.allEvents.firstWhere((e) => e.id == 'sub'), true);
    expect(store.toThankCount, 1);
    expect(store.visibleEvents.map((e) => e.id), ['cheer']);
  });

  test('filters', () {
    store.ingest(_event('sub', at: now));
    store.ingest(
      _event('follow', kind: ActivityKind.follow, at: now, actor: 'F'),
    );
    store.ingest(
      _event(
        'sc',
        kind: ActivityKind.superChat,
        platform: ActivityPlatform.youtube,
        amount: const ActivityAmount(5, 'USD'),
        at: now,
        actor: 'S',
      ),
    );
    store.ingest(_event('raid', kind: ActivityKind.raid, at: now, actor: 'R'));
    store.setFilter(ActivityFilter.money);
    expect(store.visibleEvents.map((e) => e.id), ['sc']);
    store.setFilter(ActivityFilter.follows);
    expect(store.visibleEvents.map((e) => e.id), ['follow']);
    store.setFilter(ActivityFilter.raids);
    expect(store.visibleEvents.map((e) => e.id), ['raid']);
    store.setFilter(ActivityFilter.subs);
    expect(store.visibleEvents.map((e) => e.id), ['sub']);
  });

  group('sessions', () {
    test('live opens a session, rows group under it with totals', () {
      store.setLiveForTest('twitch', true);
      expect(store.currentSession, isNotNull);
      now = now.add(const Duration(minutes: 30));
      store.ingest(_event('sub', at: now));
      store.ingest(
        _event(
          'cheer',
          kind: ActivityKind.cheer,
          amount: const ActivityAmount(100, ActivityUnit.bits),
          at: now,
          actor: 'C',
        ),
      );
      store.ingest(
        _event(
          'cheer2',
          kind: ActivityKind.cheer,
          amount: const ActivityAmount(250, ActivityUnit.bits),
          at: now,
          actor: 'D',
        ),
      );
      final group = store.groups.single;
      expect(group.session, isNotNull);
      expect(group.totals.amounts[ActivityUnit.bits], 350);
      expect(group.totals.subs, 1);
    });

    test('short drop keeps the session, a long one starts a new one', () {
      store.setLiveForTest('kick', true);
      final first = store.currentSession!;
      now = now.add(const Duration(hours: 1));
      store.setLiveForTest('kick', false);
      expect(store.currentSession, isNull);
      now = now.add(const Duration(minutes: 5));
      store.setLiveForTest('kick', true);
      expect(store.currentSession!.id, first.id);
      now = now.add(const Duration(hours: 1));
      store.setLiveForTest('kick', false);
      now = now.add(const Duration(hours: 2));
      store.setLiveForTest('obs', true);
      expect(store.currentSession!.id, isNot(first.id));
      expect(store.sessions, hasLength(2));
    });

    test('a session left open by a kill ends at the last heartbeat', () async {
      store.setLiveForTest('twitch', true);
      await persistence.putMeta(
        'heartbeat',
        now.add(const Duration(minutes: 42)).toIso8601String(),
      );
      await store.dispose();
      now = now.add(const Duration(days: 1));
      store = build();
      await store.init();
      expect(store.currentSession, isNull);
      expect(store.sessions.single.end, DateTime.utc(2026, 10, 2, 20, 42));
    });

    test('opened mid-stream: the session reaches back to the stream start', () {
      store.ingest(
        _event('early', at: now.subtract(const Duration(minutes: 40))),
      );
      store.setLiveForTest(
        'twitch',
        true,
        since: now.subtract(const Duration(hours: 1)),
      );
      expect(
        store.currentSession!.start,
        now.subtract(const Duration(hours: 1)),
      );
      expect(store.groups.single.session, isNotNull);
    });

    test('a later-reported earlier start moves an open session back', () {
      store.setLiveForTest('kick', true);
      store.setLiveForTest(
        'twitch',
        true,
        since: now.subtract(const Duration(minutes: 30)),
      );
      expect(
        store.currentSession!.start,
        now.subtract(const Duration(minutes: 30)),
      );
    });

    test('reopened while the same broadcast still runs: one session', () {
      store.setLiveForTest('kick', true);
      final first = store.currentSession!;
      now = now.add(const Duration(hours: 1));
      store.setLiveForTest('kick', false);

      /// App closed 3 h; Twitch says the stream started before the end
      now = now.add(const Duration(hours: 3));
      store.setLiveForTest(
        'twitch',
        true,
        since: first.start.add(const Duration(minutes: 5)),
      );
      expect(store.sessions, hasLength(1));
      expect(store.currentSession!.id, first.id);
    });

    test('relay backlog of two past streams: two sessions, real ends', () {
      final day1 = now.subtract(const Duration(days: 2));
      final day2 = now.subtract(const Duration(days: 1));
      store.setLiveForTest('kick-relay', true, since: day1);
      store.setLiveForTest(
        'kick-relay',
        false,
        endedAt: day1.add(const Duration(hours: 2)),
      );
      store.setLiveForTest('kick-relay', true, since: day2);
      store.setLiveForTest(
        'kick-relay',
        false,
        endedAt: day2.add(const Duration(hours: 3)),
      );
      expect(store.sessions, hasLength(2));
      expect(store.sessions.last.end, day1.add(const Duration(hours: 2)));
      expect(store.sessions.first.start, day2);
      expect(store.sessions.first.end, day2.add(const Duration(hours: 3)));
    });

    test('rows outside sessions group by day', () {
      store.ingest(_event('a', at: now));
      store.ingest(
        _event('b', at: now.subtract(const Duration(days: 2)), actor: 'B'),
      );
      expect(store.groups, hasLength(2));
      expect(store.groups.every((group) => group.session == null), isTrue);
    });
  });

  test('prune: 30 days', () async {
    store.ingest(_event('old', at: now.subtract(const Duration(days: 31))));
    store.ingest(_event('new', at: now, actor: 'New'));
    store.pruneForTest();
    expect(store.allEvents.map((e) => e.id), ['new']);
    expect(persistence.events.keys, ['new']);
  });

  test('native coverage drops a lower-priority duplicate source', () {
    store.setNativeCoverageForTest(ActivityPlatform.twitch, '1');
    now = now.add(const Duration(minutes: 1));
    store.ingest(
      _event(
        'se-sub',
        at: now,
        actor: 'Nobody',
        source: ActivitySource.streamElements,
      ),
    );
    expect(store.allEvents, isEmpty);
    store.setNativeCoverageForTest(ActivityPlatform.twitch, null);
    now = now.add(const Duration(minutes: 1));
    store.ingest(
      _event(
        'se-sub-2',
        at: now,
        actor: 'Nobody',
        source: ActivitySource.streamElements,
      ),
    );
    expect(store.allEvents.single.id, 'se-sub-2');
  });

  test('relay frames become rows; repeats are one row', () {
    final frame = {
      'type': 'event',
      'seq': 7,
      'message_id': '01A',
      'event_type': 'kicks.gifted',
      'event_version': '1',
      'timestamp': '2026-10-02T20:00:00Z',
      'payload': {
        'broadcaster': {'user_id': 42, 'username': 'me'},
        'sender': {'user_id': 9, 'username': 'Fan'},
        'gift': {'amount': 100, 'name': 'Hype', 'tier': 'BASIC'},
        'created_at': '2026-10-02T20:00:00Z',
      },
    };
    store.handleRelayFrame(frame);
    store.handleRelayFrame(frame);
    final row = store.allEvents.single;
    expect(row.kind, ActivityKind.kicks);
    expect(row.amount!.value, 100);
    expect(row.platform, ActivityPlatform.kick);
  });

  test('clear history', () async {
    store.ingest(_event('a', at: now));
    await store.clearHistory();
    expect(store.allEvents, isEmpty);
    expect(persistence.events, isEmpty);
    expect(store.unseenCount, 0);
  });
}
