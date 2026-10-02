import 'package:intl/intl.dart';

import '../../../../models/enums/chat_type.dart';
import '../../../../stores/views/activity.dart';
import '../../../../types/classes/activity/activity_event.dart';

/// Text for the activity feed. Pure - tests pin the wording.

ChatType chatTypeOf(ActivityPlatform platform) => switch (platform) {
  ActivityPlatform.twitch => ChatType.Twitch,
  ActivityPlatform.youtube => ChatType.YouTube,
  ActivityPlatform.kick => ChatType.Kick,
};

String _count(num value) => NumberFormat.decimalPattern().format(value);

String _plural(num value, String one, String many) =>
    '${_count(value)} ${value == 1 ? one : many}';

/// `$5.00`, `1,200 bits`, `500 KICKs`, `3 months`, ...
String formatActivityAmount(ActivityAmount amount) {
  if (amount.display != null && amount.display!.isNotEmpty) {
    return amount.display!;
  }
  if (amount.isCurrency) {
    try {
      return NumberFormat.simpleCurrency(
        name: amount.unit,
      ).format(amount.value);
    } catch (_) {
      return '${amount.value.toStringAsFixed(2)} ${amount.unit}';
    }
  }
  return switch (amount.unit) {
    ActivityUnit.bits => _plural(amount.value, 'bit', 'bits'),
    ActivityUnit.kicks => '${_count(amount.value)} KICKs',
    ActivityUnit.viewers => _plural(amount.value, 'viewer', 'viewers'),
    ActivityUnit.months => _plural(amount.value, 'month', 'months'),
    ActivityUnit.subs => _plural(amount.value, 'sub', 'subs'),
    ActivityUnit.points => _plural(amount.value, 'point', 'points'),
    ActivityUnit.level => 'level ${_count(amount.value)}',
    _ => '${_count(amount.value)} ${amount.unit}',
  };
}

/// Twitch plan codes → words; anything else (YouTube level names, KICKs
/// gift tiers) passes through.
String? formatActivityTier(ActivityEvent event) {
  final tier = event.tier;
  if (tier == null || tier.isEmpty) return null;
  if (event.platform == ActivityPlatform.twitch) {
    return switch (tier) {
      'prime' => 'Prime',
      '1000' => 'Tier 1',
      '2000' => 'Tier 2',
      '3000' => 'Tier 3',
      _ => null,
    };
  }
  if (event.kind == ActivityKind.kicks) return null;
  return tier;
}

/// Who: the actor, or a stand-in when there is none.
String activityActorName(ActivityEvent event) {
  if (event.kind == ActivityKind.hypeTrain) return 'Hype train';
  if (event.actor.anonymous || event.actor.name.isEmpty) return 'Anonymous';
  return event.actor.name;
}

/// What, after the name: "gifted 5 subs", "cheered 500 bits".
String activityActionText(ActivityEvent event) {
  final amount = event.amount;
  final amountText = amount == null ? null : formatActivityAmount(amount);
  switch (event.kind) {
    case ActivityKind.follow:
      return 'followed';
    case ActivityKind.sub:
      return event.title ?? 'subscribed';
    case ActivityKind.resub:
      return amount == null ? 'resubscribed' : 'resubscribed · $amountText';
    case ActivityKind.giftSub:
      final count = amount?.value ?? event.recipients.length;
      if (count <= 1 && event.recipients.length == 1) {
        return 'gifted a sub to ${event.recipients.single}';
      }
      return count <= 0
          ? 'gifted subs'
          : 'gifted ${_plural(count, 'sub', 'subs')}';
    case ActivityKind.raid:
      return amount == null ? 'raided' : 'raided with $amountText';
    case ActivityKind.host:
      return amount == null ? 'hosted' : 'hosted with $amountText';
    case ActivityKind.cheer:
      return amount == null ? 'cheered' : 'cheered $amountText';
    case ActivityKind.redemption:
      return event.title == null
          ? 'redeemed a reward'
          : 'redeemed ${event.title}';
    case ActivityKind.hypeTrain:
      final level = amount == null ? '' : ' at level ${_count(amount.value)}';
      return event.title == 'ended' ? 'ended$level' : 'running$level';
    case ActivityKind.charity:
      final cause = event.title == null ? '' : ' to ${event.title}';
      return amount == null ? 'donated$cause' : 'donated $amountText$cause';
    case ActivityKind.superChat:
      return amount == null ? 'sent a Super Chat' : 'Super Chat · $amountText';
    case ActivityKind.superSticker:
      return amount == null
          ? 'sent a Super Sticker'
          : 'Super Sticker · $amountText';
    case ActivityKind.member:
      return event.title == 'Upgraded'
          ? 'upgraded membership'
          : 'became a member';
    case ActivityKind.memberMilestone:
      return amount == null ? 'membership milestone' : 'member for $amountText';
    case ActivityKind.memberGift:
      return amount == null
          ? 'gifted memberships'
          : 'gifted ${_plural(amount.value, 'membership', 'memberships')}';
    case ActivityKind.kicks:
      return amount == null ? 'sent KICKs' : 'sent $amountText';
    case ActivityKind.tip:
      return amount == null ? 'tipped' : 'tipped $amountText';
    case ActivityKind.merch:
      return 'bought merch';
    case ActivityKind.other:
      return 'did something';
  }
}

