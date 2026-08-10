import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../utils/styling_helper.dart';
import 'native_chat_text_field.dart';

export 'native_chat_text_field.dart'
    show
        NativeChatTextField,
        kNativeChatDockControlSize,
        kNativeChatInputOpticalOffset;

/// Chat input dock of the native chat window: pill text field + circular
/// send button when the account may write ([canSend]), or a read-only hint
/// strip when the token predates the write scope. Generic by params — no
/// Twitch types — so a future native engine reuses it as-is. Optional
/// [controller]/[focusNode]/[leading] seams let the caller compose extras
/// (e.g. an emote picker) without the dock knowing about them.
class NativeChatInput extends StatefulWidget {
  /// Whether the account's token carries write scope
  final bool canSend;

  /// A send is in flight — field + button disabled, spinner shown
  final bool inFlight;

  /// Transient send error, shown above the dock
  final String? errorText;

  /// External controller for outside text insertion (e.g. an emote
  /// picker). Ownership stays with the caller — never disposed here.
  final TextEditingController? controller;

  /// External focus node — lets the caller refocus the field (e.g. after
  /// a picker sheet closes). Ownership stays with the caller.
  final FocusNode? focusNode;

  /// Optional widget rendered left of the text field (e.g. a picker
  /// toggle). Only shown in the send-ready state, not on the lock strip.
  final Widget? leading;

  /// Optional strip rendered above the input row (e.g. a "replying to…"
  /// context line). Only shown in the send-ready state, before the
  /// [errorText] row.
  final Widget? contextStrip;

  /// Brand accent (send button, hint action)
  final Color accentColor;

  /// Delivers the trimmed message; the field clears when it completes
  /// true. Must not throw — return false on failure.
  final Future<bool> Function(String text) onSend;

  /// Starts the re-login flow from the read-only strip
  final VoidCallback onRelogin;

  const NativeChatInput({
    super.key,
    required this.canSend,
    required this.inFlight,
    required this.accentColor,
    required this.onSend,
    required this.onRelogin,
    this.errorText,
    this.controller,
    this.focusNode,
    this.leading,
    this.contextStrip,
  });

  @override
  State<NativeChatInput> createState() => _NativeChatInputState();
}

class _NativeChatInputState extends State<NativeChatInput> {
  late final TextEditingController _controller =
      this.widget.controller ?? TextEditingController();

  @override
  void dispose() {
    /// Only the internally created controller is ours to dispose.
    if (this.widget.controller == null) this._controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (this.widget.inFlight) return;
    final String text = this._controller.text.trim();
    if (text.isEmpty) return;
    this.widget.onSend(text).then((sent) {
      if (sent && this.mounted) this._controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!this.widget.canSend) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.lock_fill,
              size: 14.0,
              color: this.widget.accentColor,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Logged in read-only',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            Pressable(
              haptic: true,
              onTap: this.widget.onRelogin,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: kMinInteractiveDimensionCupertino,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Re-login to chat',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: this.widget.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final Color errorColor =
        (Theme.of(context).extension<AppStatusColors>() ??
                AppStatusColors.standard)
            .unreachable;

    return Padding(
      /// Extra bottom so the gap under the row matches the gap above to
      /// the pane divider (top [AppSpacing.sm]).
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (this.widget.contextStrip != null) ...[
            this.widget.contextStrip!,
            const SizedBox(height: AppSpacing.xs),
          ],
          if (this.widget.errorText != null) ...[
            Row(
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_circle,
                  size: 12.0,
                  color: errorColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    this.widget.errorText!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: errorColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (this.widget.leading != null) ...[
                this.widget.leading!,
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: NativeChatTextField(
                  controller: this._controller,
                  focusNode: this.widget.focusNode,
                  enabled: !this.widget.inFlight,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 500,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => this._submit(),
                  hintText: 'Send a message…',
                  focusBorderColor: this.widget.accentColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Pressable(
                haptic: true,
                onTap: this.widget.inFlight ? null : this._submit,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: kMinInteractiveDimensionCupertino,
                    minHeight: kMinInteractiveDimensionCupertino,
                  ),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: kNativeChatDockControlSize,
                    height: kNativeChatDockControlSize,
                    decoration: BoxDecoration(
                      color: this.widget.accentColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: this.widget.inFlight
                        ? (StylingHelper.isApple(context)
                            ? const CupertinoActivityIndicator(radius: 8.0)
                            : const SizedBox(
                                width: 16.0,
                                height: 16.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: Colors.white,
                                ),
                              ))
                        : const Icon(
                            CupertinoIcons.paperplane_fill,
                            size: 17.0,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
