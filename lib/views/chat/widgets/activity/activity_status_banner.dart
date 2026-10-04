import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';

import '../../../../models/enums/chat_type.dart';
import '../../../../models/youtube_auth.dart';
import '../../../../shared/design/design.dart';
import '../../../../stores/views/activity.dart';
import '../../../../stores/views/kick_chat.dart';
import '../../../../stores/views/twitch_chat.dart';
import '../../../../stores/views/youtube_chat.dart';
import '../../../../types/classes/activity/activity_event.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/enums/settings_keys.dart';
import '../../../../utils/activity/activity_ledger.dart';
import '../../../../utils/activity/activity_status.dart';
import '../../../../utils/get_it_helper.dart';
import '../../../../utils/youtube/youtube_auth_service.dart';
import '../../../../utils/youtube/youtube_live_chat_service.dart';
import '../../../dashboard/widgets/obs_widgets/stream_chat/kick_setup_sheet.dart';
import '../../../dashboard/widgets/obs_widgets/stream_chat/twitch_device_code_dialog.dart';
import '../../../dashboard/widgets/obs_widgets/stream_chat/youtube_device_code_dialog.dart';
import '../../../dashboard/widgets/obs_widgets/stream_chat/youtube_setup_sheet.dart';
import '../../../dashboard/widgets/obs_widgets/stream_chat/chat_type_brand.dart';
import 'activity_formatting.dart';

/// Gaps of the newest stream count while it runs and for this long after
const Duration kActivityStatusGapWindow = Duration(hours: 6);

/// The newest stream if it's live or ended within [kActivityStatusGapWindow]
ActivitySession? activityStatusSession(ActivityStore store, DateTime now) {
  final session = store.sessions.isEmpty ? null : store.sessions.first;
  if (session == null) return null;
  final end = session.end;
  if (end != null && now.toUtc().difference(end) > kActivityStatusGapWindow) {
    return null;
  }
  return session;
}

/// Reads the status inputs off the stores - never creates one (a YouTube
/// store would start polling). Call inside an Observer: the observables
/// read here, plus [ActivityStore.setupRevision] for what lives in Hive,
/// keep it current.
ActivityStatusInput readActivityStatusInput(ActivityStore store) {
  store.setupRevision;
  store.clockTick;
  final getIt = GetIt.instance;

  var twitchSignedIn = false;
  var twitchMissingScopes = false;
  var twitchConnection = ActivityTwitchConnection.connecting;
  if (lazySingletonCreated<TwitchChatStore>()) {
    final twitch = getIt<TwitchChatStore>();
    twitchSignedIn = twitch.isLoggedIn;
    twitchMissingScopes =
        twitchSignedIn && twitch.missingActivityScopes.isNotEmpty;
    twitchConnection = switch (twitch.chatConnection) {
      TwitchChatConnectionState.live => ActivityTwitchConnection.connected,
      TwitchChatConnectionState.failed => ActivityTwitchConnection.failed,
      _ => ActivityTwitchConnection.connecting,
    };
  }

  YouTubeAuth? youTubeAuth;
  try {
    if (Hive.isBoxOpen(HiveKeys.YouTubeAuth.name)) {
      youTubeAuth = Hive.box<YouTubeAuth>(
        HiveKeys.YouTubeAuth.name,
      ).get(YouTubeAuth.kBoxKey);
    }
  } catch (_) {}

  /// The YouTube chat knows best; without it, what it last found
  /// (mirrored to the settings box)
  final youTubeNoChannel = lazySingletonCreated<YouTubeChatStore>()
      ? getIt<YouTubeChatStore>().signedInWithoutChannel
      : Hive.isBoxOpen(HiveKeys.Settings.name) &&
            Hive.box(
                  HiveKeys.Settings.name,
                ).get(SettingsKeys.YouTubeSignedInWithoutChannel.name) ==
                true;

  var kickSignedIn = false;
  var kickUsed = false;
  if (lazySingletonCreated<KickChatStore>()) {
    final kick = getIt<KickChatStore>();
    kickSignedIn = kick.ownChannelSlug != null;
    kickUsed = kick.channels.isNotEmpty;
  }

  final now = store.now;
  final session = activityStatusSession(store, now);
  return ActivityStatusInput(
    twitchSignedIn: twitchSignedIn,
    twitchMissingScopes: twitchMissingScopes,
    twitchConnection: twitchConnection,
    youTubeConfigured: YouTubeLiveChatService.resolveApiKey().isNotEmpty,
    youTubeCanSignIn: YouTubeAuthService.configuredClientId().isNotEmpty,
    youTubeSignedIn: youTubeAuth != null,
    youTubeChannelId: youTubeAuth?.channelId,
    youTubeNoChannel: youTubeNoChannel,
    youTubeOwn: store.youTubeOwnState,
    youTubeQuotaResetAt: store.youTubeQuotaResetAt,
    kickSignedIn: kickSignedIn,
    kickUsed: kickUsed,
    kickRelayEnabled: store.relayEnabled,
    kickRelay: store.relayState,
    kickRelaySubscribed: store.relaySubscribed,
    obsLive: store.obsLive,
    obsLivePlatform: store.obsLivePlatform,
    gaps: session == null
        ? const <ActivityGap>[]
        : store.gapsOf(session, now: now),
  );
}

