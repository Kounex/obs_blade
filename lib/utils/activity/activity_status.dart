import '../../types/classes/activity/activity_event.dart';
import '../kick/kick_events_relay_client.dart';
import 'activity_ledger.dart';
import 'youtube_own_activity_poller.dart';

/// How much a status line asks of the user. The banner's tucked button
/// badges [action] and [warning] lines it hasn't shown yet; a new [action]
/// line brings the banner out by itself.
enum ActivityStatusLevel {
  /// Something to do so events arrive (sign in, set up)
  action,

  /// Events are being missed right now or were (connection, gap, quota)
  warning,

  /// Worth knowing, nothing broken
  info,

  /// Listening
  ok,
}

/// What a status line's button does - the banner maps it to the sheet /
/// call (this file stays UI-free).
enum ActivityStatusAction {
  twitchSignIn,
  twitchRetry,
  youTubeSetUp,
  youTubeSignIn,
  youTubeSwitchAccount,
  kickSignIn,
  kickRelayOn,
}

class ActivityStatusItem {
  /// Stable per situation - acknowledged ids are persisted
  final String id;
  final ActivityPlatform? platform;
  final ActivityStatusLevel level;
  final String text;
  final ActivityStatusAction? action;
  final String? actionLabel;

  const ActivityStatusItem({
    required this.id,
    required this.level,
    required this.text,
    this.platform,
    this.action,
    this.actionLabel,
  });

  /// Counts for the badge / pops the banner out
  bool get needsAttention =>
      this.level == ActivityStatusLevel.action ||
      this.level == ActivityStatusLevel.warning;

  @override
  String toString() => 'ActivityStatusItem($id, ${level.name}, $text)';
}

enum ActivityTwitchConnection { connected, connecting, failed }

/// Everything the status lines depend on, read off the stores (see
/// `readActivityStatusInput` in the feed) - plain values so the rules are
/// testable state by state.
class ActivityStatusInput {
  final bool twitchSignedIn;
  final bool twitchMissingScopes;
  final ActivityTwitchConnection twitchConnection;

  /// An API key is set (reads work)
  final bool youTubeConfigured;

  /// An OAuth client is set (sign-in possible)
  final bool youTubeCanSignIn;
  final bool youTubeSignedIn;
  final String? youTubeChannelId;

  /// YouTube said this account has no channel (only known while the
  /// YouTube chat exists)
  final bool youTubeNoChannel;
  final YouTubeOwnActivityState youTubeOwn;
  final DateTime? youTubeQuotaResetAt;

  final bool kickSignedIn;

  /// Kick channels are added (the user reads Kick)
  final bool kickUsed;
  final bool kickRelayEnabled;
  final KickRelayState kickRelay;
  final bool kickRelaySubscribed;

  final bool obsLive;
  final ActivityPlatform? obsLivePlatform;

  /// Gaps of the newest stream, oldest first
  final List<ActivityGap> gaps;

  const ActivityStatusInput({
    this.twitchSignedIn = false,
    this.twitchMissingScopes = false,
    this.twitchConnection = ActivityTwitchConnection.connecting,
    this.youTubeConfigured = false,
    this.youTubeCanSignIn = false,
    this.youTubeSignedIn = false,
    this.youTubeChannelId,
    this.youTubeNoChannel = false,
    this.youTubeOwn = YouTubeOwnActivityState.off,
    this.youTubeQuotaResetAt,
    this.kickSignedIn = false,
    this.kickUsed = false,
    this.kickRelayEnabled = true,
    this.kickRelay = KickRelayState.off,
    this.kickRelaySubscribed = true,
    this.obsLive = false,
    this.obsLivePlatform,
    this.gaps = const [],
  });
}

/// The status lines, most pressing first. [time] formats a moment for
/// the user (local clock).
List<ActivityStatusItem> buildActivityStatus(
  ActivityStatusInput input, {
  required String Function(DateTime at) time,
}) {
  final items = <ActivityStatusItem>[
    ..._twitch(input),
    ..._youTube(input, time),
    ..._kick(input),
    for (final gap in input.gaps.reversed) _gap(gap, time),
  ];
  items.sort((a, b) => a.level.index.compareTo(b.level.index));
  return items;
}

