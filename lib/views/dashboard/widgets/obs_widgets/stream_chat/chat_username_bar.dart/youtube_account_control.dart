import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../chat_type_brand.dart';
import '../youtube_device_code_dialog.dart';
import '../youtube_setup_sheet.dart';

/// Native-mode YouTube sign-in control for the username bar — mirrors
/// [TwitchAccountControl]: a "Connect YouTube" pill while signed out, a
/// setup pill when no API key is configured yet, nothing while signed in
/// (the account, a channel-less account's "Switch account" and sign-out
/// live in the chat header's sheet).
class YouTubeAccountControl extends StatelessWidget {
  const YouTubeAccountControl({super.key});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final store = GetIt.instance<YouTubeChatStore>();

        return Align(
          alignment: Alignment.centerRight,

          /// Hug the pill: a full-width Align left a gap next to the
          /// options button in the chat bar row.
          widthFactor: 1.0,
          child: switch (store.authState) {
            YouTubeAuthState.unconfigured => const _SetupPill(),
            YouTubeAuthState.signedIn => const SizedBox.shrink(),
            _ => const _ConnectPill(),
          },
        );
      },
    );
  }
}

/// Same visual idiom as the Twitch "Connect Twitch" pill. Read-only
/// setups (API key, no OAuth client) go straight to the sign-in part of
/// the setup sheet - the device flow can't start without a client.
class _ConnectPill extends StatelessWidget {
  const _ConnectPill();

  @override
  Widget build(BuildContext context) {
    return Pressable(
      haptic: true,
      onTap: () => GetIt.instance<YouTubeChatStore>().canSignIn
          ? startYouTubeLogin(context)
          : showYouTubeSignInSheet(context),
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
        child: AutoSizeText(
          'Connect YouTube',
          maxLines: 1,
          minFontSize: 10.0,
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
        child: AutoSizeText(
          'Set up YouTube',
          maxLines: 1,
          minFontSize: 10.0,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
