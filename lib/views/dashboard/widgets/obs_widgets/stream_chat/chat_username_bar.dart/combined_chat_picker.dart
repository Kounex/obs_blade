import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/general/base/button.dart';
import '../../../../../../shared/general/themed/cupertino_button.dart';
import '../../../../../../stores/views/combined_chat.dart';
import '../../../../../../types/classes/combined/combined_combo.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';
import '../chat_type_brand.dart';
import '../combined_chat_builder_sheet.dart';
import '../combined_chat_icon.dart';
import '../combined_sources_sheet.dart';
import '../native_chat_chrome.dart';

/// One line naming a combo's channels. Same-name channels (a streamer on
/// all platforms) read as one name + the platforms ("LVNDMARK on Twitch,
/// YouTube, Kick") instead of the name three times; mixed names list
/// every channel.
String combinedSourcesSubtitle(List<CombinedSource> sources) {
  final names = {for (final s in sources) s.label.toLowerCase()};
  final platforms = sources.map((s) => s.platform.text).join(', ');
  if (names.length == 1) return '${sources.first.label} on $platforms';
  return sources.map((s) => s.label).join(' · ');
}

/// Connection problems worth a marker — a healthy (or plainly offline)
/// connection shows nothing: green / "live" are reserved for on air.
enum CombinedIssue {
  connecting,

  /// Failed, or the platform needs the user (sign in / set up).
  attention,
}

CombinedIssue? combinedIssueOf(CombinedSourceStatus? status) =>
    switch (status) {
      CombinedSourceStatus.connecting => CombinedIssue.connecting,
      CombinedSourceStatus.error ||
      CombinedSourceStatus.needsSetup => CombinedIssue.attention,
      _ => null,
    };

/// Short label for a source's connection state in chip rows / sheets —
/// null for the quiet states (connected, offline).
String? combinedIssueLabel(CombinedSourceStatus? status) => switch (status) {
  CombinedSourceStatus.connecting => 'Connecting…',
  CombinedSourceStatus.needsSetup => 'Needs setup',
  CombinedSourceStatus.error => 'Failed',
  _ => null,
};

/// Small corner marker of a connection issue: an amber spinner while
/// connecting, a red ⚠ when it needs the user.
class CombinedIssueMarker extends StatelessWidget {
  final CombinedIssue issue;
  final double size;

  /// Ring around the marker (the surface under it) so it reads on top of
  /// a badge.
  final Color? ring;

