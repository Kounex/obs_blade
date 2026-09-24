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
import '../combined_sources_sheet.dart';
import '../native_chat_chrome.dart';

/// Status dot color for a combined source — null draws no dot (offline /
/// unknown reads as "nothing happening", not as an error).
Color? combinedStatusDotColor(
  BuildContext context,
  CombinedSourceStatus? status,
) {
  final colors =
      Theme.of(context).extension<AppStatusColors>() ??
      AppStatusColors.standard;
  return switch (status) {
    CombinedSourceStatus.live => colors.live,
    CombinedSourceStatus.connecting => colors.warning,
    CombinedSourceStatus.error ||
    CombinedSourceStatus.needsSetup => colors.unreachable,
    CombinedSourceStatus.offline || null => null,
  };
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
        final live = statuses.values
            .where((status) => status == CombinedSourceStatus.live)
            .length;
        final muted = Theme.of(context).textTheme.bodySmall;

        final String subtitle = sources.isEmpty
            ? 'Sign in natively to Twitch, YouTube or Kick'
            : sources.map((source) => source.label).join(' · ');

        return Semantics(
          button: true,
          label:
              '${combo?.displayName ?? 'My chats'}, $live of '
              '${sources.length} live. Switch combined chat',
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
                    Text(
                      '$live/${sources.length} live',
                      key: const Key('combined-combo-live-count'),
                      style: muted,
                    ),
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

/// Overlapping square platform badges (a combo's "avatar stack"), each
/// with its status dot. Empty → one neutral placeholder tile.
class CombinedBadgeStack extends StatelessWidget {
  final List<ChatType> platforms;
  final Map<ChatType, CombinedSourceStatus> statuses;
  final double size;

  const CombinedBadgeStack({
    super.key,
    required this.platforms,
    this.statuses = const {},
    this.size = 26.0,
  });

  @override
  Widget build(BuildContext context) {
    final surface = StylingHelper.lightenDarkenColor(
      Theme.of(context).cardColor,
    );
    final overlap = this.size * 0.3;
    if (this.platforms.isEmpty) {
      return Container(
        width: this.size,
        height: this.size,
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          ChatType.Combined.icon,
          size: this.size * 0.6,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      );
    }
    final width =
        this.size + (this.platforms.length - 1) * (this.size - overlap);
    return SizedBox(
      width: width + 3.0,
      height: this.size + 3.0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < this.platforms.length; i++)
            Positioned(
              left: i * (this.size - overlap),
              top: 0,
              child: _StackBadge(
                platform: this.platforms[i],
                size: this.size,
                ring: surface,
                dot: combinedStatusDotColor(
                  context,
                  this.statuses[this.platforms[i]],
                ),
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
  final Color? dot;

  const _StackBadge({
    required this.platform,
    required this.size,
    required this.ring,
    required this.dot,
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
            border: Border.all(color: this.ring, width: 2.0),
          ),
          alignment: Alignment.center,
          child: Icon(this.platform.icon, size: this.size * 0.55, color: glyph),
        ),
        if (this.dot != null)
          Positioned(
            right: -3.0,
            bottom: -3.0,
            child: Container(
              width: 10.0,
              height: 10.0,
              decoration: BoxDecoration(
                color: this.dot,
                shape: BoxShape.circle,
                border: Border.all(color: this.ring, width: 2.0),
              ),
            ),
          ),
      ],
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

class CombinedChatSwitcherSheet extends StatelessWidget {
  /// The chat bar's context — follow-up sheets open on it, not on this
  /// sheet (which closes first).
  final BuildContext hostContext;

  const CombinedChatSwitcherSheet({super.key, required this.hostContext});

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
                platforms: mine,
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
                  () => showCombinedSourcesSheet(this.hostContext),
                ),
              ),
              for (final combo in store.combos)
                _ComboTile(
                  key: Key('combined-combo-tile-${combo.id}'),
                  platforms: combo.platforms,
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
  final List<ChatType> platforms;
  final String title;
  final String subtitle;
  final bool own;
  final bool selected;
  final String actionLabel;
  final VoidCallback onTap;
  final VoidCallback onAction;

  const _ComboTile({
    super.key,
    required this.platforms,
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
              CombinedBadgeStack(platforms: this.platforms, size: 24.0),
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
