import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/dialogs/confirmation.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';
import '../chat_type_brand.dart';
import '../youtube_device_code_dialog.dart';
import '../youtube_setup_sheet.dart';

/// Native-mode YouTube account control for the username bar — mirrors
/// [TwitchAccountControl]: the connected channel chip (tap → disconnect
/// confirmation) while signed in, a "Connect YouTube" pill while signed
/// out, or a setup pill when no API key is configured yet.
class YouTubeAccountControl extends StatelessWidget {
  const YouTubeAccountControl({super.key});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final store = GetIt.instance<YouTubeChatStore>();

        return Align(
          alignment: Alignment.centerRight,
          child: switch (store.authState) {
            YouTubeAuthState.unconfigured => const _SetupPill(),
            YouTubeAuthState.signedIn => _AccountChip(
              displayName: store.selfChannelTitle,
            ),
            _ => const _ConnectPill(),
          },
        );
      },
    );
  }
}

/// The connected channel, styled like the bar's other control containers
/// (checkmark + channel title, tap → disconnect confirmation).
class _AccountChip extends StatelessWidget {
  final String? displayName;

  const _AccountChip({this.displayName});

  @override
  Widget build(BuildContext context) {
    final enabledColor = Theme.of(context).cupertinoOverrideTheme!.primaryColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textMax = constraints.maxWidth.isFinite
            ? (constraints.maxWidth - AppSpacing.md * 2 - 18.0 - AppSpacing.xs)
                  .clamp(0.0, 96.0)
            : 96.0;

        return Tooltip(
          message:
              'Connected as ${this.displayName ?? 'YouTube'} — tap to disconnect',
          child: Pressable(
            haptic: true,
            onTap: () => ModalHandler.showBaseDialog(
              context: context,
              dialogWidget: ConfirmationDialog(
                title: 'Disconnect YouTube?',
                body:
                    'Connected as ${this.displayName ?? 'your YouTube channel'}. You will be signed out of your Google account.',
                okText: 'Disconnect',
                isYesDestructive: true,
                onOk: (_) => GetIt.instance<YouTubeChatStore>().logout(),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
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
                      this.displayName ?? 'YouTube',
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

/// Same visual idiom as the Twitch "Connect Twitch" pill.
class _ConnectPill extends StatelessWidget {
  const _ConnectPill();

  @override
  Widget build(BuildContext context) {
    return Pressable(
      haptic: true,
      onTap: () => startYouTubeLogin(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color:
              ChatType.YouTube.brandColor ??
              Theme.of(context).colorScheme.secondary,
          borderRadius: AppRadius.pill,
        ),
        child: Text(
          'Connect YouTube',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

/// No API key configured — the account control can't sign in yet, so the
/// pill routes to the setup sheet instead.
class _SetupPill extends StatelessWidget {
  const _SetupPill();

  @override
  Widget build(BuildContext context) {
    return Pressable(
      haptic: true,
      onTap: () => showYouTubeSetupSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color:
              ChatType.YouTube.brandColor ??
              Theme.of(context).colorScheme.secondary,
          borderRadius: AppRadius.pill,
        ),
        child: Text(
          'Set up YouTube',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