List<ActivityStatusItem> _twitch(ActivityStatusInput input) {
  const platform = ActivityPlatform.twitch;
  if (!input.twitchSignedIn) {
    if (input.obsLivePlatform != platform) return const [];
    return const [
      ActivityStatusItem(
        id: 'twitch-signin',
        platform: platform,
        level: ActivityStatusLevel.action,
        text:
            'You\'re live on Twitch - sign in so follows, subs and cheers '
            'land here.',
        action: ActivityStatusAction.twitchSignIn,
        actionLabel: 'Sign in',
      ),
    ];
  }
  return [
    if (input.twitchMissingScopes)
      const ActivityStatusItem(
        id: 'twitch-scopes',
        platform: platform,
        level: ActivityStatusLevel.action,
        text:
            'Sign in to Twitch again to add cheers, Power-ups, channel '
            'points and hype trains.',
        action: ActivityStatusAction.twitchSignIn,
        actionLabel: 'Sign in again',
      ),
    switch (input.twitchConnection) {
      ActivityTwitchConnection.connected => const ActivityStatusItem(
        id: 'twitch-ok',
        platform: platform,
        level: ActivityStatusLevel.ok,
        text: 'Twitch · listening',
      ),
      ActivityTwitchConnection.connecting => const ActivityStatusItem(
        id: 'twitch-connecting',
        platform: platform,
        level: ActivityStatusLevel.info,
        text: 'Twitch · connecting…',
      ),
      ActivityTwitchConnection.failed => const ActivityStatusItem(
        id: 'twitch-failed',
        platform: platform,
        level: ActivityStatusLevel.warning,
        text:
            'Twitch isn\'t connected - follows, subs and cheers don\'t '
            'arrive right now.',
        action: ActivityStatusAction.twitchRetry,
        actionLabel: 'Retry',
      ),
    },
  ];
}

List<ActivityStatusItem> _youTube(
  ActivityStatusInput input,
  String Function(DateTime) time,
) {
  const platform = ActivityPlatform.youtube;
  final liveThere = input.obsLivePlatform == platform;
  if (!input.youTubeConfigured) {
    if (!liveThere) return const [];
    return const [
      ActivityStatusItem(
        id: 'youtube-setup',
        platform: platform,
        level: ActivityStatusLevel.action,
        text:
            'You\'re live on YouTube - set up YouTube so Super Chats and '
            'memberships land here.',
        action: ActivityStatusAction.youTubeSetUp,
        actionLabel: 'Set up',
      ),
    ];
  }
  if (!input.youTubeSignedIn) {
    return [
      ActivityStatusItem(
        id: 'youtube-signin',
        platform: platform,
        level: liveThere
            ? ActivityStatusLevel.action
            : ActivityStatusLevel.info,
        text:
            '${liveThere ? 'You\'re live on YouTube - sign' : 'Sign'} in to '
            'YouTube so Super Chats and memberships on your channel land '
            'here. An API key alone can\'t tell which channel is yours.',
        action: input.youTubeCanSignIn
            ? ActivityStatusAction.youTubeSignIn
            : ActivityStatusAction.youTubeSetUp,
        actionLabel: input.youTubeCanSignIn ? 'Sign in' : 'Set up sign-in',
      ),
    ];
  }
  if (input.youTubeChannelId == null) {
    if (input.youTubeNoChannel) {
      return const [
        ActivityStatusItem(
          id: 'youtube-nochannel',
          platform: platform,
          level: ActivityStatusLevel.action,
          text:
              'This Google account has no YouTube channel - switch to the '
              'account that owns yours.',
          action: ActivityStatusAction.youTubeSwitchAccount,
          actionLabel: 'Switch account',
        ),
      ];
    }

    /// The lookup at sign-in failed (network) - a new sign-in repeats it
    return [
      ActivityStatusItem(
        id: 'youtube-nochannel-yet',
        platform: platform,
        level: liveThere
            ? ActivityStatusLevel.action
            : ActivityStatusLevel.info,
        text:
            'YouTube · your channel couldn\'t be looked up at sign-in - sign '
            'in again so Super Chats on it land here.',
        action: ActivityStatusAction.youTubeSignIn,
        actionLabel: 'Sign in again',
      ),
    ];
  }
  return [
    switch (input.youTubeOwn) {
      YouTubeOwnActivityState.quotaExhausted => ActivityStatusItem(
        id: 'youtube-quota',
        platform: platform,
        level: ActivityStatusLevel.warning,
        text:
            'YouTube\'s daily API quota is used up - Super Chats arrive '
            'again after '
            '${input.youTubeQuotaResetAt == null ? 'midnight Pacific time' : time(input.youTubeQuotaResetAt!)}.',
      ),
      YouTubeOwnActivityState.live ||
      YouTubeOwnActivityState.standby => const ActivityStatusItem(
        id: 'youtube-ok',
        platform: platform,
        level: ActivityStatusLevel.ok,
        text: 'YouTube · listening',
      ),
      _ => const ActivityStatusItem(
        id: 'youtube-waiting',
        platform: platform,
        level: ActivityStatusLevel.ok,
        text: 'YouTube · waiting for your stream',
      ),
    },
  ];
}

