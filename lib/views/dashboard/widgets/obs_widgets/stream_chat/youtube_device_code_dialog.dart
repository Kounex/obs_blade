import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/base/adaptive_dialog/adaptive_dialog.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/utils/styling_helper.dart';
import 'package:url_launcher/url_launcher.dart';

/// Start the device-flow login and show its dialog — the single entry
/// point every "Connect YouTube" affordance uses. Requires a configured
/// API key (the store falls back to `unconfigured` without one, so the
/// setup sheet is the right CTA there, not this).
void startYouTubeLogin(BuildContext context) {
  GetIt.instance<YouTubeChatStore>().startLogin();
  ModalHandler.showBaseDialog(
    context: context,
    dialogWidget: const YouTubeDeviceCodeDialog(),
  );
}

/// Walks the user through Google's device code grant: show the code, open
/// google.com/device, poll until authorized/expired/denied/cancelled.
/// Mirrors [TwitchDeviceCodeDialog].
class YouTubeDeviceCodeDialog extends StatelessWidget {
  const YouTubeDeviceCodeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final store = GetIt.instance<YouTubeChatStore>();

    return Observer(
      builder: (_) {
        /// Auto-close once the flow finished
        if (store.authState == YouTubeAuthState.signedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
        }

        return BaseAdaptiveDialog(
          title: 'Connect YouTube',
          bodyWidget: AnimatedSwitcher(
            duration: AppMotion.medium,
            transitionBuilder: (child, animation) {
              final CurvedAnimation curved = CurvedAnimation(
                parent: animation,
                curve: AppMotion.emphasized,
              );
              Widget current = FadeTransition(opacity: curved, child: child);
              if (!AppMotion.reduce(context)) {
                current = AnimatedBuilder(
                  animation: curved,
                  child: current,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0.0, (1.0 - curved.value) * 12.0),
                    child: child,
                  ),
                );
              }
              return current;
            },
            child: KeyedSubtree(
              key: ValueKey(store.authState),
              child: switch (store.authState) {
                YouTubeAuthState.awaitingAuthorization => _CodeEntryState(
                  store: store,
                ),
                YouTubeAuthState.signingIn => const _ProgressState(
                  'Finishing up…',
                ),
                YouTubeAuthState.error => _ErrorState(store: store),
                _ => const _ProgressState('Contacting Google…'),
              },
            ),
          ),
          actions: [
            if (store.authState == YouTubeAuthState.error)
              DialogActionConfig(
                onPressed: (_) => store.startLogin(),
                popOnAction: false,
                child: const Text('Try again'),
              ),
            DialogActionConfig(
              onPressed: (_) => store.cancelLogin(),
              isDefaultAction: true,
              child: Text(
                store.authState == YouTubeAuthState.error ? 'Close' : 'Cancel',
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The code the user enters at google.com/device + the button to get there
class _CodeEntryState extends StatefulWidget {
  final YouTubeChatStore store;

  const _CodeEntryState({required this.store});

  @override
  State<_CodeEntryState> createState() => _CodeEntryStateState();
}

class _CodeEntryStateState extends State<_CodeEntryState> {
  /// How long the "copied" confirmation stays before reverting
  static const Duration _copiedFeedbackDuration = Duration(seconds: 2);

  bool _copied = false;
  Timer? _copiedTimer;

  @override
  void dispose() {
    this._copiedTimer?.cancel();
    super.dispose();
  }

  /// Copies the code and confirms it inline — the full-screen status
  /// overlay is too easy to miss while the user's eyes are on the dialog
  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    this._copiedTimer?.cancel();
    this.setState(() => this._copied = true);
    this._copiedTimer = Timer(_copiedFeedbackDuration, () {
      if (this.mounted) {
        this.setState(() => this._copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final code = this.widget.store.pendingUserCode ?? '…';
    final uri = Uri.parse(
      this.widget.store.pendingVerificationUrl ??
          'https://www.google.com/device',
    );
    final statusColors =
        Theme.of(context).extension<AppStatusColors>() ??
        AppStatusColors.standard;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Open Google and enter this code:',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        StaggeredEntrance(
          scaleFrom: 0.985,
          child: Pressable(
            haptic: true,
            onTap: () => this._copyCode(code),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: StylingHelper.lightenDarkenColor(
                  Theme.of(context).cardColor,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                code,
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(letterSpacing: 2.0),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (this._copied)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.checkmark_circle_fill,
                size: 14.0,
                color: statusColors.live,
              ),
              const SizedBox(width: AppSpacing.xs / 2),
              Text(
                'Copied to clipboard',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: statusColors.live),
              ),
            ],
          )
        else
          Text(
            'Tap the code to copy it',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const SizedBox(height: AppSpacing.lg),
        Pressable(
          haptic: true,
          onTap: () async {
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).buttonTheme.colorScheme?.secondary ??
                  StylingHelper.accent_color,
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              'Open Google',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontSize: 17.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _ProgressState('Waiting for authorization…'),
      ],
    );
  }
}

class _ProgressState extends StatelessWidget {
  final String text;

  const _ProgressState(this.text);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StylingHelper.isApple(context)
            ? const CupertinoActivityIndicator()
            : const CircularProgressIndicator(),
        const SizedBox(height: AppSpacing.md),
        Text(this.text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final YouTubeChatStore store;

  const _ErrorState({required this.store});

  @override
  Widget build(BuildContext context) {
    return Text(
      this.store.authError ?? 'Something went wrong',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
