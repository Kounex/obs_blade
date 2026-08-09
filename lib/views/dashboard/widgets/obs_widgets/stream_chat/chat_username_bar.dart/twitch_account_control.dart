import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/dialogs/confirmation.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';
import '../chat_type_brand.dart';
import '../twitch_device_code_dialog.dart';

/// Native-mode Twitch account control for the username bar: the connected
/// account chip (tap -> disconnect confirmation) while logged in, or a
/// "Connect Twitch" pill while logged out. Only visible while the native
/// engine is selected - the WebView engine shows the classic username
/// actions instead.
class TwitchAccountControl extends StatelessWidget {
  const TwitchAccountControl({super.key});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final store = GetIt.instance<TwitchChatStore>();
        final displayName = store.user?.displayName ?? store.user?.login;

        return Align(
          alignment: Alignment.centerRight,
          child: store.isLoggedIn
              ? _AccountChip(displayName: displayName)
              : const _ConnectPill(),
        );
      },
    );
  }
}

/// The connected account, styled like the bar's other control containers
/// and reading as tappable (checkmark + display name). Tapping opens the
/// disconnect confirmation. When the parent [Flexible] compresses the
/// native right cluster, the name ellipsizes instead of overflowing.
class _AccountChip extends StatelessWidget {
  final String? displayName;

  const _AccountChip({this.displayName});

  @override
  Widget build(BuildContext context) {
    final enabledColor =
        Theme.of(context).cupertinoOverrideTheme!.primaryColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textMax = constraints.maxWidth.isFinite
            ? (constraints.maxWidth -
                    AppSpacing.md * 2 -
                    18.0 -
                    AppSpacing.xs)
                .clamp(0.0, 96.0)
            : 96.0;

        return Tooltip(
          message:
              'Connected as ${this.displayName ?? 'Twitch'} — tap to disconnect',
          child: Pressable(
            haptic: true,
            onTap: () => ModalHandler.showBaseDialog(
              context: context,
              dialogWidget: ConfirmationDialog(
                title: 'Disconnect Twitch?',
                body:
                    'Connected as ${this.displayName ?? 'your Twitch account'}. You will be logged out of your Twitch account.',
                okText: 'Disconnect',
                isYesDestructive: true,
                onOk: (_) => GetIt.instance<TwitchChatStore>().logout(),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: StylingHelper.lightenDarkenColor(
                    Theme.of(context).cardColor),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                  width: 0.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    size: 18.0,
                    color: enabledColor,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: textMax),
                    child: Text(
                      this.displayName ?? 'Twitch',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: enabledColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
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

/// Same visual style as the "Connect Twitch" pill in the native connect
/// empty state (`stream_chat.dart`)
class _ConnectPill extends StatelessWidget {
  const _ConnectPill();

  @override
  Widget build(BuildContext context) {
    return Pressable(
      haptic: true,
      onTap: () => startTwitchLogin(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: ChatType.Twitch.brandColor ??
              Theme.of(context).colorScheme.secondary,
          borderRadius: AppRadius.pill,
        ),
        child: Text(
          'Connect Twitch',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
