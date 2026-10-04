import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/types/classes/activity/activity_event.dart';
import 'package:obs_blade/utils/activity/activity_ledger.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 2, 20);

ActivityEvent _event({
  String id = 'e1',
  ActivityPlatform platform = ActivityPlatform.kick,
  String channel = '42',
  ActivityKind kind = ActivityKind.sub,
  ActivityActor actor = const ActivityActor(id: '7', name: 'Fan'),
  ActivityAmount? amount,
  List<String> recipients = const [],
  Duration at = Duration.zero,
  ActivitySource source = ActivitySource.native,
  String? sourceId,
  String? title,
}) => ActivityEvent(
  id: id,
  platform: platform,
  channelId: channel,
  kind: kind,
  actor: actor,
  amount: amount,
  recipients: recipients,
  title: title,
  timestamp: _t0.add(at),
  sources: {source: sourceId ?? id},
  primarySource: source,
);

void main() {
  group('ingest', () {
    test('inserts with increasing seq', () {
      final ledger = ActivityLedger();
      final a = ledger.ingest(_event(id: 'a'));
      final b = ledger.ingest(
        _event(
          id: 'b',
          actor: const ActivityActor(name: 'Other'),
        ),
      );
      expect(a.outcome, ActivityIngestOutcome.inserted);
      expect(b.outcome, ActivityIngestOutcome.inserted);
      expect(a.event!.seq, 1);
      expect(b.event!.seq, 2);
      expect(ledger.seq, 2);
    });

    test('same id is an update, not a second row (reconnect replay)', () {
      final ledger = ActivityLedger();
      ledger.ingest(_event(id: 'a'));
      final again = ledger.ingest(_event(id: 'a'));
      expect(again.outcome, ActivityIngestOutcome.merged);
      expect(ledger.events, hasLength(1));
      expect(again.event!.seq, 1);
    });

    test('same source event id under another id merges', () {
      final ledger = ActivityLedger();
      ledger.ingest(_event(id: 'a', sourceId: 'msg-1'));
      final again = ledger.ingest(_event(id: 'b', sourceId: 'msg-1'));
      expect(again.outcome, ActivityIngestOutcome.merged);
      expect(ledger.events, hasLength(1));
    });

    test('thanked survives a merge', () {
      final ledger = ActivityLedger();
      final stored = ledger.ingest(_event(id: 'a')).event!;
      ledger.update(stored.copyWith(thanked: true));
      final merged = ledger.ingest(_event(id: 'a')).event!;
      expect(merged.thanked, isTrue);
    });

    test(
      'Twitch gift bomb: community notice + per-recipient notices are one row',
      () {
        final ledger = ActivityLedger();
        ActivityEvent gift({
          ActivityAmount? amount,
          List<String> to = const [],
        }) => _event(
          id: 'twitch:1:gift:cg-1',
          platform: ActivityPlatform.twitch,
          channel: '1',
          kind: ActivityKind.giftSub,
          amount: amount,
          recipients: to,
          sourceId: 'msg-${to.isEmpty ? 'bomb' : to.first}',
        );
        ledger.ingest(gift(to: ['a']));
        ledger.ingest(gift(amount: const ActivityAmount(3, ActivityUnit.subs)));
        ledger.ingest(gift(to: ['b']));
        final row = ledger.ingest(gift(to: ['c'])).event!;
        expect(ledger.events, hasLength(1));
        expect(row.recipients, ['a', 'b', 'c']);
        expect(row.amount!.value, 3);
        expect(row.amount!.unit, ActivityUnit.subs);
      },
    );
  });

  group('cross-source matching (Kick: relay first, Pusher second)', () {
    ActivityEvent pusherSub({Duration at = Duration.zero}) => _event(
      id: 'kick:42:pusher:p1',
      actor: const ActivityActor(login: 'fan', name: 'Fan'),
      at: at,
      sourceId: 'p1',
    );
    ActivityEvent relaySub({Duration at = Duration.zero}) => _event(
      id: 'kick:42:sub:r1',
      actor: const ActivityActor(id: '7', login: 'fan', name: 'Fan'),
      at: at,
      source: ActivitySource.kickRelay,
      sourceId: 'r1',
      title: 'from relay',
    );

    test('relay covering: Pusher copy is dropped', () {
      final ledger = ActivityLedger();
      ledger.coverage.open(
        ActivitySource.kickRelay,
        ActivityPlatform.kick,
        '42',
        _t0.subtract(const Duration(minutes: 5)),
      );
      expect(ledger.ingest(pusherSub()).outcome, ActivityIngestOutcome.dropped);
      expect(ledger.ingest(relaySub()).outcome, ActivityIngestOutcome.inserted);
      expect(ledger.events, hasLength(1));
    });

    test('relay first, Pusher later: merged, relay payload stays', () {
      final ledger = ActivityLedger();
      ledger.ingest(relaySub());
      final merged = ledger.ingest(pusherSub(at: const Duration(seconds: 3)));
      expect(merged.outcome, ActivityIngestOutcome.merged);
      expect(merged.event!.primarySource, ActivitySource.kickRelay);
      expect(merged.event!.title, 'from relay');
      expect(
        merged.event!.sources.keys,
        containsAll(ActivitySource.values.take(2)),
      );
    });

    test('relay offline: Pusher row kept, relay backfill upgrades it', () {
      final ledger = ActivityLedger();
      final first = ledger.ingest(pusherSub());
      expect(first.outcome, ActivityIngestOutcome.inserted);
      final upgraded = ledger.ingest(relaySub(at: const Duration(seconds: 40)));
      expect(upgraded.outcome, ActivityIngestOutcome.merged);
      expect(ledger.events, hasLength(1));
      expect(upgraded.event!.primarySource, ActivitySource.kickRelay);
      expect(upgraded.event!.actor.id, '7');
      expect(upgraded.event!.seq, first.event!.seq);
    });

    test('too far apart in time: two rows', () {
      final ledger = ActivityLedger();
      ledger.ingest(pusherSub());
      final later = ledger.ingest(relaySub(at: const Duration(minutes: 5)));
      expect(later.outcome, ActivityIngestOutcome.inserted);
      expect(ledger.events, hasLength(2));
    });

    test('different amounts never match', () {
      final ledger = ActivityLedger();
      ledger.ingest(
        _event(
          id: 'p',
          kind: ActivityKind.giftSub,
          amount: const ActivityAmount(5, ActivityUnit.subs),
        ),
      );
      final other = ledger.ingest(
        _event(
          id: 'r',
          kind: ActivityKind.giftSub,
          amount: const ActivityAmount(10, ActivityUnit.subs),
          source: ActivitySource.kickRelay,
        ),
      );
      expect(other.outcome, ActivityIngestOutcome.inserted);
    });

    test('two cheers from one person on one source are two rows', () {
      final ledger = ActivityLedger();
      ActivityEvent cheer(String id) => _event(
        id: id,
        platform: ActivityPlatform.twitch,
        kind: ActivityKind.cheer,
        amount: const ActivityAmount(100, ActivityUnit.bits),
      );
      ledger.ingest(cheer('c1'));
      expect(
        ledger.ingest(cheer('c2')).outcome,
        ActivityIngestOutcome.inserted,
      );
    });
  });

  group('third-party gap fill (StreamElements / Streamlabs seam)', () {
    ActivityEvent seSub({Duration at = Duration.zero, String id = 'se1'}) =>
        _event(
          id: 'se:$id',
          platform: ActivityPlatform.twitch,
          channel: '1',
          actor: const ActivityActor(login: 'fan', name: 'Fan'),
          at: at,
          source: ActivitySource.streamElements,
          sourceId: id,
        );

    test('native covering: the SE copy is dropped', () {
      final ledger = ActivityLedger();
      ledger.coverage.open(
        ActivitySource.native,
        ActivityPlatform.twitch,
        '1',
        _t0.subtract(const Duration(hours: 1)),
      );
      expect(ledger.ingest(seSub()).outcome, ActivityIngestOutcome.dropped);
    });

    test('native was offline at that time: SE fills the gap', () {
      final ledger = ActivityLedger();
      ledger.coverage
        ..open(
          ActivitySource.native,
          ActivityPlatform.twitch,
          '1',
          _t0.subtract(const Duration(hours: 2)),
        )
        ..close(
          ActivitySource.native,
          ActivityPlatform.twitch,
          '1',
          _t0.subtract(const Duration(hours: 1)),
        );
      expect(ledger.ingest(seSub()).outcome, ActivityIngestOutcome.inserted);
    });

    test('native row exists: the SE report merges into it', () {
      final ledger = ActivityLedger();
      ledger.ingest(
        _event(
          id: 'twitch:1:sub:m1',
          platform: ActivityPlatform.twitch,
          channel: '1',
          actor: const ActivityActor(id: '7', login: 'fan', name: 'Fan'),
        ),
      );
      final merged = ledger.ingest(seSub(at: const Duration(seconds: 20)));
      expect(merged.outcome, ActivityIngestOutcome.merged);
      expect(merged.event!.primarySource, ActivitySource.native);
    });

    test('tips belong to third parties - kept even while native covers', () {
      final ledger = ActivityLedger();
      ledger.coverage.open(
        ActivitySource.native,
        ActivityPlatform.twitch,
        '1',
        _t0.subtract(const Duration(hours: 1)),
      );
      final tip = _event(
        id: 'se:tip1',
        platform: ActivityPlatform.twitch,
        channel: '1',
        kind: ActivityKind.tip,
        amount: const ActivityAmount(5, 'USD'),
        source: ActivitySource.streamElements,
      );
      expect(ledger.ingest(tip).outcome, ActivityIngestOutcome.inserted);
    });
  });

  group('coverage', () {
    test('open / close / covers / closeAll / json', () {
      final coverage = ActivityCoverage();
      expect(
        coverage.open(ActivitySource.native, ActivityPlatform.kick, '1', _t0),
        isTrue,
      );
      expect(
        coverage.open(ActivitySource.native, ActivityPlatform.kick, '1', _t0),
        isFalse,
      );
      expect(
        coverage.covers(
          ActivitySource.native,
          ActivityPlatform.kick,
          '1',
          _t0.add(const Duration(days: 3)),
        ),
        isTrue,
      );
      coverage.closeAll(_t0.add(const Duration(hours: 1)));
      expect(
        coverage.covers(
          ActivitySource.native,
          ActivityPlatform.kick,
          '1',
          _t0.add(const Duration(hours: 2)),
        ),
        isFalse,
      );
      final restored = ActivityCoverage.fromJson(
        jsonDecode(jsonEncode(coverage.toJson())),
      );
      expect(
        restored.covers(
          ActivitySource.native,
          ActivityPlatform.kick,
          '1',
          _t0.add(const Duration(minutes: 30)),
        ),
        isTrue,
      );
      expect(
        restored.isOpen(ActivitySource.native, ActivityPlatform.kick, '1'),
        isFalse,
      );
    });

    test('prune drops closed windows older than the cutoff', () {
      final coverage = ActivityCoverage()
        ..open(ActivitySource.native, ActivityPlatform.kick, '1', _t0)
        ..close(
          ActivitySource.native,
          ActivityPlatform.kick,
          '1',
          _t0.add(const Duration(hours: 1)),
        );
      coverage.prune(_t0.add(const Duration(days: 31)));
      expect(coverage.toJson(), isEmpty);
    });
  });

  group('event json', () {
    test('round trip keeps every field', () {
      final event = _event(
        kind: ActivityKind.kicks,
        amount: const ActivityAmount(500, ActivityUnit.kicks),
        recipients: const ['x'],
        title: 'Rage Quit',
      ).copyWith(seq: 9, thanked: true, message: 'w', tier: 'MID');
      final back = ActivityEvent.fromJson(
        jsonDecode(jsonEncode(event.toJson())),
      )!;
      expect(back.id, event.id);
      expect(back.platform, event.platform);
      expect(back.kind, ActivityKind.kicks);
      expect(back.amount!.value, 500);
      expect(back.amount!.unit, ActivityUnit.kicks);
      expect(back.recipients, ['x']);
      expect(back.title, 'Rage Quit');
      expect(back.message, 'w');
      expect(back.tier, 'MID');
      expect(back.seq, 9);
      expect(back.thanked, isTrue);
      expect(back.timestamp, event.timestamp);
      expect(back.sources, event.sources);
    });

    test('unknown kind reads as other; junk reads as null', () {
      final json = _event().toJson()..['kind'] = 'teleport';
      expect(ActivityEvent.fromJson(json)!.kind, ActivityKind.other);
      expect(ActivityEvent.fromJson('nope'), isNull);
      expect(ActivityEvent.fromJson({'id': 'x'}), isNull);
    });

    test('currency vs platform units', () {
      expect(ActivityUnit.isCurrency('USD'), isTrue);
      expect(ActivityUnit.isCurrency(ActivityUnit.bits), isFalse);
      expect(ActivityUnit.isCurrency('usd'), isFalse);
    });
  });

  group('coverage gaps', () {
    DateTime at(int minute) => DateTime.utc(2026, 10, 2, 20, minute);

    test('overlapping windows from two sources are one', () {
      final gaps = coverageGaps(
        ActivityPlatform.youtube,
        [(at(0), at(10)), (at(5), at(20)), (at(30), null)],
        at(0),
        at(40),
        open: true,
      );
      expect(gaps, [
        ActivityGap(
          platform: ActivityPlatform.youtube,
          start: at(20),
          end: at(30),
        ),
      ]);
    });

    test('nothing covered: one gap over the whole span, running when open', () {
      final gaps = coverageGaps(
        ActivityPlatform.twitch,
        const [],
        at(0),
        at(10),
        open: true,
      );
      expect(gaps.single.start, at(0));
      expect(gaps.single.end, isNull);
    });

    test('windows outside the span and sub-minute holes are ignored', () {
      final gaps = coverageGaps(
        ActivityPlatform.twitch,
        [
          (DateTime.utc(2026, 10, 1), DateTime.utc(2026, 10, 1, 1)),
          (at(0), DateTime.utc(2026, 10, 2, 20, 4, 30)),
          (DateTime.utc(2026, 10, 2, 20, 5), at(10)),
        ],
        at(0),
        at(10),
        open: false,
      );
      expect(gaps, isEmpty);
    });

    test('kill: an open window ends at the last alive moment', () {
      final coverage = ActivityCoverage()
        ..open(ActivitySource.native, ActivityPlatform.twitch, '1', at(0));
      coverage.closeAfterKill(at(3));
      expect(
        coverage.covers(
          ActivitySource.native,
          ActivityPlatform.twitch,
          '1',
          at(2),
        ),
        isTrue,
      );
      expect(
        coverage.covers(
          ActivitySource.native,
          ActivityPlatform.twitch,
          '1',
          at(4),
        ),
        isFalse,
      );
      final stale = ActivityCoverage()
        ..open(ActivitySource.native, ActivityPlatform.twitch, '1', at(5));
      stale.closeAfterKill(at(3));
      expect(
        stale.covers(
          ActivitySource.native,
          ActivityPlatform.twitch,
          '1',
          at(6),
        ),
        isFalse,
      );
    });
  });

  group('coverage window cap', () {
    DateTime at(int minute) =>
        DateTime.utc(2026, 10, 2, 20).add(Duration(minutes: minute));

    test('reopened where it ended: one window', () {
      final coverage = ActivityCoverage()
        ..open(ActivitySource.native, ActivityPlatform.twitch, '1', at(0))
        ..close(ActivitySource.native, ActivityPlatform.twitch, '1', at(5))
        ..open(ActivitySource.native, ActivityPlatform.twitch, '1', at(5));
      expect(coverage.windowsFor(ActivityPlatform.twitch), [(at(0), null)]);
    });

    test('dropped history is unknown, survives a restart', () {
      final coverage = ActivityCoverage();
      for (var i = 0; i < 501; i++) {
        coverage
          ..open(ActivitySource.native, ActivityPlatform.twitch, '1', at(2 * i))
          ..close(
            ActivitySource.native,
            ActivityPlatform.twitch,
            '1',
            at(2 * i + 1),
          );
      }
      expect(coverage.windowsFor(ActivityPlatform.twitch), hasLength(500));
      expect(coverage.truncatedBefore(ActivityPlatform.twitch), at(1));
      final restored = ActivityCoverage.fromJson(coverage.toJson());
      expect(restored.truncatedBefore(ActivityPlatform.twitch), at(1));
      expect(restored.truncatedBefore(ActivityPlatform.youtube), isNull);
    });
  });
}
