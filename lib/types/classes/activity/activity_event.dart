/// Activity feed data model: one row per thing that happened on one of
/// the user's own channels (follow, sub, cheer, super chat, KICKs, ...).
///
/// Persisted as JSON strings in an untyped Hive box (no TypeID / adapter,
/// see `docs/persistence-risk.md`): [toJson] / [fromJson] are hand-written
/// and versioned via [kActivityEventJsonVersion]; unknown enum names read
/// back as fallbacks instead of throwing.
library;

/// Bump when the JSON shape changes in a way [ActivityEvent.fromJson]
/// must branch on.
const int kActivityEventJsonVersion = 1;

enum ActivityPlatform {
  twitch,
  youtube,
  kick;

  static ActivityPlatform? parse(Object? value) {
    for (final platform in ActivityPlatform.values) {
      if (platform.name == value) return platform;
    }
    return null;
  }
}

/// Where an event came from. Order matters nowhere - priority per
/// (platform, kind) lives in `ActivityOwnership`.
enum ActivitySource {
  /// The platform's own API, through the native chat stores
  native,

  /// OBS Blade's Kick webhook relay (`kick-events.obs-blade.com`)
  kickRelay,

  /// StreamElements (planned - waiting on API access)
  streamElements,

  /// Streamlabs (planned - waiting on API access)
  streamlabs;

  static ActivitySource? parse(Object? value) {
    for (final source in ActivitySource.values) {
      if (source.name == value) return source;
    }
    return null;
  }
}

enum ActivityKind {
  follow,
  sub,
  resub,

  /// One row per gifting action - a 50-sub bomb is one row with
  /// `amount = 50 subs` and the recipients listed.
  giftSub,
  raid,
  cheer,
  redemption,
  hypeTrain,
  charity,
  superChat,
  superSticker,
  member,
  memberMilestone,
  memberGift,
  kicks,
  host,
  tip,
  merch,
  other;

  static ActivityKind parse(Object? value) {
    for (final kind in ActivityKind.values) {
      if (kind.name == value) return kind;
    }
    return ActivityKind.other;
  }

  /// Goes into the to-thank queue by default.
  bool get isBig => switch (this) {
    ActivityKind.follow ||
    ActivityKind.redemption ||
    ActivityKind.host ||
    /// Nobody to thank - its contributors have their own rows
    ActivityKind.hypeTrain ||
    ActivityKind.other => false,
    _ => true,
  };

  /// Money (real currency or a platform currency bought with it).
  bool get isMoney => switch (this) {
    ActivityKind.cheer ||
    ActivityKind.superChat ||
    ActivityKind.superSticker ||
    ActivityKind.kicks ||
    ActivityKind.tip ||
    ActivityKind.merch ||
    ActivityKind.charity => true,
    _ => false,
  };

  /// Subscriptions / memberships, own or gifted.
  bool get isSub => switch (this) {
    ActivityKind.sub ||
    ActivityKind.resub ||
    ActivityKind.giftSub ||
    ActivityKind.member ||
    ActivityKind.memberMilestone ||
    ActivityKind.memberGift => true,
    _ => false,
  };
}

/// Units an [ActivityAmount] can carry besides ISO currency codes.
abstract final class ActivityUnit {
  static const String bits = 'bits';
  static const String kicks = 'kicks';
  static const String viewers = 'viewers';
  static const String months = 'months';
  static const String subs = 'subs';
  static const String points = 'points';
  static const String level = 'level';

  static const Set<String> nonCurrency = {
    bits,
    kicks,
    viewers,
    months,
    subs,
    points,
    level,
  };

  /// ISO 4217 code (3 upper-case letters) - real money.
  static bool isCurrency(String unit) =>
      unit.length == 3 &&
      unit.toUpperCase() == unit &&
      !nonCurrency.contains(unit);
}

class ActivityActor {
  /// Platform user id (Twitch user id, YouTube channel id, Kick user id)
  final String? id;

  /// Login / handle, lower-case where the platform has one
  final String? login;

  /// Display name; empty only for anonymous events
  final String name;
  final bool anonymous;

  const ActivityActor({
    this.id,
    this.login,
    required this.name,
    this.anonymous = false,
  });

  static const ActivityActor anonymousActor = ActivityActor(
    name: '',
    anonymous: true,
  );

