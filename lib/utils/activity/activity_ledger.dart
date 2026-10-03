import '../../types/classes/activity/activity_event.dart';

/// Which source is trusted first for each (platform, kind). The first
/// source in the list owns the kind; later ones only fill gaps - while a
/// higher-priority source is covering the channel, lower ones are dropped
/// (see [ActivityLedger.ingest]).
///
/// StreamElements / Streamlabs rows are here already so adding their
/// clients is only a provider + mapper: tips and merch only exist there,
/// everything else stays native-first.
abstract final class ActivityOwnership {
  static const List<ActivitySource> _nativeFirst = [
    ActivitySource.native,
    ActivitySource.streamElements,
    ActivitySource.streamlabs,
  ];

  static const List<ActivitySource> _thirdPartyOnly = [
    ActivitySource.streamElements,
    ActivitySource.streamlabs,
  ];

  static List<ActivitySource> priority(
    ActivityPlatform platform,
    ActivityKind kind,
  ) {
    if (kind == ActivityKind.tip || kind == ActivityKind.merch) {
      return _thirdPartyOnly;
    }
    switch (platform) {
      case ActivityPlatform.twitch:
        return _nativeFirst;
      case ActivityPlatform.youtube:

        /// New channel subscribers: the live chat API never sends them
        return kind == ActivityKind.follow ? _thirdPartyOnly : _nativeFirst;
      case ActivityPlatform.kick:
        return switch (kind) {
          /// Webhook-only on Kick's side - the relay, or SE's own relay
          ActivityKind.follow || ActivityKind.kicks => const [
            ActivitySource.kickRelay,
            ActivitySource.streamElements,
          ],

          /// Pusher payloads are guessed; the relay's are documented
          ActivityKind.sub ||
          ActivityKind.resub ||
          ActivityKind.giftSub ||
          ActivityKind.redemption => const [
            ActivitySource.kickRelay,
            ActivitySource.native,
            ActivitySource.streamElements,
          ],
          _ => _nativeFirst,
        };
    }
  }

  /// Lower is better; sources missing from the list rank last.
  static int rank(
    ActivityPlatform platform,
    ActivityKind kind,
    ActivitySource source,
  ) {
    final index = priority(platform, kind).indexOf(source);
    return index < 0 ? 1 << 20 : index;
  }
}

/// When a source was really connected for an own channel. A source that
/// covers a channel reports everything of the kinds it owns, so a
/// lower-priority duplicate at that time can be dropped.
class ActivityCoverage {
  /// `source|platform|channel` → intervals, oldest first; an open
  /// interval has a null end.
  final Map<String, List<(DateTime, DateTime?)>> _windows;

  static const int _maxWindowsPerKey = 100;

  ActivityCoverage([Map<String, List<(DateTime, DateTime?)>>? windows])
    : _windows = windows ?? {};

  static String key(
    ActivitySource source,
    ActivityPlatform platform,
    String channelId,
  ) => '${source.name}|${platform.name}|$channelId';

  bool isOpen(ActivitySource source, ActivityPlatform platform, String ch) {
    final list = this._windows[key(source, platform, ch)];
    return list != null && list.isNotEmpty && list.last.$2 == null;
  }

  /// Returns whether anything changed.
  bool open(
    ActivitySource source,
    ActivityPlatform platform,
    String channelId,
    DateTime at,
  ) {
    final list = this._windows.putIfAbsent(
      key(source, platform, channelId),
      () => [],
    );
    if (list.isNotEmpty && list.last.$2 == null) return false;
    list.add((at.toUtc(), null));
    if (list.length > _maxWindowsPerKey) list.removeAt(0);
    return true;
  }

  bool close(
    ActivitySource source,
    ActivityPlatform platform,
    String channelId,
    DateTime at,
  ) {
    final list = this._windows[key(source, platform, channelId)];
    if (list == null || list.isEmpty || list.last.$2 != null) return false;
    final start = list.last.$1;
    list[list.length - 1] = (start, at.toUtc());
    return true;
  }

  /// Close every open window at [at].
  void closeAll(DateTime at) {
    for (final list in this._windows.values) {
      if (list.isNotEmpty && list.last.$2 == null) {
        final start = list.last.$1;
        list[list.length - 1] = (start, at.toUtc());
      }
    }
  }

