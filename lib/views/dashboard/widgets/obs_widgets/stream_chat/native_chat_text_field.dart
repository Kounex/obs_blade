import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../utils/styling_helper.dart';

/// Visual height of dock controls and matching compose fields.
/// Hit targets stay at [kMinInteractiveDimensionCupertino]; chrome is
/// bottom-aligned inside them so it shares a baseline with the field.
const double kNativeChatDockControlSize = 40.0;

/// Optical nudge — Material [TextField] fill/border sits ~2px high vs
/// plain sibling chrome when bottom-/stretch-aligned in a row.
const double kNativeChatInputOpticalOffset = 2.0;

/// Shared filled text field chrome for native chat surfaces (dock,
/// emote draft/search, add-chat search) — same height, padding, fill,
/// and optical offset.
class NativeChatTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final bool obscureText;
  final Widget? prefixIcon;
  final BoxConstraints? prefixIconConstraints;
  final Color? focusBorderColor;
  final Key? fieldKey;

  /// When false, skip the Material optical nudge (rare — prefer default).
  final bool applyOpticalOffset;

  const NativeChatTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.obscureText = false,
    this.prefixIcon,
    this.prefixIconConstraints,
    this.focusBorderColor,
    this.fieldKey,
    this.applyOpticalOffset = true,
  });

  @override
  Widget build(BuildContext context) {
    final mutedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        width: 0.0,
      ),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(
        color: this.focusBorderColor ??
            Theme.of(context).dividerColor.withValues(alpha: 0.4),
        width: this.focusBorderColor == null ? 0.0 : 1.0,
      ),
    );

    final field = TextField(
      key: this.fieldKey,
      controller: this.controller,
      focusNode: this.focusNode,
      enabled: this.enabled,
      obscureText: this.obscureText,
      minLines: this.minLines,
      maxLines: this.maxLines,
      maxLength: this.maxLength,
      textInputAction: this.textInputAction,
      onChanged: this.onChanged,
      onSubmitted: this.onSubmitted,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: StylingHelper.lightenDarkenColor(
          Theme.of(context).cardColor,
        ),
        hintText: this.hintText,
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
        prefixIcon: this.prefixIcon,
        prefixIconConstraints: this.prefixIconConstraints,
        counterText: this.maxLength == null ? null : '',
        constraints: const BoxConstraints(
          minHeight: kNativeChatDockControlSize,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: mutedBorder,
        enabledBorder: mutedBorder,
        focusedBorder: focusedBorder,
      ),
    );

    if (!this.applyOpticalOffset) return field;
    return Transform.translate(
      offset: const Offset(0, kNativeChatInputOpticalOffset),
      child: field,
    );
  }
}
