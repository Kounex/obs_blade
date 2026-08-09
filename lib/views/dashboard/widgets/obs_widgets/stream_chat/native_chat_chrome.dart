import 'package:flutter/material.dart';

import '../../../../../../shared/design/design.dart';

/// Compact LIVE / Mod chip used in the add-chat picker and the native
/// chat header — same visual language in both places.
class NativeChatStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const NativeChatStatusChip({
    super.key,
    required this.label,
    required this.color,
  });

  factory NativeChatStatusChip.live({Key? key, required Color color}) =>
      NativeChatStatusChip(
        key: key,
        label: 'LIVE',
        color: color,
      );

  factory NativeChatStatusChip.mod({Key? key, required Color color}) =>
      NativeChatStatusChip(
        key: key,
        label: 'Mod',
        color: color,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2.0,
      ),
      decoration: BoxDecoration(
        color: this.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: this.color.withValues(alpha: 0.55),
          width: 1.0,
        ),
      ),
      child: Text(
        this.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: this.color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

/// Sheet / page titles — heavier than body so headers read as chrome.
TextStyle? nativeChatSheetTitleStyle(BuildContext context) =>
    Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        );

/// Section labels inside a sheet (Emotes, Badges groups, etc.).
TextStyle? nativeChatSheetSectionStyle(BuildContext context) =>
    Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        );

/// Thin hairline matching native chat message separators.
Widget nativeChatHairline(BuildContext context) => Divider(
      height: 1.0,
      thickness: 0.5,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
    );

/// Drag handle for dismissible chat sheets.
Widget nativeChatSheetDragHandle(BuildContext context) => Center(
      child: Container(
        width: 36.0,
        height: 4.0,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
          borderRadius: AppRadius.pill,
        ),
      ),
    );