  /// App start: a window a kill left open ends when the app was last
  /// known alive ([lastAlive]), never at this launch - the downtime wasn't
  /// listened to. Without a usable [lastAlive] it ends where it began.
  void closeAfterKill(DateTime? lastAlive) {
    for (final list in this._windows.values) {
      if (list.isEmpty || list.last.$2 != null) continue;
      final start = list.last.$1;
      final alive = lastAlive?.toUtc();
      list[list.length - 1] = (
        start,
        alive != null && alive.isAfter(start) ? alive : start,
      );
    }
  }

  /// The process was frozen from [from] to [to] (iOS suspends a
  /// backgrounded app: sockets die, nothing arrives): every open window
  /// ends at [from] and goes on from [to]. Returns whether any was open.
  bool splitOpen(DateTime from, DateTime to) {
    var any = false;
    for (final list in this._windows.values) {
      if (list.isEmpty || list.last.$2 != null) continue;
      any = true;
      final start = list.last.$1;
      final end = from.toUtc();
      list[list.length - 1] = (start, end.isAfter(start) ? end : start);
      list.add((to.toUtc(), null));
      if (list.length > _maxWindowsPerKey) list.removeAt(0);
    }
    return any;
  }

  bool get anyOpen => this._windows.values.any(
    (list) => list.isNotEmpty && list.last.$2 == null,
  );

  /// Every window of [platform] from any source and channel, unsorted.
  List<(DateTime, DateTime?)> windowsFor(ActivityPlatform platform) => [
    for (final entry in this._windows.entries)
      if (entry.key.split('|').elementAtOrNull(1) == platform.name)
        ...entry.value,
  ];

  bool covers(
    ActivitySource source,
    ActivityPlatform platform,
    String channelId,
    DateTime at,
  ) {
    final list = this._windows[key(source, platform, channelId)];
    if (list == null) return false;
    final moment = at.toUtc();
    for (final (start, end) in list) {
      if (!moment.isBefore(start) && (end == null || !moment.isAfter(end))) {
        return true;
      }
    }
    return false;
  }

  void prune(DateTime olderThan) {
    for (final list in this._windows.values) {
      list.removeWhere((window) {
        final end = window.$2;
        return end != null && end.isBefore(olderThan);
      });
    }
    this._windows.removeWhere((_, list) => list.isEmpty);
  }

  Map<String, Object?> toJson() => {
    for (final entry in this._windows.entries)
      entry.key: [
        for (final (start, end) in entry.value)
          [start.toIso8601String(), end?.toIso8601String()],
      ],
  };

  factory ActivityCoverage.fromJson(Object? json) {
    final windows = <String, List<(DateTime, DateTime?)>>{};
    if (json is Map) {
      for (final entry in json.entries) {
        final list = entry.value;
        if (entry.key is! String || list is! List) continue;
        final parsed = <(DateTime, DateTime?)>[];
        for (final window in list) {
          if (window is! List || window.length != 2) continue;
          final start = DateTime.tryParse('${window[0]}');
          if (start == null) continue;
          final end = window[1] == null
              ? null
              : DateTime.tryParse('${window[1]}');
          parsed.add((start.toUtc(), end?.toUtc()));
        }
        if (parsed.isNotEmpty) windows[entry.key as String] = parsed;
      }
    }
    return ActivityCoverage(windows);
  }
}

enum ActivityIngestOutcome {
  /// New row
  inserted,

  /// Same event seen before (same id, or the same thing from another
  /// source) - the stored row was updated
  merged,

  /// A higher-priority source was covering the channel at the time
  dropped,
}

class ActivityIngestResult {
  final ActivityIngestOutcome outcome;

  /// The stored row after the operation (null when dropped)
  final ActivityEvent? event;

  const ActivityIngestResult(this.outcome, this.event);
}

/// The in-memory feed plus the dedup rules. Pure - no Hive, no MobX - so
/// the rules are testable on their own; `ActivityStore` persists what
/// [ingest] returns.
class ActivityLedger {
  /// Max time apart for two reports of the same event from different
  /// sources (webhook / socket / poll latency).
  static const Duration matchWindow = Duration(minutes: 2);

  final Map<String, ActivityEvent> _byId = {};

  /// `source:sourceEventId` → event id
  final Map<String, String> _bySourceId = {};
  final ActivityCoverage coverage;
  int _seq;