/// Small grey line under the action: tier, reward cost, gift name, ...
String? activityDetailText(ActivityEvent event) {
  final parts = <String>[
    ?formatActivityTier(event),
    if (event.kind == ActivityKind.redemption && event.amount != null)
      formatActivityAmount(event.amount!),
    if (event.kind == ActivityKind.kicks && event.title != null) event.title!,
    if (event.kind == ActivityKind.superSticker && event.title != null)
      event.title!,
    if (event.kind == ActivityKind.giftSub && event.recipients.length > 1)
      _recipientsText(event.recipients),
    if (event.kind == ActivityKind.hypeTrain && event.recipients.isNotEmpty)
      'top: ${event.recipients.take(3).join(', ')}',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

String _recipientsText(List<String> recipients) {
  if (recipients.length <= 3) return 'to ${recipients.join(', ')}';
  return 'to ${recipients.take(2).join(', ')} and ${recipients.length - 2} more';
}

/// "This stream" totals: money first (never converted - each currency /
/// bits / KICKs on its own), then counts. Null when there is nothing.
String? formatActivityTotals(ActivityTotals totals) {
  final currencies = <String>[];
  final platformMoney = <String>[];
  final units = totals.amounts.keys.toList()..sort();
  for (final unit in units) {
    final text = formatActivityAmount(
      ActivityAmount(totals.amounts[unit]!, unit),
    );
    if (ActivityUnit.isCurrency(unit)) {
      currencies.add(text);
    } else {
      platformMoney.add(text);
    }
  }
  final parts = <String>[
    ...currencies,
    ...platformMoney,
    if (totals.subs > 0) _plural(totals.subs, 'sub', 'subs'),
    if (totals.follows > 0) _plural(totals.follows, 'follow', 'follows'),
    if (totals.raids > 0) _plural(totals.raids, 'raid', 'raids'),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

String _clock(DateTime time) {
  final local = time.toLocal();
  final use24h = DateFormat.jm().pattern?.contains('H') ?? true;
  return use24h
      ? DateFormat('HH:mm').format(local)
      : DateFormat.jm().format(local);
}

String _day(DateTime day, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(day.year, day.month, day.day);
  final diff = today.difference(date).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return DateFormat('EEE d MMM').format(date);
}

/// Group header: "Live now · since 19:58", "Stream · Yesterday · 19:58 –
/// 22:10", "Today".
String activityGroupTitle(ActivityGroup group, {DateTime? now}) {
  final current = (now ?? DateTime.now()).toLocal();
  final session = group.session;
  if (session == null) return _day(group.day, current);
  if (session.isOpen) return 'Live now · since ${_clock(session.start)}';
  return 'Stream · ${_day(session.start.toLocal(), current)} · '
      '${_clock(session.start)} – ${_clock(session.end!)}';
}

/// Row time: "now", "4m", "2h", else the clock time.
String formatActivityAge(DateTime time, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final age = current.difference(time);
  if (age.inSeconds < 60) return 'now';
  if (age.inMinutes < 60) return '${age.inMinutes}m';
  if (age.inHours < 12) return '${age.inHours}h';
  return _clock(time);
}

/// Badge text: 1..99, then 99+.
String activityBadgeText(int count) => count > 99 ? '99+' : '$count';
