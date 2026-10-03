import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';

import '../../../../models/enums/chat_type.dart';
import '../../../../models/youtube_auth.dart';
import '../../../../shared/design/design.dart';
import '../../../../shared/general/base/button.dart';
import '../../../../shared/general/base/divider.dart';
import '../../../../stores/pro_store.dart';
import '../../../../stores/shared/tabs.dart';
import '../../../../stores/views/activity.dart';
import '../../../../stores/views/kick_chat.dart';
import '../../../../stores/views/twitch_chat.dart';
import '../../../../stores/views/youtube_chat.dart';
import '../../../../types/classes/activity/activity_event.dart';
import '../../../../utils/activity/activity_ledger.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../utils/get_it_helper.dart';
import '../../../../utils/icons/jam_icons.dart';
import '../../../../utils/routing_helper.dart';
import '../../../dashboard/widgets/obs_widgets/stream_chat/chat_type_brand.dart';
import '../../../settings/widgets/accent_icon_tile.dart';
import 'activity_formatting.dart';
import 'activity_sheets.dart';
import 'activity_status_banner.dart';

ActivityStore? activityStoreOrNull() =>
    GetIt.instance.isRegistered<ActivityStore>()
    ? GetIt.instance<ActivityStore>()
    : null;

/// The activity feed pane - Chat tab segment, tablet side pane and the
/// streaming-mode sheet all render this. While it is on screen it holds
/// the "new since you last looked" divider still; leaving marks
/// everything it showed as seen.
class ActivityFeed extends StatefulWidget {
  /// Paywall route on the host tab's navigator (upsell button)
  final String? proRoute;

  /// Rendered in a bottom sheet (no card frame of its own)
  final bool inSheet;

  /// Tab the feed lives in - tabs stay mounted ([IndexedStack]), so the
  /// feed counts as on screen only while its tab is the active one. Null
  /// (sheets): on screen while built.
  final Tabs? hostTab;

  const ActivityFeed({
    super.key,
    this.proRoute,
    this.inSheet = false,
    this.hostTab,
  });

  @override
  State<ActivityFeed> createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  ActivityStore? _store;

  /// A visit is open (counted in the store) - while on screen
  bool _visiting = false;
  ReactionDisposer? _tabReaction;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    this._store = activityStoreOrNull();
    final getIt = GetIt.instance;
    if (this.widget.hostTab != null && getIt.isRegistered<TabsStore>()) {
      this._tabReaction = reaction<Tabs>(
        (_) => getIt<TabsStore>().activeTab,
        (_) => this._sync(),
      );
    }
    this._lifecycle = AppLifecycleListener(onStateChange: (_) => this._sync());
    this._sync();
  }

  bool get _onScreen {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
      return false;
    }
    final tab = this.widget.hostTab;
    final getIt = GetIt.instance;
    if (tab == null || !getIt.isRegistered<TabsStore>()) return true;
    return getIt<TabsStore>().activeTab == tab;
  }

  void _sync() {
    final store = this._store;
    if (store == null) return;
    final visible = this.mounted && this._onScreen;
    if (visible && !this._visiting) {
      this._visiting = true;
      store.beginVisit();
    } else if (!visible && this._visiting) {
      this._visiting = false;
      store.endVisit();
    }
  }

  @override
  void dispose() {
    this._tabReaction?.call();
    this._lifecycle?.dispose();
    if (this._visiting) this._store?.endVisit();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = this._store;
    final Widget content = store == null
        ? const SizedBox.shrink()
        : Observer(
            builder: (context) {
              if (!GetIt.instance<ProStore>().isPro) {
                return ActivityProUpsell(
                  proRoute:
                      this.widget.proRoute ?? HomeTabRoutingKeys.Pro.route,
                );
              }
              return _FeedBody(store: store);
            },
          );
    if (this.widget.inSheet) return content;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          width: 0.0,
        ),
      ),
      child: content,
    );
  }
}

class _FeedBody extends StatelessWidget {
  final ActivityStore store;

