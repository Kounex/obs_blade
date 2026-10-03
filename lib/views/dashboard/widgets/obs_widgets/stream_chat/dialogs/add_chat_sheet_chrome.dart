import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../utils/styling_helper.dart';
import '../native_chat_chrome.dart';
import '../native_chat_text_field.dart';

/// Shared building blocks of the "Add chat" pickers (Twitch, YouTube,
/// Kick): one frame, one row, one set of loading / error / hint states,
/// so the three platforms read the same.

/// Handle, title, search field and the capped scrolling list, plus an
/// optional [footer] below the list (e.g. a re-login strip).
class AddChatSheetFrame extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final Widget body;
  final Widget? footer;

  const AddChatSheetFrame({
    super.key,
    required this.title,
    required this.controller,
    required this.onChanged,
    required this.hintText,
    required this.body,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final listMaxHeight = MediaQuery.sizeOf(context).height * 0.45;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          nativeChatSheetDragHandle(context),
          Text(this.title, style: nativeChatSheetTitleStyle(context)),
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.md,
            ),
            child: NativeChatTextField(
              controller: this.controller,
              onChanged: this.onChanged,
              hintText: this.hintText,
              prefixIcon: const Icon(CupertinoIcons.search, size: 16.0),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 36.0,
                minHeight: 0.0,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: listMaxHeight),
            child: SingleChildScrollView(child: this.body),
          ),
          if (this.footer case final footer?) ...[
            const SizedBox(height: AppSpacing.sm),
            footer,
          ],
        ],
      ),
    );
  }
}

class AddChatSectionHeader extends StatelessWidget {
  final String title;

  const AddChatSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Text(this.title, style: nativeChatSheetSectionStyle(context)),
  );
}

class AddChatLoading extends StatelessWidget {
  /// Search results get more room than a section's spinner.
  final bool large;

  const AddChatLoading({super.key, this.large = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(this.large ? AppSpacing.lg : AppSpacing.sm),
    child: Center(
      child: StylingHelper.isApple(context)
          ? const CupertinoActivityIndicator()
          : const CircularProgressIndicator(),
    ),
  );
}

/// Inline "something failed" row with an optional trailing action
/// (Retry by default).
class AddChatErrorRow extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  const AddChatErrorRow({
    super.key,
    this.message = 'Could not load this list',
    this.onRetry,
    this.retryLabel = 'Retry',
  });

  @override
  Widget build(BuildContext context) {
    final onRetry = this.onRetry;
    return Row(
      children: [
        Icon(
          CupertinoIcons.exclamationmark_triangle,
          size: 14.0,
          color:
              (Theme.of(context).extension<AppStatusColors>() ??
                      AppStatusColors.standard)
                  .destructive,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text(
              this.message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        if (onRetry != null)
          AddChatTextAction(label: this.retryLabel, onTap: onRetry),
      ],
    );
  }
}

/// Highlight-tinted text button with a 44 pt touch target.
class AddChatTextAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const AddChatTextAction({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Pressable(
    haptic: true,
    onTap: this.onTap,
    child: Container(
      constraints: const BoxConstraints(
        minHeight: kMinInteractiveDimensionCupertino,
      ),
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      alignment: Alignment.center,
      child: Text(
        this.label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color:
              (Theme.of(context).extension<AppTextColors>() ??
                      AppTextColors.standard)
                  .highlightText,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

/// Centered icon + short text: "No channels found", "Type at least 3
/// characters", the empty state of a sheet without quick picks.
class AddChatHint extends StatelessWidget {
  final IconData icon;
  final String text;

  const AddChatHint({
    super.key,
    this.icon = CupertinoIcons.search,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final textColors =
        Theme.of(context).extension<AppTextColors>() ?? AppTextColors.standard;
    return StaggeredEntrance(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(this.icon, size: 28.0, color: textColors.textOrnament),
            const SizedBox(height: AppSpacing.xs),
            Text(
              this.text,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: textColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

/// One pickable channel: name (+ verified seal), subtitle, then a fixed
/// check slot (already added), LIVE (+ viewers) and Mod chips. Added rows
/// are dimmed and inert; [busy] swaps the check slot for a spinner while
/// the pick resolves (e.g. naming a pasted YouTube link).
class AddChatChannelRow extends StatelessWidget {
  /// Scopes the chip keys (`add-chat-live-<scope>-<id>`) per list.
  final String chipScope;
  final String id;
  final String displayName;
  final String subtitle;
  final bool added;
  final bool live;
  final int? viewerCount;
  final bool mod;
  final bool verified;
  final bool busy;
  final IconData? leadingIcon;
  final VoidCallback? onAdd;

  const AddChatChannelRow({
    super.key,
    required this.chipScope,
    required this.id,
    required this.displayName,
    required this.subtitle,
    required this.added,
    this.live = false,
    this.viewerCount,
    this.mod = false,
    this.verified = false,
    this.busy = false,
    this.leadingIcon,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final statusColors =
        Theme.of(context).extension<AppStatusColors>() ??
        AppStatusColors.standard;
    final textColors =
        Theme.of(context).extension<AppTextColors>() ?? AppTextColors.standard;
    return Pressable(
      haptic: true,
      onTap: this.added || this.busy ? null : this.onAdd,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: kMinInteractiveDimensionCupertino,
        ),
        alignment: Alignment.centerLeft,
        child: Opacity(
          opacity: this.added ? 0.5 : 1.0,
          child: Row(
            children: [
              if (this.leadingIcon case final icon?) ...[
                Icon(icon, size: 18.0, color: textColors.highlightText),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            this.displayName,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        if (this.verified) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            CupertinoIcons.checkmark_seal_fill,
                            key: Key('add-chat-verified-${this.id}'),
                            size: 13.0,
                            color: textColors.textTertiary,
                            semanticLabel: 'Verified',
                          ),
                        ],
                      ],
                    ),
                    if (this.subtitle.isNotEmpty)
                      Text(
                        this.subtitle,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),

              /// Reserved check slot left of LIVE so viewer chips share a
              /// column whether or not the channel is already added.
              SizedBox(
                width: 18.0 + AppSpacing.xs,
                child: this.busy
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox.square(
                          dimension: 14.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        ),
                      )
                    : this.added
                    ? Icon(
                        Icons.check,
                        size: 18.0,
                        color: textColors.highlightText,
                      )
                    : null,
              ),
              if (this.live)
                NativeChatStatusChip.live(
                  key: Key('add-chat-live-${this.chipScope}-${this.id}'),
                  color: statusColors.live,
                  viewerCount: this.viewerCount,
                ),
              if (this.mod) ...[
                const SizedBox(width: AppSpacing.xs),
                NativeChatStatusChip.mod(
                  key: Key('add-chat-mod-${this.chipScope}-${this.id}'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// `1234` → `1.2K`, `1118300` → `1.1M` — follower / subscriber counts in
/// row subtitles.
String formatAddChatCount(int count) {
  String trim(double value) {
    final text = value.toStringAsFixed(value >= 100 ? 0 : 1);
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }

  if (count >= 1000000) return '${trim(count / 1000000)}M';
  if (count >= 1000) return '${trim(count / 1000)}K';
  return '$count';
}
