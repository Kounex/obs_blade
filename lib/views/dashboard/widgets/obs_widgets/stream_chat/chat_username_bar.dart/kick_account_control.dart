import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../utils/styling_helper.dart';
import '../chat_type_brand.dart';
import '../kick_setup_sheet.dart';

/// Native-mode Kick account control for the username bar — mirrors
/// [YouTubeAccountControl]: the connected account chip (pfp + username,
/// tap → setup sheet with the sign-out action) while signed in, or a
/// "Connect Kick" pill while signed out. Kick has no `unconfigured`
/// state — reads are anonymous, so the pill always routes to the setup
/// sheet (which hosts the BYO client fields).
class KickAccountControl extends StatelessWidget {
  const KickAccountControl({super.key});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final store = GetIt.instance<KickChatStore>();

        return Align(
          alignment: Alignment.centerRight,
          child: store.isSignedInState
              ? _AccountChip(
                  displayName: store.selfUsername,
                  profilePicture: store.selfProfilePicture,
                )
              : const _ConnectPill(),
        );
      },
    );
  }
}

/// The connected account, styled like the bar's other control containers
/// (avatar + username, tap → setup sheet hosting the sign-out action).
class _AccountChip extends StatelessWidget {
  final String? displayName;
  final String? profilePicture;

  const _AccountChip({this.displayName, this.profilePicture});

  @override
  Widget build(BuildContext context) {
    final enabledColor =
        (Theme.of(context).extension<AppTextColors>() ?? AppTextColors.standard)
            .highlightText;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textMax = constraints.maxWidth.isFinite
            ? (constraints.maxWidth - AppSpacing.md * 2 - 18.0 - AppSpacing.xs)
                  .clamp(0.0, 96.0)
            : 96.0;

        return Tooltip(
          message:
              'Connected as ${this.displayName ?? 'Kick'} — manage sign-in',
          child: Pressable(
            haptic: true,
            onTap: () => showKickSetupSheet(context),
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
                  ClipOval(
                    child:
                        this.profilePicture != null &&
                            this.profilePicture!.isNotEmpty
                        ? Image.network(
                            this.profilePicture!,
                            width: 18.0,
                            height: 18.0,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              CupertinoIcons.person_fill,
                              size: 18.0,
                              color: enabledColor,
                            ),
                          )
                        : Icon(
                            CupertinoIcons.person_fill,
                            size: 18.0,
                            color: enabledColor,
                          ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: textMax),
                    child: Text(
                      this.displayName ?? 'Kick',
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

/// Same visual idiom as the YouTube "Connect YouTube" pill.
class _ConnectPill extends StatelessWidget {
  const _ConnectPill();

  @override
  Widget build(BuildContext context) {
    return Pressable(
      haptic: true,
      onTap: () => showKickSetupSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color:
              ChatType.Kick.brandColor ??
              Theme.of(context).colorScheme.secondary,
          borderRadius: AppRadius.pill,
        ),
        child: AutoSizeText(
          'Connect Kick',
          maxLines: 1,
          minFontSize: 10.0,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.black),
        ),
      ),
    );
  }
}