  const _FeedBody({required this.store});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final groups = this.store.groups;
        final toThank = this.store.toThankCount;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FeedHeader(store: this.store, toThank: toThank),
            const BaseDivider(),
            _FilterRow(store: this.store),
            Expanded(
              child: ActivityStatusBanner(
                store: this.store,
                child: !this.store.loaded
                    ? const Center(child: CupertinoActivityIndicator())
                    : groups.isEmpty
                    ? _EmptyFeed(store: this.store)
                    : _GroupedList(store: this.store, groups: groups),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeedHeader extends StatelessWidget {
  final ActivityStore store;
  final int toThank;

  const _FeedHeader({required this.store, required this.toThank});

  /// Own Observer: reads store observables the parent doesn't track
  @override
  Widget build(BuildContext context) =>
      Observer(builder: (context) => this._content(context));

  Widget _content(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.secondary;
    final bool on = this.store.toThankOnly;
    return LayoutBuilder(
      builder: (context, constraints) =>
          this._build(context, accent, on, constraints.maxWidth < 330.0),
    );
  }

  Widget _build(BuildContext context, Color accent, bool on, bool compact) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: kMinInteractiveDimensionCupertino,
      ),
      padding: const EdgeInsets.only(left: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Activity',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Semantics(
            button: true,
            toggled: on,
            label: 'Show only the $toThank to thank',
            excludeSemantics: true,
            child: Pressable(
              key: const Key('activity-to-thank'),
              haptic: true,
              springy: false,
              onTap: () => this.store.setToThankOnly(!on),
              child: Container(
                height: 28.0,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: on
                      ? accent.withValues(alpha: 0.18)
                      : Theme.of(context).dividerColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.pill,
                  border: Border.all(
                    color: on
                        ? accent.withValues(alpha: 0.6)
                        : Theme.of(context).dividerColor.withValues(alpha: 0.4),
                    width: 0.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      on ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                      size: 14.0,
                      color: on ? accent : null,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      /// Narrow panes (tablet split, 320 pt phones) keep
                      /// just the count
                      compact ? '$toThank' : 'To thank · $toThank',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Activity options',
            excludeSemantics: true,
            child: Pressable(
              key: const Key('activity-options'),
              haptic: true,
              springy: false,
              onTap: () => showActivityOptionsSheet(context),
              child: const SizedBox(
                width: kMinInteractiveDimensionCupertino,
                height: kMinInteractiveDimensionCupertino,
                child: Icon(CupertinoIcons.ellipsis_circle, size: 20.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final ActivityStore store;

  const _FilterRow({required this.store});

  static const Map<ActivityFilter, String> _labels = {
    ActivityFilter.all: 'All',
    ActivityFilter.money: 'Money',
    ActivityFilter.subs: 'Subs',
    ActivityFilter.follows: 'Follows',
    ActivityFilter.raids: 'Raids',
    ActivityFilter.points: 'Points',
  };

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.secondary;
    return SizedBox(
      height: 44.0,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        children: [
          for (final entry in _labels.entries)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Observer(
                builder: (context) {
                  final selected = this.store.filter == entry.key;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: '${entry.value} filter',
                    excludeSemantics: true,
                    child: Pressable(
                      key: Key('activity-filter-${entry.key.name}'),
                      springy: false,
                      onTap: () => this.store.setFilter(entry.key),
                      child: AnimatedContainer(
                        duration: AppMotion.fast,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? accent
                              : Theme.of(
                                  context,
                                ).dividerColor.withValues(alpha: 0.12),
                          borderRadius: AppRadius.pill,
                        ),
                        child: Text(
                          entry.value,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Theme.of(context).colorScheme.onSecondary
                                    : null,
                              ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  final ActivityStore store;

  const _EmptyFeed({required this.store});

  /// Own Observer: the sign-in state it reads changes without any feed
  /// row changing (signing in next to it on a tablet)
  @override
  Widget build(BuildContext context) =>
      Observer(builder: (context) => this._content(context));

  Widget _content(BuildContext context) {
    final filtered =
        this.store.filter != ActivityFilter.all || this.store.toThankOnly;
    final String title;
    final String body;
    if (filtered && this.store.allEvents.isNotEmpty) {
      title = this.store.toThankOnly ? 'All thanked' : 'Nothing here';
      body = this.store.toThankOnly
          ? 'Every sub, gift and tip has been thanked.'
          : 'Nothing of this kind yet.';
    } else if (!_anyOwnChannel()) {
      title = 'No channel connected';
      body =
          'Sign in to Twitch, YouTube or Kick in the chat. Follows, subs, '
          'cheers, Super Chats and KICKs on your channels show up here.';
    } else {
      title = 'Nothing yet';
      body =
          'Follows, subs, cheers, Super Chats and KICKs on your own channels '
          'show up here while you\'re live - Twitch and Kick follows also '
          'from while the app was closed.';
    }
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AccentIconTile(
              icon: CupertinoIcons.bell,
              size: 56.0,
              iconSize: 26.0,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  bool _anyOwnChannel() {
    this.store.setupRevision;
    final getIt = GetIt.instance;
    if (lazySingletonCreated<TwitchChatStore>() &&
        getIt<TwitchChatStore>().isLoggedIn) {
      return true;
    }
    if (lazySingletonCreated<KickChatStore>() &&
        getIt<KickChatStore>().ownChannelSlug != null) {
      return true;
    }
    if (_ownYouTubeChannel()) return true;
    return activityStoreOrNull()?.allEvents.isNotEmpty ?? false;
  }

  /// Signed in to YouTube with a channel - read off the stored session, so
  /// the YouTube store (whose poll spends API quota) isn't created here.
  static bool _ownYouTubeChannel() {
    if (lazySingletonCreated<YouTubeChatStore>()) {
      return GetIt.instance<YouTubeChatStore>().ownChannel != null;
    }
    if (!Hive.isBoxOpen(HiveKeys.YouTubeAuth.name)) return false;
    return Hive.box<YouTubeAuth>(
          HiveKeys.YouTubeAuth.name,
        ).get(YouTubeAuth.kBoxKey)?.channelId !=
        null;
  }
}

class _GroupedList extends StatelessWidget {
  final ActivityStore store;
  final List<ActivityGroup> groups;

  const _GroupedList({required this.store, required this.groups});

  /// Own Observer: reads store observables the parent doesn't track
  @override
  Widget build(BuildContext context) =>
      Observer(builder: (context) => this._content(context));

  Widget _content(BuildContext context) {
    final now = DateTime.now();

    /// Only what each line needs - rows are built as they scroll in
    final items = <Object>[];
    final rowIndex = <String, int>{};
    var dividerPlaced = false;
    var sawNew = false;
    for (final group in this.groups) {
      items.add(group);

      /// Newest first, like the rows: a gap's marker sits above the first
      /// row older than its end
      final session = group.session;
      final gaps = session == null
          ? <ActivityGap>[]
          : this.store.gapsOf(session).reversed.toList();
      void placeGaps(DateTime? before) {
        while (gaps.isNotEmpty &&
            (before == null ||
                gaps.first.end == null ||
                !before.isAfter(gaps.first.end!))) {
          items.add(_GapMarker(gap: gaps.removeAt(0)));
        }
      }

      for (final event in group.events) {
        placeGaps(event.timestamp);
        final isNew = this.store.isNew(event);

        /// Under the newest run of unseen rows: everything above is new
        if (!dividerPlaced && sawNew && !isNew) {
          items.add(const _NewDivider());
          dividerPlaced = true;
        }
        sawNew = sawNew || isNew;
        rowIndex[event.id] = items.length;
        items.add((event, isNew));
      }
      placeGaps(null);
    }
    return ListView.builder(
      key: const Key('activity-list'),
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      itemCount: items.length,

      /// Rows keep their state (swipe) when rows above come and go
      findChildIndexCallback: (key) =>
          key is ValueKey<String> ? rowIndex[key.value] : null,
      itemBuilder: (context, index) => switch (items[index]) {
        final ActivityGroup group => _GroupHeader(
          group: group,
          now: now,

          /// The banner's tucked button (40 + 8 from the edge) floats over
          /// the first header's end
          trailingInset: index == 0 ? 36.0 : 0.0,
          onThankAll: () => this.store.markThanked(group.events),
        ),
        (final ActivityEvent event, final bool isNew) => ActivityRow(
          key: ValueKey(event.id),
          event: event,
          isNew: isNew,
          now: now,
          onThanked: (thanked) => this.store.setThanked(event, thanked),
          onTap: () => showActivityPersonSheet(context, event),
        ),
        final Widget widget => widget,
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final ActivityGroup group;
  final DateTime now;
  final double trailingInset;
  final VoidCallback onThankAll;

  const _GroupHeader({
    required this.group,
    required this.now,
    required this.onThankAll,
    this.trailingInset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final totals = formatActivityTotals(this.group.totals);
    final open = this.group.events
        .where((event) => event.isBig && !event.thanked)
        .length;
    final live = this.group.session?.isOpen ?? false;
    final statusColors =
        Theme.of(context).extension<AppStatusColors>() ??
        AppStatusColors.standard;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + this.trailingInset,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (live) ...[
                Container(
                  width: 7.0,
                  height: 7.0,
                  decoration: BoxDecoration(
                    color: statusColors.live,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  activityGroupTitle(this.group, now: this.now).toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: live ? statusColors.live : null,
                  ),
                ),
              ),
            ],
          ),
          if (totals != null || open > 0) ...[
            const SizedBox(height: 2.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: totals == null
                      ? const SizedBox.shrink()
                      : Text(
                          totals,
                          key: Key('activity-totals-${this.group.key}'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                ),
                if (open > 0)
                  Flexible(
                    child: Semantics(
                      button: true,
                      label: open == 1
                          ? 'Mark 1 thanked'
                          : 'Mark all $open thanked',
                      excludeSemantics: true,
                      child: Pressable(
                        key: Key('activity-thank-all-${this.group.key}'),
                        haptic: true,
                        springy: false,
                        onTap: this.onThankAll,
                        child: Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.sm),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.checkmark_circle,
                                size: 14.0,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Flexible(
                                child: Text(
                                  'Mark $open thanked',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Where the app wasn't listening during a stream - rows from then may be
/// missing.
class _GapMarker extends StatelessWidget {
  final ActivityGap gap;

  const _GapMarker({required this.gap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warning =
        (theme.extension<AppStatusColors>() ?? AppStatusColors.standard)
            .warning;
    final name = chatTypeOf(this.gap.platform).text;
    final end = this.gap.end;
    final span = end == null
        ? 'since ${formatActivityClock(context, this.gap.start)}'
        : '${formatActivityClock(context, this.gap.start)}–'
              '${formatActivityClock(context, end)}';
    return Padding(
      key: Key('activity-gap-${this.gap.id}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.waveform_path_badge_minus,
            size: 14.0,
            color: warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Not listening on $name $span - rows may be missing',
              style: theme.textTheme.labelSmall?.copyWith(color: warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewDivider extends StatelessWidget {
  const _NewDivider();

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.secondary;
    return Padding(
      key: const Key('activity-new-divider'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(child: Container(height: 1.0, color: accent)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              'New since you last looked',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Container(height: 1.0, color: accent)),
        ],
      ),
    );
  }
}

/// One feed row. Swipe right toggles thanked (the row stays); tap opens
/// the person's history.
class ActivityRow extends StatelessWidget {
  final ActivityEvent event;
  final bool isNew;
  final DateTime now;
  final ValueChanged<bool> onThanked;
  final VoidCallback onTap;

  /// Compact: person sheet history (no swipe, no new bar)
  final bool compact;

  const ActivityRow({
    super.key,
    required this.event,
    required this.isNew,
    required this.now,
    required this.onThanked,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color accent = theme.colorScheme.secondary;
    final statusColors =
        theme.extension<AppStatusColors>() ?? AppStatusColors.standard;
    final chatType = chatTypeOf(this.event.platform);
    final detail = activityDetailText(this.event);
    final message = this.event.message;
    final bool toThank = this.event.isBig && !this.event.thanked;

    final Widget row = Pressable(
      springy: false,
      onTap: this.onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44.0),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: this.isNew && !this.compact ? accent : Colors.transparent,
              width: 3.0,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md - 3.0,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Icon(
                chatType.icon,
                size: 16.0,
                color: chatType.brandColor ?? accent,
                semanticLabel: chatType.text,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: activityActorName(this.event),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' ${activityActionText(this.event)}'),
                      ],
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (detail != null)
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  if (message != null && message.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        '“${message.trim()}”',
                        maxLines: this.compact ? 1 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatActivityAge(this.event.timestamp, now: this.now),
                  style: theme.textTheme.labelSmall,
                ),
                if (this.event.isBig) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Icon(
                    this.event.thanked
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.heart,
                    size: 16.0,
                    color: this.event.thanked ? statusColors.live : accent,
                    semanticLabel: this.event.thanked ? 'Thanked' : 'To thank',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
    if (this.compact) return row;

    return Dismissible(
      key: ValueKey('swipe-${this.event.id}'),
      direction: DismissDirection.startToEnd,
      dismissThresholds: const {DismissDirection.startToEnd: 0.3},
      confirmDismiss: (_) async {
        this.onThanked(!this.event.thanked);
        return false;
      },
      background: Container(
        color: (toThank ? statusColors.live : theme.disabledColor).withValues(
          alpha: 0.25,
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              toThank
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.arrow_uturn_left,
              size: 18.0,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              toThank ? 'Thanked' : 'Not thanked',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      child: Semantics(
        customSemanticsActions: {
          CustomSemanticsAction(
            label: this.event.thanked ? 'Mark not thanked' : 'Mark thanked',
          ): () =>
              this.onThanked(!this.event.thanked),
        },
        child: row,
      ),
    );
  }
}

/// Activity for non-Pro users: what it is, and the way to Pro.
class ActivityProUpsell extends StatelessWidget {
  final String proRoute;

  const ActivityProUpsell({super.key, required this.proRoute});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AccentIconTile(
              icon: JamIcons.padlock,
              size: 64.0,
              iconSize: 30.0,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Activity', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Every follow, sub, cheer, Super Chat and KICKs gift on your '
              'channels in one list - with a to-thank queue so nobody gets '
              'missed on stream. Part of OBS Blade Pro.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            const SizedBox(height: AppSpacing.md),
            BaseButton(
              text: 'Explore Pro',
              onPressed: () => Navigator.of(context).pushNamed(this.proRoute),
            ),
          ],
        ),
      ),
    );
  }
}
