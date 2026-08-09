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

  /// [viewerCount] when known → `LIVE · 1.2k`; omit for a plain LIVE chip.
  factory NativeChatStatusChip.live({
    Key? key,
    required Color color,
    int? viewerCount,
  }) =>
      NativeChatStatusChip(
        key: key,
        label: viewerCount == null
            ? 'LIVE'
            : 'LIVE · ${formatChatViewerCount(viewerCount)}',
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

/// Compact viewer count for LIVE chips: `999`, `1.2k`, `3.4M`.
String formatChatViewerCount(int count) {
  if (count >= 1000000) {
    final value = count / 1000000;
    if (count % 1000000 == 0) return '${value.toInt()}M';
    return '${value.toStringAsFixed(1)}M';
  }
  if (count >= 1000) {
    final value = count / 1000;
    if (count % 1000 == 0) return '${value.toInt()}k';
    return '${value.toStringAsFixed(1)}k';
  }
  return '$count';
}

/// Sheet / page titles — title2 scale so they read clearly above body
/// (`titleMedium` is 15px in the On Air theme, same as body).
TextStyle? nativeChatSheetTitleStyle(BuildContext context) =>
    Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        );

/// Section labels inside a sheet (Emotes, Badges groups, etc.).
TextStyle? nativeChatSheetSectionStyle(BuildContext context) =>
    Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
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