  /// Stable identity for matching the same person across sources: the
  /// platform id when present, else the lower-cased login / name.
  String get matchKey {
    if (this.anonymous) return 'anon';
    final id = this.id;
    if (id != null && id.isNotEmpty) return 'id:$id';
    return 'name:${(this.login ?? this.name).toLowerCase()}';
  }

  /// Same person by any key both sides have (id, else login / name).
  bool sameAs(ActivityActor other) {
    if (this.anonymous || other.anonymous) {
      return this.anonymous && other.anonymous;
    }
    final id = this.id;
    final otherId = other.id;
    if (id != null && id.isNotEmpty && otherId != null && otherId.isNotEmpty) {
      return id == otherId;
    }
    final names = {
      if (this.login != null) this.login!.toLowerCase(),
      this.name.toLowerCase(),
    };
    return names.contains((other.login ?? '').toLowerCase()) ||
        names.contains(other.name.toLowerCase());
  }

  Map<String, Object?> toJson() => {
    if (this.id != null) 'id': this.id,
    if (this.login != null) 'login': this.login,
    'name': this.name,
    if (this.anonymous) 'anonymous': true,
  };

  factory ActivityActor.fromJson(Object? json) {
    if (json is! Map) return anonymousActor;
    return ActivityActor(
      id: json['id'] as String?,
      login: json['login'] as String?,
      name: (json['name'] as String?) ?? '',
      anonymous: json['anonymous'] == true,
    );
  }
}

class ActivityAmount {
  final num value;

  /// ISO currency code or one of [ActivityUnit]
  final String unit;

  /// Platform-formatted text when it has one (YouTube `$5.00`)
  final String? display;

  const ActivityAmount(this.value, this.unit, {this.display});

  bool get isCurrency => ActivityUnit.isCurrency(this.unit);

  /// Equal for matching across sources: same unit, values within a cent
  /// (micros → double rounding).
  bool sameAs(ActivityAmount other) =>
      this.unit == other.unit && (this.value - other.value).abs() < 0.01;

  Map<String, Object?> toJson() => {
    'value': this.value,
    'unit': this.unit,
    if (this.display != null) 'display': this.display,
  };

  static ActivityAmount? fromJson(Object? json) {
    if (json is! Map) return null;
    final value = json['value'];
    final unit = json['unit'];
    if (value is! num || unit is! String) return null;
    return ActivityAmount(value, unit, display: json['display'] as String?);
  }
}

class ActivityEvent {
  /// Stable key, unique per real-world event across sources. Built by the
  /// mappers (e.g. `twitch:<channel>:follow:<user>`); the store keys
  /// persistence and exact-dedup on it.
  final String id;
  final ActivityPlatform platform;

  /// Own channel this happened on: Twitch user id, YouTube channel id,
  /// Kick user id
  final String channelId;
  final ActivityKind kind;
  final ActivityActor actor;
  final ActivityAmount? amount;

  /// Sub tier (`1000` / `2000` / `3000` / `prime`), member level name,
  /// KICKs gift tier, hype train type
  final String? tier;
  final String? message;

  /// Reward title, gift name, sticker alt text
  final String? title;
  final List<String> recipients;

  /// When it happened (UTC)
  final DateTime timestamp;

  /// Every source that reported it → that source's own event id
  final Map<ActivitySource, String> sources;

  /// The source whose payload the row shows (highest priority seen)
  final ActivitySource primarySource;

  /// Insert order, assigned by the store - "new since you last looked"
  /// compares against it, not the timestamp (backfilled events are new
  /// even when they are old)
  final int seq;
  final bool thanked;

  const ActivityEvent({
    required this.id,
    required this.platform,
    required this.channelId,
    required this.kind,
    required this.actor,
    this.amount,
    this.tier,
    this.message,
    this.title,
    this.recipients = const <String>[],
    required this.timestamp,
    required this.sources,
    required this.primarySource,
    this.seq = 0,
    this.thanked = false,
  });

  bool get isBig => this.kind.isBig;

  ActivityEvent copyWith({
    ActivityActor? actor,
    ActivityAmount? amount,
    String? tier,
    String? message,
    String? title,
    List<String>? recipients,
    DateTime? timestamp,
    Map<ActivitySource, String>? sources,
    ActivitySource? primarySource,
    int? seq,
    bool? thanked,
  }) => ActivityEvent(
    id: this.id,
    platform: this.platform,
    channelId: this.channelId,
    kind: this.kind,
    actor: actor ?? this.actor,
    amount: amount ?? this.amount,
    tier: tier ?? this.tier,
    message: message ?? this.message,
    title: title ?? this.title,
    recipients: recipients ?? this.recipients,
    timestamp: timestamp ?? this.timestamp,
    sources: sources ?? this.sources,
    primarySource: primarySource ?? this.primarySource,
    seq: seq ?? this.seq,
    thanked: thanked ?? this.thanked,
  );