  ActivityLedger({ActivityCoverage? coverage, int seq = 0})
    : coverage = coverage ?? ActivityCoverage(),
      _seq = seq; // ignore: prefer_initializing_formals

  int get seq => this._seq;

  Iterable<ActivityEvent> get events => this._byId.values;

  ActivityEvent? operator [](String id) => this._byId[id];

  /// Load a persisted row as-is (no dedup, keeps its seq).
  void restore(ActivityEvent event) {
    this._byId[event.id] = event;
    for (final entry in event.sources.entries) {
      this._bySourceId['${entry.key.name}:${entry.value}'] = event.id;
    }
    if (event.seq > this._seq) this._seq = event.seq;
  }

  ActivityEvent? remove(String id) {
    final event = this._byId.remove(id);
    if (event != null) {
      for (final entry in event.sources.entries) {
        this._bySourceId.remove('${entry.key.name}:${entry.value}');
      }
    }
    return event;
  }

  /// Replace a stored row (thanked toggles); ignores unknown ids.
  void update(ActivityEvent event) {
    if (this._byId.containsKey(event.id)) this._byId[event.id] = event;
  }

  /// Rules, in order:
  /// 1. same id or same source event id → update in place;
  /// 2. same platform + channel + kind, same person, same amount, within
  ///    [matchWindow] → merge (another source's report of it);
  /// 3. a higher-priority source covered the channel at that time → drop;
  /// 4. insert.
  ActivityIngestResult ingest(ActivityEvent incoming) {
    final existing = this._exact(incoming) ?? this._fuzzy(incoming);
    if (existing != null) {
      final merged = this._merge(existing, incoming);
      this._byId[merged.id] = merged;
      for (final entry in merged.sources.entries) {
        this._bySourceId['${entry.key.name}:${entry.value}'] = merged.id;
      }
      return ActivityIngestResult(ActivityIngestOutcome.merged, merged);
    }

    if (this._coveredByBetterSource(incoming)) {
      return const ActivityIngestResult(ActivityIngestOutcome.dropped, null);
    }

    final stored = incoming.copyWith(seq: ++this._seq);
    this._byId[stored.id] = stored;
    for (final entry in stored.sources.entries) {
      this._bySourceId['${entry.key.name}:${entry.value}'] = stored.id;
    }
    return ActivityIngestResult(ActivityIngestOutcome.inserted, stored);
  }

  ActivityEvent? _exact(ActivityEvent incoming) {
    final byId = this._byId[incoming.id];
    if (byId != null) return byId;
    for (final entry in incoming.sources.entries) {
      final id = this._bySourceId['${entry.key.name}:${entry.value}'];
      if (id != null && this._byId[id] != null) return this._byId[id];
    }
    return null;
  }

  ActivityEvent? _fuzzy(ActivityEvent incoming) {
    ActivityEvent? best;
    Duration? bestGap;
    for (final candidate in this._byId.values) {
      if (candidate.platform != incoming.platform ||
          candidate.channelId != incoming.channelId ||
          candidate.kind != incoming.kind) {
        continue;
      }

      /// Two reports from the same source are two events (two follows
      /// from one person can't happen; two cheers can)
      if (candidate.sources.keys.any(incoming.sources.containsKey)) continue;
      final gap = candidate.timestamp.difference(incoming.timestamp).abs();
      if (gap > matchWindow) continue;
      if (!candidate.actor.sameAs(incoming.actor)) continue;
      final a = candidate.amount;
      final b = incoming.amount;
      if (a != null && b != null && !a.sameAs(b)) continue;
      if (bestGap == null || gap < bestGap) {
        best = candidate;
        bestGap = gap;
      }
    }
    return best;
  }

  bool _coveredByBetterSource(ActivityEvent incoming) {
    final order = ActivityOwnership.priority(incoming.platform, incoming.kind);
    final own = ActivityOwnership.rank(
      incoming.platform,
      incoming.kind,
      incoming.primarySource,
    );
    for (var i = 0; i < order.length && i < own; i++) {
      if (this.coverage.covers(
        order[i],
        incoming.platform,
        incoming.channelId,
        incoming.timestamp,
      )) {
        return true;
      }
    }
    return false;
  }

