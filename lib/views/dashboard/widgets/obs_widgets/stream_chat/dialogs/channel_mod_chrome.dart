import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../types/classes/chat/chat_ban_entry.dart';
import '../../../../../../utils/styling_helper.dart';
import '../native_chat_chrome.dart';

/// Shared rows of the channel mod panels (Twitch / Kick / YouTube): one
/// look for every platform, standalone or as a tab of the combined sheet.

/// Section title inside a channel mod panel.
class ChannelModSectionHeader extends StatelessWidget {
  final String title;

  const ChannelModSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
    child: Text(this.title, style: nativeChatSheetSectionStyle(context)),
  );
}

/// Tappable action row (44pt) — icon, label, optional trailing widget.
/// A null [onTap] renders it disabled.
class ChannelModActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;
  final Widget? trailing;

  /// Swaps the label with [CountUpText] (live counters).
  final bool animateLabel;

  const ChannelModActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.trailing,
    this.animateLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = this.destructive
        ? (Theme.of(context).extension<AppStatusColors>() ??
                  AppStatusColors.standard)
              .destructive
        : Theme.of(context).textTheme.bodyMedium?.color ??
              CupertinoColors.label;
    final TextStyle? labelStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: color);
    return Pressable(
      haptic: true,
      onTap: this.onTap,
      child: Opacity(
        opacity: this.onTap == null ? 0.5 : 1.0,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: kMinInteractiveDimensionCupertino,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
              Icon(this.icon, size: 18.0, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: this.animateLabel
                    ? CountUpText(value: this.label, style: labelStyle)
                    : Text(this.label, style: labelStyle),
              ),
              if (this.trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                this.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Read-only status line (a chat mode the API can't change).
class ChannelModStatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String status;
  final bool active;

  const ChannelModStatusRow({
    super.key,
    required this.icon,
    required this.label,
    required this.status,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(this.icon, size: 18.0, color: muted?.color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(this.label)),
          Text(
            this.status,
            style: this.active
                ? muted?.copyWith(
                    color:
                        (Theme.of(context).extension<AppTextColors>() ??
                                AppTextColors.standard)
                            .highlightText,
                    fontWeight: FontWeight.w600,
                  )
                : muted,
          ),
        ],
      ),
    );
  }
}

/// Small print under a section (API limits, empty states).
class ChannelModNote extends StatelessWidget {
  final String text;

  const ChannelModNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.xs),
    child: Text(this.text, style: Theme.of(context).textTheme.bodySmall),
  );
}

/// "banned · by mod" / "timeout until 14:05 · by mod" for a ban entry.
String chatBanSubtitle(ChatBanEntry ban, DateTime now) {
  final expires = ban.expiresAt;
  final String kind;
  if (expires == null) {
    kind = 'Banned';
  } else if (!expires.isAfter(now)) {
    kind = 'Timeout ended';
  } else {
    final local = expires.toLocal();
    kind =
        'Timeout until ${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
  return ban.bannedBy == null ? kind : '$kind · by ${ban.bannedBy}';
}

/// One ban in a panel's list; [onUnban] null = can't be lifted from here
/// ([unavailableHint] explains why).
class ChannelModBanRow extends StatelessWidget {
  final ChatBanEntry ban;
  final VoidCallback? onUnban;
  final String? unavailableHint;

  const ChannelModBanRow({
    super.key,
    required this.ban,
    required this.onUnban,
    this.unavailableHint,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall;
    final subtitle = chatBanSubtitle(this.ban, DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
      child: Row(
        children: [
          Icon(
            this.ban.isTimeout ? CupertinoIcons.timer : CupertinoIcons.nosign,
            size: 18.0,
            color: muted?.color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  this.ban.userName ?? this.ban.userId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  this.onUnban == null && this.unavailableHint != null
                      ? '$subtitle · ${this.unavailableHint}'
                      : subtitle,
                  style: muted,
                ),
              ],
            ),
          ),
          if (this.onUnban != null)
            Pressable(
              key: Key('channel-mod-unban-${this.ban.userId}'),
              haptic: true,
              onTap: this.onUnban,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: kMinInteractiveDimensionCupertino,
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                alignment: Alignment.center,
                child: Text(
                  this.ban.isTimeout ? 'Lift' : 'Unban',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        (Theme.of(context).extension<AppTextColors>() ??
                                AppTextColors.standard)
                            .highlightText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Standalone frame of a channel mod panel: padding, drag handle, a
/// height-capped scroll body. The combined sheet uses its own frame (tabs
/// above) and embeds the panels without this.
class ChannelModSheetFrame extends StatelessWidget {
  final Widget child;

  const ChannelModSheetFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.lg,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [nativeChatSheetDragHandle(context), this.child],
    ),
  );
}

/// Snackbar on [context] (the chat pane's — sheets pop first).
void showChannelModToast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

/// Compact accent-text button next to a panel's text field.
class ChannelModInlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const ChannelModInlineButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Pressable(
    haptic: true,
    onTap: this.onTap,
    child: Opacity(
      opacity: this.onTap == null ? 0.5 : 1.0,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: kMinInteractiveDimensionCupertino,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        alignment: Alignment.center,
        child: Text(
          this.label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color:
                (Theme.of(context).extension<AppTextColors>() ??
                        AppTextColors.standard)
                    .highlightText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}