/// Local clock time the way the device shows it (12 / 24 h).
String formatActivityClock(BuildContext context, DateTime at) {
  final local = at.toLocal();
  final material = Localizations.of<MaterialLocalizations>(
    context,
    MaterialLocalizations,
  );
  if (material == null) return DateFormat.Hm().format(local);
  return material.formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}

void runActivityStatusAction(
  BuildContext context,
  ActivityStore store,
  ActivityStatusAction action,
) {
  switch (action) {
    case ActivityStatusAction.twitchSignIn:
      startTwitchLogin(context);
    case ActivityStatusAction.twitchRetry:
      if (lazySingletonCreated<TwitchChatStore>()) {
        GetIt.instance<TwitchChatStore>().connectChat();
      }
    case ActivityStatusAction.youTubeSetUp:
      showYouTubeSetupSheet(context);

    /// The OAuth client is set (that's when this action is offered): go
    /// straight to Google's sign-in, not the client form
    case ActivityStatusAction.youTubeSignIn:
      startYouTubeLogin(context);
    case ActivityStatusAction.youTubeSwitchAccount:
      switchYouTubeAccount(context);
    case ActivityStatusAction.kickSignIn:
      showKickSetupSheet(context);
    case ActivityStatusAction.kickRelayOn:
      Hive.box(
        HiveKeys.Settings.name,
      ).put(SettingsKeys.ActivityKickRelay.name, true).then((_) {
        store.relaySettingChanged();
      });
  }
}

enum _BannerMode { tucked, collapsed, expanded }

/// Floating status of the feed over [child] (the list), built like the
/// pinned-message banner: tucked it's a small button top-right (a dot
/// when there's news since it was last opened); a new line that needs
/// action brings it out as a one-line banner; tap expands every line with
/// its button; ✕ tucks it again.
class ActivityStatusBanner extends StatefulWidget {
  final ActivityStore store;
  final Widget child;

  const ActivityStatusBanner({
    super.key,
    required this.store,
    required this.child,
  });

  @override
  State<ActivityStatusBanner> createState() => _ActivityStatusBannerState();
}

class _ActivityStatusBannerState extends State<ActivityStatusBanner> {
  _BannerMode _mode = _BannerMode.tucked;

  /// Action lines that already brought the banner out once
  final Set<String> _poppedFor = {};

  void _setMode(_BannerMode mode, List<ActivityStatusItem> items) {
    if (mode != _BannerMode.collapsed) {
      /// Opened or put away: what it showed counts as seen
      this.widget.store.acknowledgeStatus([
        for (final item in items)
          if (item.needsAttention) item.id,
      ]);
    }
    setState(() => this._mode = mode);
  }