  /// Keeps id, seq and thanked of [stored]. The better-ranked source's
  /// payload wins; recipients add up (Twitch sends a gift bomb's
  /// recipients one notice at a time).
  ActivityEvent _merge(ActivityEvent stored, ActivityEvent incoming) {
    final storedRank = ActivityOwnership.rank(
      stored.platform,
      stored.kind,
      stored.primarySource,
    );
    final incomingRank = ActivityOwnership.rank(
      incoming.platform,
      incoming.kind,
      incoming.primarySource,
    );
    final incomingWins =
        incomingRank < storedRank ||
        (incomingRank == storedRank &&
            incoming.primarySource == stored.primarySource);
    final base = incomingWins ? incoming : stored;
    final other = incomingWins ? stored : incoming;
    final recipients = <String>[
      ...stored.recipients,
      for (final name in incoming.recipients)
        if (!stored.recipients.contains(name)) name,
    ];
    var amount = base.amount ?? other.amount;
    final otherAmount = other.amount;
    if (amount != null &&
        otherAmount != null &&
        amount.unit == ActivityUnit.subs &&
        otherAmount.unit == ActivityUnit.subs &&
        otherAmount.value > amount.value) {
      amount = otherAmount;
    }
    if (amount != null &&
        amount.unit == ActivityUnit.subs &&
        recipients.length > amount.value) {
      amount = ActivityAmount(recipients.length, ActivityUnit.subs);
    }
    return ActivityEvent(
      id: stored.id,
      platform: stored.platform,
      channelId: stored.channelId,
      kind: stored.kind,
      actor: base.actor.anonymous && !other.actor.anonymous
          ? other.actor
          : base.actor,
      amount: amount,
      tier: base.tier ?? other.tier,
      message: base.message ?? other.message,
      title: base.title ?? other.title,
      recipients: recipients,
      timestamp: stored.timestamp,
      sources: {...stored.sources, ...incoming.sources},
      primarySource: incomingWins
          ? incoming.primarySource
          : stored.primarySource,
      seq: stored.seq,
      thanked: stored.thanked,
    );
  }
}

/// A stretch of a stream where the app wasn't listening on [platform]:
/// events of it from then may be missing.
class ActivityGap {
  final ActivityPlatform platform;
  final DateTime start;

  /// Null: still not listening
  final DateTime? end;

  const ActivityGap({required this.platform, required this.start, this.end});

  String get id => 'gap:${this.platform.name}:${this.start.toIso8601String()}';

  @override
  bool operator ==(Object other) =>
      other is ActivityGap &&
      other.platform == this.platform &&
      other.start == this.start &&
      other.end == this.end;

  @override
  int get hashCode => Object.hash(this.platform, this.start, this.end);

  @override
  String toString() => 'ActivityGap(${this.platform.name}, $start - $end)';
}

/// Parts of [from]..[to] that none of [windows] covers, at least [minimum]
/// long, oldest first. [open] marks [to] as "now" - a gap reaching it is
/// still going (null end).
List<ActivityGap> coverageGaps(
  ActivityPlatform platform,
  List<(DateTime, DateTime?)> windows,
  DateTime from,
  DateTime to, {
  required bool open,
  Duration minimum = const Duration(minutes: 1),
}) {
  final start = from.toUtc();
  final end = to.toUtc();
  final sorted = [for (final (s, e) in windows) (s.toUtc(), (e ?? end).toUtc())]
    ..sort((a, b) => a.$1.compareTo(b.$1));
  final gaps = <ActivityGap>[];
  var cursor = start;
  void add(DateTime gapStart, DateTime gapEnd, {bool running = false}) {
    if (gapEnd.difference(gapStart) < minimum) return;
    gaps.add(
      ActivityGap(
        platform: platform,
        start: gapStart,
        end: running ? null : gapEnd,
      ),
    );
  }

  for (final (s, e) in sorted) {
    if (!e.isAfter(cursor)) continue;
    if (!s.isBefore(end)) {
      /// Listening again from exactly now: the gap is over
      if (s == end && cursor.isBefore(end)) {
        add(cursor, end);
        cursor = end;
      }
      break;
    }
    if (s.isAfter(cursor)) add(cursor, s);
    if (e.isAfter(cursor)) cursor = e;
  }
  if (cursor.isBefore(end)) add(cursor, end, running: open);
  return gaps;
}