  const CombinedIssueMarker({
    super.key,
    required this.issue,
    this.size = 14.0,
    this.ring,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppStatusColors>() ??
        AppStatusColors.standard;
    final color = this.issue == CombinedIssue.connecting
        ? colors.warning
        : colors.unreachable;
    return Semantics(
      label: this.issue == CombinedIssue.connecting
          ? 'connecting'
          : 'needs attention',
      child: Container(
        width: this.size,
        height: this.size,
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(color: this.ring, shape: BoxShape.circle),
        child: this.issue == CombinedIssue.connecting
            ? CircularProgressIndicator(strokeWidth: 1.8, color: color)
            : Container(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  '!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: this.size * 0.62,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
      ),
    );
  }
}

/// The combined card's on-air summary: `LIVE · 2 · 3.1k` in the LIVE
/// chip style while any source is on air (count of live sources, total
/// known viewers), a muted "Offline" otherwise.
class CombinedLiveSummary extends StatelessWidget {
  final Map<ChatType, int?> live;

  /// Distinguishes several summaries on one screen (switcher tiles).
  final String keySuffix;

  const CombinedLiveSummary({
    super.key,
    required this.live,
    this.keySuffix = '',
  });

  @override
  Widget build(BuildContext context) {
    if (this.live.isEmpty) {
      return Text(
        'Offline',
        key: Key('combined-summary-offline${this.keySuffix}'),
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final viewers = this.live.values.whereType<int>().fold<int>(
      0,
      (sum, count) => sum + count,
    );
    final hasViewers = this.live.values.any((count) => count != null);
    final colors =
        Theme.of(context).extension<AppStatusColors>() ??
        AppStatusColors.standard;
    return NativeChatStatusChip(
      key: Key('combined-summary-live${this.keySuffix}'),
      label: this.live.length > 1 ? 'LIVE · ${this.live.length}' : 'LIVE',
      color: colors.live,
      viewerCountLabel: hasViewers ? formatChatViewerCount(viewers) : null,
    );
  }
}

/// The combined chat's channel control: a full-width card under the
/// chat-type row (the bar gives Combined its own row — it has no engine
/// switch or account pill competing for the space). Shows the combo's
/// platforms as an overlapping badge stack with live dots, its name and
/// its channels; tapping opens [CombinedChatSwitcherSheet].
class CombinedChatPicker extends StatelessWidget {
  const CombinedChatPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final store = GetIt.instance<CombinedChatStore>();
        final combo = store.selectedCombo;
        final sources = store.activeSources;
        final statuses = store.sourceStatus;
        final live = store.liveSources;
        final issues = statuses.values
            .where((status) => combinedIssueOf(status) != null)
            .length;
        final muted = Theme.of(context).textTheme.bodySmall;

        final String subtitle = sources.isEmpty
            ? 'Sign in natively to Twitch, YouTube or Kick'
            : combinedSourcesSubtitle(sources);

        return Semantics(
          button: true,
          label:
              '${combo?.displayName ?? 'My chats'}, '
              '${live.isEmpty ? 'offline' : '${live.length} on air'}'
              '${issues > 0 ? ', $issues need attention' : ''}. '
              'Switch combined chat',
          excludeSemantics: true,
          child: Pressable(
            key: const Key('combined-combo-card'),
            haptic: true,
            onTap: () => showCombinedChatSwitcherSheet(context),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56.0),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: StylingHelper.lightenDarkenColor(
                  Theme.of(context).cardColor,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                  width: 0.0,
                ),
              ),
              child: Row(
                children: [
                  CombinedBadgeStack(
                    platforms: [for (final s in sources) s.platform],
                    statuses: statuses,
                    live: live.keys.toSet(),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                combo?.displayName ?? 'My chats',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (combo == null && sources.isNotEmpty) ...[
                              const SizedBox(width: AppSpacing.xs),
                              NativeChatYouChip(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: muted,
                        ),
                      ],
                    ),
                  ),
                  if (sources.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.sm),
                    CombinedLiveSummary(live: live),
                    if (issues > 0) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Row(
                        key: const Key('combined-summary-issues'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CombinedIssueMarker(
                            issue: CombinedIssue.attention,
                          ),
                          if (issues > 1) ...[
                            const SizedBox(width: 2.0),
                            Text('$issues', style: muted),
                          ],
                        ],
                      ),
                    ],
                  ],
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    CupertinoIcons.chevron_up_chevron_down,
                    size: 16.0,
                    color: muted?.color,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Overlapping square platform badges (a combo's "avatar stack"). A
/// badge whose streamer is on air ([live]) wears a ring in the live
/// color; a connection problem adds a corner [CombinedIssueMarker]. A
/// healthy, offline source is a plain badge. Empty → one neutral
/// placeholder tile.
class CombinedBadgeStack extends StatelessWidget {
  final List<ChatType> platforms;
  final Map<ChatType, CombinedSourceStatus> statuses;
  final Set<ChatType> live;
  final double size;

  const CombinedBadgeStack({
    super.key,
    required this.platforms,
    this.statuses = const {},
    this.live = const {},
    this.size = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    final surface = StylingHelper.lightenDarkenColor(
      Theme.of(context).cardColor,
    );

    /// Light overlap: enough to read as one group, while every badge's
    /// status dot (bottom-right corner) stays fully visible.
    final overlap = this.size * 0.18;
    if (this.platforms.isEmpty) {
      return Container(
        width: this.size,
        height: this.size,
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        alignment: Alignment.center,
        child: CombinedChatIcon(size: this.size * 0.75),
      );
    }
    final width =
        this.size + (this.platforms.length - 1) * (this.size - overlap);
    return SizedBox(
      width: width + 4.0,
      height: this.size + 4.0,
      child: Stack(
        clipBehavior: Clip.none,

        /// Painted last-to-first: each badge sits above the one to its
        /// right, so its corner dot is never covered by a neighbour.
        children: [
          for (var i = this.platforms.length - 1; i >= 0; i--)
            Positioned(
              left: i * (this.size - overlap),
              top: 0,
              child: _StackBadge(
                platform: this.platforms[i],
                size: this.size,
                ring: surface,
                onAir: this.live.contains(this.platforms[i]),
                issue: combinedIssueOf(this.statuses[this.platforms[i]]),
              ),
            ),
        ],
      ),
    );
  }
}

class _StackBadge extends StatelessWidget {
  final ChatType platform;
  final double size;
  final Color ring;
  final bool onAir;
  final CombinedIssue? issue;

  const _StackBadge({
    required this.platform,
    required this.size,
    required this.ring,
    required this.onAir,
    required this.issue,
  });

  @override
  Widget build(BuildContext context) {
    final brand =
        this.platform.brandColor ?? Theme.of(context).colorScheme.secondary;
    final glyph = ThemeData.estimateBrightnessForColor(brand) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          key: Key('combined-stack-${this.platform.name}'),
          width: this.size,
          height: this.size,
          decoration: BoxDecoration(
            color: brand,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: this.onAir
                  ? (Theme.of(context).extension<AppStatusColors>() ??
                            AppStatusColors.standard)
                        .live
                  : this.ring,
              width: this.onAir ? 2.5 : 2.0,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(this.platform.icon, size: this.size * 0.55, color: glyph),
        ),
        if (this.onAir)
          Positioned(
            key: Key('combined-stack-live-${this.platform.name}'),
            left: 0,
            right: 0,
            bottom: -5.0,
            child: const Center(child: _LivePip()),
          ),
        if (this.issue case final issue?)
          Positioned(
            right: -5.0,
            top: -5.0,
            child: CombinedIssueMarker(
              key: Key('combined-stack-issue-${this.platform.name}'),
              issue: issue,
              ring: this.ring,
            ),
          ),
      ],
    );
  }
}

/// Tiny "LIVE" tab under an on-air badge (the ring alone is easy to miss
/// on a green brand like Kick's).
class _LivePip extends StatelessWidget {
  const _LivePip();

  @override
  Widget build(BuildContext context) {
    final live =
        (Theme.of(context).extension<AppStatusColors>() ??
                AppStatusColors.standard)
            .live;

    /// No contrasting outline: the pip is the ring's own green, so the two
    /// read as one shape.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      decoration: BoxDecoration(
        color: live,
        borderRadius: BorderRadius.circular(3.0),
      ),
      child: const Text(
        'LIVE',
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          color: Colors.black,
          fontSize: 6.0,
          fontWeight: FontWeight.w900,
          height: 1.2,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Switch between "My chats" and the saved combos, create a new one, or
/// manage / edit the one shown.
Future<void> showCombinedChatSwitcherSheet(BuildContext context) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      enableDrag: true,
      maxHeightFraction: 0.8,
      builder: (_) => CombinedChatSwitcherSheet(hostContext: context),
    );

/// Every combo shows who's on air (rings + LIVE summary), not only the
/// one on screen: the platforms' per-channel live data covers all listed
/// channels ([CombinedChatStore.liveSourcesOf]); opening the sheet asks
/// for a fresh round. Connection markers stay with the shown combo —
/// the others aren't connected.
class CombinedChatSwitcherSheet extends StatefulWidget {
  /// The chat bar's context — follow-up sheets open on it, not on this
  /// sheet (which closes first).
  final BuildContext hostContext;

  const CombinedChatSwitcherSheet({super.key, required this.hostContext});

  @override
  State<CombinedChatSwitcherSheet> createState() =>
      _CombinedChatSwitcherSheetState();
}

class _CombinedChatSwitcherSheetState extends State<CombinedChatSwitcherSheet> {
  BuildContext get hostContext => this.widget.hostContext;

  @override
  void initState() {
    super.initState();
    GetIt.instance<CombinedChatStore>().refreshLivePreviews();
  }

  void _then(BuildContext context, void Function() action) {
    Navigator.of(context).pop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    return NativeChatSheetScaffold(
      headerGap: AppSpacing.sm,
      header: Text('Combined chats', style: nativeChatSheetTitleStyle(context)),
      body: Observer(
        builder: (_) {
          final store = GetIt.instance<CombinedChatStore>();
          final mine = [for (final s in store.mySources) s.platform];
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ComboTile(
                key: const Key('combined-combo-tile-my'),
                id: kMyChatsComboId,
                platforms: mine,
                statuses: store.selectedComboId == kMyChatsComboId
                    ? store.sourceStatus
                    : const {},
                live: store.selectedComboId == kMyChatsComboId
                    ? store.liveSources
                    : store.liveSourcesOf(store.mySources),
                title: 'My chats',
                subtitle: mine.isEmpty
                    ? 'Your own channels - sign in natively to start'
                    : 'Your own channels on ${mine.map((p) => p.text).join(', ')}',
                own: true,
                selected: store.selectedComboId == kMyChatsComboId,
                actionLabel: 'Manage',
                onTap: () => this._then(
                  context,
                  () => store.selectCombo(kMyChatsComboId),
                ),
                onAction: () => this._then(
                  context,
                  () => showCombinedSourcesSheet(
                    this.hostContext,
                    comboId: kMyChatsComboId,
                  ),
                ),
              ),
              for (final combo in store.combos)
                _ComboTile(
                  key: Key('combined-combo-tile-${combo.id}'),
                  id: combo.id,
                  platforms: combo.platforms,
                  statuses: store.selectedComboId == combo.id
                      ? store.sourceStatus
                      : const {},
                  live: store.selectedComboId == combo.id
                      ? store.liveSources
                      : store.liveSourcesOf(store.sourcesOf(combo)),
                  title: combo.displayName,
                  subtitle: _comboChannels(combo),
                  selected: store.selectedComboId == combo.id,
                  actionLabel: 'Edit',
                  onTap: () =>
                      this._then(context, () => store.selectCombo(combo.id)),
                  onAction: () => this._then(
                    context,
                    () => showCombinedChatBuilderSheet(
                      this.hostContext,
                      combo: combo,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              BaseButton(
                key: const Key('combined-new-combo'),
                secondary: true,
                icon: const Icon(CupertinoIcons.plus, size: 18.0),
                text: 'New combined chat',
                onPressed: () => this._then(
                  context,
                  () => showCombinedChatBuilderSheet(this.hostContext),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Combine any channels - one per platform. Handy for '
                'moderating or following a streamer across platforms.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }

  static String _comboChannels(CombinedCombo combo) => [
    if (combo.twitch case final ref?) 'Twitch: ${ref.displayName}',
    if (combo.youTube case final yt?) 'YouTube: ${yt.label}',
    if (combo.kickSlug case final slug?) 'Kick: $slug',
  ].join(' · ');
}

class _ComboTile extends StatelessWidget {
  /// Combo id ([kMyChatsComboId] for "My chats") — keys the tile's parts.
  final String id;
  final List<ChatType> platforms;

  /// Connection issues — only for the combo on screen (the others aren't
  /// connected).
  final Map<ChatType, CombinedSourceStatus> statuses;

  /// On-air sources (platform → viewers) — for every combo.
  final Map<ChatType, int?> live;
  final String title;
  final String subtitle;
  final bool own;
  final bool selected;
  final String actionLabel;
  final VoidCallback onTap;
  final VoidCallback onAction;

  const _ComboTile({
    super.key,
    required this.id,
    required this.platforms,
    this.statuses = const {},
    this.live = const {},
    required this.title,
    required this.subtitle,
    this.own = false,
    required this.selected,
    required this.actionLabel,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        (Theme.of(context).extension<AppTextColors>() ?? AppTextColors.standard)
            .highlightText;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Pressable(
        haptic: true,
        onTap: this.onTap,
        child: Container(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: this.selected
                ? accent.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: this.selected
                  ? accent.withValues(alpha: 0.5)
                  : Theme.of(context).dividerColor.withValues(alpha: 0.4),
              width: this.selected ? 1.0 : 0.0,
            ),
          ),
          child: Row(
            children: [
              CombinedBadgeStack(
                platforms: this.platforms,
                statuses: this.statuses,
                live: this.live.keys.toSet(),
                size: 26.0,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            this.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (this.selected) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            CupertinoIcons.checkmark_alt,
                            size: 16.0,
                            color: accent,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      this.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (this.live.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      CombinedLiveSummary(
                        live: this.live,
                        keySuffix: '-${this.id}',
                      ),
                    ],
                  ],
                ),
              ),
              ThemedCupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                text: this.actionLabel,
                onPressed: this.onAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