  /// After a build: a new unacknowledged action line pops the banner out;
  /// nothing pressing left collapses it back.
  void _follow(List<ActivityStatusItem> items) {
    final acknowledged = this.widget.store.acknowledgedStatus;
    final fresh = [
      for (final item in items)
        if (item.level == ActivityStatusLevel.action &&
            !acknowledged.contains(item.id) &&
            !this._poppedFor.contains(item.id))
          item.id,
    ];
    final pressing = items.any(
      (item) => item.needsAttention && !acknowledged.contains(item.id),
    );
    _BannerMode? next;
    if (fresh.isNotEmpty && this._mode == _BannerMode.tucked) {
      this._poppedFor.addAll(fresh);
      next = _BannerMode.collapsed;
    } else if (!pressing && this._mode == _BannerMode.collapsed) {
      next = _BannerMode.tucked;
    }
    if (next == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (this.mounted && this._mode != next) {
        setState(() => this._mode = next!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final input = readActivityStatusInput(this.widget.store);
        final items = buildActivityStatus(
          input,
          time: (at) => formatActivityClock(context, at),
        );
        final acknowledged = this.widget.store.acknowledgedStatus.toSet();
        this._follow(items);
        final unseen = items
            .where(
              (item) => item.needsAttention && !acknowledged.contains(item.id),
            )
            .length;
        return Stack(
          fit: StackFit.expand,
          children: [
            this.widget.child,
            Positioned(
              top: AppSpacing.xs,

              /// Full width for every state: the tucked button sits at its
              /// right end, the rest of the strip lets taps through
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              child: AnimatedSwitcher(
                duration: AppMotion.reduce(context)
                    ? Duration.zero
                    : AppMotion.medium,
                switchInCurve: AppMotion.emphasized,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topRight,
                  children: [...previous, ?current],
                ),
                child: switch (this._mode) {
                  _BannerMode.tucked => _TuckedButton(
                    key: const ValueKey('tucked'),
                    items: items,
                    unseen: unseen,
                    onTap: () => this._setMode(_BannerMode.expanded, items),
                  ),
                  _BannerMode.collapsed => _CollapsedBanner(
                    key: const ValueKey('collapsed'),
                    items: items,
                    onExpand: () => this._setMode(_BannerMode.expanded, items),
                    onClose: () => this._setMode(_BannerMode.tucked, items),
                  ),
                  _BannerMode.expanded => _ExpandedBanner(
                    key: const ValueKey('expanded'),
                    store: this.widget.store,
                    items: items,
                    onCollapse: () => this._setMode(_BannerMode.tucked, items),
                  ),
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

Widget _glass({required Widget child, BorderRadius? radius}) {
  final clipped = GlassBar(contentEdge: GlassBarEdge.bottom, child: child);
  if (radius == null) return ClipOval(child: clipped);
  return ClipRRect(borderRadius: radius, child: clipped);
}

ActivityStatusLevel _worst(List<ActivityStatusItem> items) => items.isEmpty
    ? ActivityStatusLevel.ok
    : items
          .map((item) => item.level)
          .reduce((a, b) => a.index <= b.index ? a : b);

Color? _levelColor(BuildContext context, ActivityStatusLevel level) {
  final status =
      Theme.of(context).extension<AppStatusColors>() ??
      AppStatusColors.standard;
  return switch (level) {
    ActivityStatusLevel.action => Theme.of(context).colorScheme.secondary,
    ActivityStatusLevel.warning => status.warning,
    ActivityStatusLevel.info => Theme.of(context).textTheme.bodySmall?.color,
    ActivityStatusLevel.ok => status.live,
  };
}

IconData _levelIcon(ActivityStatusLevel level) => switch (level) {
  ActivityStatusLevel.action => CupertinoIcons.exclamationmark_circle_fill,
  ActivityStatusLevel.warning => CupertinoIcons.exclamationmark_triangle_fill,
  ActivityStatusLevel.info => CupertinoIcons.info_circle,
  ActivityStatusLevel.ok => CupertinoIcons.dot_radiowaves_left_right,
};

class _TuckedButton extends StatelessWidget {
  final List<ActivityStatusItem> items;
  final int unseen;
  final VoidCallback onTap;

  const _TuckedButton({
    super.key,
    required this.items,
    required this.unseen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final worst = _worst(this.items);
    final pressing =
        worst == ActivityStatusLevel.action ||
        worst == ActivityStatusLevel.warning;
    return Semantics(
      button: true,
      label: this.unseen > 0 ? 'Feed status, $unseen new' : 'Feed status',
      excludeSemantics: true,
      child: Pressable(
        key: const Key('activity-status-tucked'),
        haptic: true,
        onTap: this.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _glass(
              child: SizedBox(
                width: 40.0,
                height: 40.0,
                child: Center(
                  child: Icon(
                    pressing
                        ? _levelIcon(worst)
                        : CupertinoIcons.dot_radiowaves_left_right,
                    size: 16.0,
                    color: pressing
                        ? _levelColor(context, worst)
                        : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ),
            if (this.unseen > 0)
              Positioned(
                top: 1.0,
                right: 1.0,
                child: Container(
                  key: const Key('activity-status-badge'),
                  width: 10.0,
                  height: 10.0,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).cardColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CollapsedBanner extends StatelessWidget {
  final List<ActivityStatusItem> items;
  final VoidCallback onExpand;
  final VoidCallback onClose;

  const _CollapsedBanner({
    super.key,
    required this.items,
    required this.onExpand,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = this.items.isEmpty ? null : this.items.first;
    final more = this.items.where((item) => item.needsAttention).length - 1;
    final muted = theme.textTheme.bodySmall?.color;
    return _glass(
      radius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'Show feed status',
                child: Pressable(
                  key: const Key('activity-status-collapsed'),
                  haptic: true,
                  onTap: this.onExpand,
                  child: Row(
                    children: [
                      Icon(
                        _levelIcon(top?.level ?? ActivityStatusLevel.ok),
                        size: 14.0,
                        color: _levelColor(
                          context,
                          top?.level ?? ActivityStatusLevel.ok,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          top?.text ?? 'Listening',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      if (more > 0) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '+$more',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: muted,
                          ),
                        ),
                      ],
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        CupertinoIcons.chevron_down,
                        size: 12.0,
                        color: muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Semantics(
              button: true,
              label: 'Hide feed status',
              child: Pressable(
                key: const Key('activity-status-close'),
                haptic: true,
                onTap: this.onClose,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Icon(CupertinoIcons.xmark, size: 14.0, color: muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedBanner extends StatelessWidget {
  final ActivityStore store;
  final List<ActivityStatusItem> items;
  final VoidCallback onCollapse;

  const _ExpandedBanner({
    super.key,
    required this.store,
    required this.items,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.color;
    return LayoutBuilder(
      builder: (context, constraints) => _glass(
        radius: BorderRadius.circular(AppRadius.md),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.5,
          ),
          child: Column(
            key: const Key('activity-status-expanded'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Pressable(
                haptic: true,
                onTap: this.onCollapse,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Feed status',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Hide feed status',
                        excludeSemantics: true,
                        child: Padding(
                          key: const Key('activity-status-close'),
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          child: Icon(
                            CupertinoIcons.xmark,
                            size: 14.0,
                            color: muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0.0,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (this.items.isEmpty)
                        Text(
                          'Sign in to Twitch, YouTube or Kick in the chat - '
                          'the feed then shows here what it listens to.',
                          style: theme.textTheme.bodySmall,
                        ),
                      for (final item in this.items)
                        _StatusLine(store: this.store, item: item),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final ActivityStore store;
  final ActivityStatusItem item;

  const _StatusLine({required this.store, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final platform = this.item.platform;
    final chatType = platform == null ? null : chatTypeOf(platform);
    final action = this.item.action;
    return Padding(
      key: Key('activity-status-${this.item.id}'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Icon(
              this.item.level == ActivityStatusLevel.ok && chatType != null
                  ? chatType.icon
                  : _levelIcon(this.item.level),
              size: 14.0,
              color: this.item.level == ActivityStatusLevel.ok
                  ? chatType?.brandColor ?? _levelColor(context, item.level)
                  : _levelColor(context, this.item.level),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              this.item.text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: this.item.level == ActivityStatusLevel.ok
                    ? null
                    : theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Pressable(
              key: Key('activity-status-action-${this.item.id}'),
              haptic: true,
              onTap: () => runActivityStatusAction(context, this.store, action),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  this.item.actionLabel ?? 'Fix',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
