import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../stores/views/youtube_chat.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';
import '../native_chat_chrome.dart';
import '../native_chat_options_sheet.dart';
import '../youtube_device_code_dialog.dart';
import '../youtube_setup_sheet.dart';

/// Entry point in the native-mode chat bar for YouTube: opens
/// [YouTubeChatOptionsSheet]. Styled like [NativeChatOptionsButton] —
/// same container idiom, 44pt touch target.
class YouTubeChatOptionsButton extends StatelessWidget {
  const YouTubeChatOptionsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Native chat options',
      child: Pressable(
        haptic: true,
        onTap: () => ModalHandler.showBaseBottomSheet(
          context: context,
          barrierDismissible: true,
          enableDrag: true,
          maxHeightFraction: 0.72,
          builder: (sheetContext) =>
              YouTubeChatOptionsSheet(hostContext: context),
        ),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: kMinInteractiveDimensionCupertino,
            minHeight: kMinInteractiveDimensionCupertino,
          ),
          decoration: BoxDecoration(
            color:
                StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
              width: 0.0,
            ),
          ),
          child: const Icon(
            CupertinoIcons.slider_horizontal_3,
            size: 18.0,
          ),
        ),
      ),
    );
  }
}

/// Minimal options for the native YouTube chat: account (sign in/out),
/// setup (API key / OAuth client) and the shared Appearance page. No mod
/// sheets here — per-message actions live on the message long-press.
class YouTubeChatOptionsSheet extends StatelessWidget {
  /// Context of the sheet's opener — follow-up sheets/dialogs need a
  /// context that survives this sheet being popped.
  final BuildContext hostContext;

  const YouTubeChatOptionsSheet({super.key, required this.hostContext});

  void _popThen(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  Widget _navRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final Color color = destructive
        ? (Theme.of(context).extension<AppStatusColors>() ??
                AppStatusColors.standard)
            .unreachable
        : Theme.of(context).textTheme.bodyMedium?.color ??
            CupertinoColors.label;
    return Pressable(
      haptic: true,
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, size: 18.0, color: color),
        title: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: color,
              ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
        trailing: const Icon(CupertinoIcons.chevron_forward, size: 16.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Native chat options',
            style: nativeChatSheetTitleStyle(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          Observer(
            builder: (_) {
              final store = GetIt.instance<YouTubeChatStore>();
              switch (store.authState) {
                case YouTubeAuthState.signedIn:
                  return this._navRow(
                    context,
                    icon: CupertinoIcons.square_arrow_right,
                    label:
                        'Sign out ${store.selfChannelTitle ?? 'YouTube'}',
                    destructive: true,
                    onTap: () => this._popThen(
                      context,
                      () => ModalHandler.showBaseDialog(
                        context: this.hostContext,
                        dialogWidget: ConfirmationDialog(
                          title: 'Disconnect YouTube?',
                          body:
                              'Connected as ${store.selfChannelTitle ?? 'your YouTube channel'}. You will be signed out of your Google account.',
                          okText: 'Disconnect',
                          isYesDestructive: true,
                          onOk: (_) => store.logout(),
                        ),
                      ),
                    ),
                  );
                case YouTubeAuthState.unconfigured:
                  return const SizedBox.shrink();
                default:
                  return this._navRow(
                    context,
                    icon: CupertinoIcons.link,
                    label: 'Sign in with Google',
                    subtitle: 'Send messages and moderate chat',
                    onTap: () => this._popThen(
                      context,
                      () => startYouTubeLogin(this.hostContext),
                    ),
                  );
              }
            },
          ),
          this._navRow(
            context,
            icon: CupertinoIcons.gear,
            label: 'Chat setup',
            subtitle: 'API key and sign-in client',
            onTap: () => this._popThen(
              context,
              () => showYouTubeSetupSheet(this.hostContext),
            ),
          ),
          this._navRow(
            context,
            icon: CupertinoIcons.textformat_size,
            label: 'Appearance',
            subtitle: 'Text size, spacing, and separators',
            onTap: () => this._popThen(
              context,
              () => ModalHandler.showBaseBottomSheet(
                context: this.hostContext,
                barrierDismissible: true,
                enableDrag: true,
                maxHeightFraction: 0.72,
                builder: (_) => const NativeChatOptionsSheet(
                  chatType: ChatType.YouTube,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