  Map<String, Object?> toJson() => {
    'v': kActivityEventJsonVersion,
    'id': this.id,
    'platform': this.platform.name,
    'channel': this.channelId,
    'kind': this.kind.name,
    'actor': this.actor.toJson(),
    if (this.amount != null) 'amount': this.amount!.toJson(),
    if (this.tier != null) 'tier': this.tier,
    if (this.message != null) 'message': this.message,
    if (this.title != null) 'title': this.title,
    if (this.recipients.isNotEmpty) 'recipients': this.recipients,
    'ts': this.timestamp.toUtc().toIso8601String(),
    'sources': {
      for (final entry in this.sources.entries) entry.key.name: entry.value,
    },
    'primary': this.primarySource.name,
    'seq': this.seq,
    if (this.thanked) 'thanked': true,
  };

  /// Null for rows a newer app version wrote in a shape this one can't
  /// read, or junk - the store skips (and later prunes) them.
  static ActivityEvent? fromJson(Object? json) {
    if (json is! Map) return null;
    final platform = ActivityPlatform.parse(json['platform']);
    final id = json['id'];
    final channel = json['channel'];
    final ts = DateTime.tryParse('${json['ts']}');
    if (platform == null || id is! String || channel is! String || ts == null) {
      return null;
    }
    final sources = <ActivitySource, String>{};
    final rawSources = json['sources'];
    if (rawSources is Map) {
      for (final entry in rawSources.entries) {
        final source = ActivitySource.parse(entry.key);
        if (source != null && entry.value is String) {
          sources[source] = entry.value as String;
        }
      }
    }
    final primary =
        ActivitySource.parse(json['primary']) ??
        (sources.keys.isEmpty ? ActivitySource.native : sources.keys.first);
    final rawRecipients = json['recipients'];
    return ActivityEvent(
      id: id,
      platform: platform,
      channelId: channel,
      kind: ActivityKind.parse(json['kind']),
      actor: ActivityActor.fromJson(json['actor']),
      amount: ActivityAmount.fromJson(json['amount']),
      tier: json['tier'] as String?,
      message: json['message'] as String?,
      title: json['title'] as String?,
      recipients: rawRecipients is List
          ? [
              for (final name in rawRecipients)
                if (name is String) name,
            ]
          : const <String>[],
      timestamp: ts.toUtc(),
      sources: sources,
      primarySource: primary,
      seq: (json['seq'] as num?)?.toInt() ?? 0,
      thanked: json['thanked'] == true,
    );
  }
}

/// A stream session on one or more own channels: events between [start]
/// and [end] (plus a short grace) group under it.
class ActivitySession {
  final String id;
  final DateTime start;

  /// Null while still live
  final DateTime? end;

  /// Platforms that were live during the session
  final Set<ActivityPlatform> platforms;

  const ActivitySession({
    required this.id,
    required this.start,
    this.end,
    this.platforms = const {},
  });

  bool get isOpen => this.end == null;

  ActivitySession copyWith({
    DateTime? start,
    DateTime? end,
    bool clearEnd = false,
    Set<ActivityPlatform>? platforms,
  }) => ActivitySession(
    id: this.id,
    start: start ?? this.start,
    end: clearEnd ? null : (end ?? this.end),
    platforms: platforms ?? this.platforms,
  );

  Map<String, Object?> toJson() => {
    'id': this.id,
    'start': this.start.toUtc().toIso8601String(),
    if (this.end != null) 'end': this.end!.toUtc().toIso8601String(),
    'platforms': [for (final platform in this.platforms) platform.name],
  };

  static ActivitySession? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final start = DateTime.tryParse('${json['start']}');
    if (id is! String || start == null) return null;
    final rawPlatforms = json['platforms'];
    return ActivitySession(
      id: id,
      start: start.toUtc(),
      end: json['end'] == null
          ? null
          : DateTime.tryParse('${json['end']}')?.toUtc(),
      platforms: {
        if (rawPlatforms is List)
          for (final name in rawPlatforms) ?ActivityPlatform.parse(name),
      },
    );
  }
}