List<ActivityStatusItem> _kick(ActivityStatusInput input) {
  const platform = ActivityPlatform.kick;
  if (!input.kickSignedIn) {
    if (!input.kickUsed) return const [];
    return const [
      ActivityStatusItem(
        id: 'kick-signin',
        platform: platform,
        level: ActivityStatusLevel.info,
        text:
            'Sign in to Kick so follows, KICKs and subs on your channel land '
            'here.',
        action: ActivityStatusAction.kickSignIn,
        actionLabel: 'Sign in',
      ),
    ];
  }
  if (!input.kickRelayEnabled) {
    return const [
      ActivityStatusItem(
        id: 'kick-relay-off',
        platform: platform,
        level: ActivityStatusLevel.info,
        text:
            'Kick follows and KICKs are off - subs and gifts only arrive '
            'while your Kick chat is open.',
        action: ActivityStatusAction.kickRelayOn,
        actionLabel: 'Turn on',
      ),
    ];
  }
  return [
    switch (input.kickRelay) {
      KickRelayState.synced when !input.kickRelaySubscribed =>
        const ActivityStatusItem(
          id: 'kick-partial',
          platform: platform,
          level: ActivityStatusLevel.info,
          text:
              'Kick · listening - Kick hasn\'t accepted every event yet, '
              'retrying',
        ),
      KickRelayState.synced => const ActivityStatusItem(
        id: 'kick-ok',
        platform: platform,
        level: ActivityStatusLevel.ok,
        text: 'Kick · listening, also while the app is closed',
      ),
      KickRelayState.retrying => const ActivityStatusItem(
        id: 'kick-retrying',
        platform: platform,
        level: ActivityStatusLevel.warning,
        text:
            'Reconnecting to Kick follows, KICKs and subs… nothing is lost, '
            'they arrive once it\'s back.',
      ),
      _ => const ActivityStatusItem(
        id: 'kick-connecting',
        platform: platform,
        level: ActivityStatusLevel.info,
        text: 'Kick · connecting…',
      ),
    },
  ];
}

ActivityStatusItem _gap(ActivityGap gap, String Function(DateTime) time) {
  final span = gap.end == null
      ? 'since ${time(gap.start)}'
      : '${time(gap.start)}–${time(gap.end!)}';
  final (String name, String missing) = switch (gap.platform) {
    ActivityPlatform.twitch => (
      'Twitch',
      'subs, cheers and raids from then are missing (follows were filled in)',
    ),
    ActivityPlatform.youtube => (
      'YouTube',
      'Super Chats and memberships from then may be missing',
    ),
    ActivityPlatform.kick => ('Kick', 'subs and gifts from then are missing'),
  };
  return ActivityStatusItem(
    id: gap.id,
    platform: gap.platform,
    level: ActivityStatusLevel.warning,
    text: '$name: not listening $span - $missing.',
  );
}
