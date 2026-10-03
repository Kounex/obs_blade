import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../chat_type_brand.dart';
import '../kick_setup_sheet.dart';

/// Native-mode Kick sign-in control for the username bar — mirrors
/// [YouTubeAccountControl]: a "Connect Kick" pill while signed out,
/// nothing while signed in (the account and its sign-out live in the chat
/// header's sheet). Kick has no `unconfigured`
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
              ? const SizedBox.shrink()
              : const _ConnectPill(),
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
