import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/base/adaptive_dialog/adaptive_dialog.dart';
import 'package:obs_blade/shared/overlay/base_result.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/utils/overlay_handler.dart';
import 'package:obs_blade/utils/styling_helper.dart';
import 'package:url_launcher/url_launcher.dart';

/// Start the device-flow login and show its dialog — the single entry
/// point every "Connect Twitch" affordance uses.
void startTwitchLogin(BuildContext context) {
  GetIt.instance<TwitchChatStore>().startLogin();
  ModalHandler.showBaseDialog(
    context: context,
    dialogWidget: const TwitchDeviceCodeDialog(),
  );
}

/// Walks the user through Twitch's device code grant: show the code, open
/// twitch.tv/activate, poll until authorized/expired/denied/cancelled.
class TwitchDeviceCodeDialog extends StatelessWidget {
  const TwitchDeviceCodeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final store = GetIt.instance<TwitchChatStore>();

    return Observer(
      builder: (_) {
        /// Auto-close once the flow finished
        if (store.authState == TwitchAuthState.loggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
        }

        return BaseAdaptiveDialog(
          title: 'Connect Twitch',
          bodyWidget: switch (store.authState) {
            TwitchAuthState.awaitingAuthorization =>
              _CodeEntryState(store: store),
            TwitchAuthState.loggingIn =>
              const _ProgressState('Finishing up…'),
            TwitchAuthState.error => _ErrorState(store: store),
            _ => const _ProgressState('Contacting Twitch…'),
          },
          actions: [
            if (store.authState == TwitchAuthState.error)
              DialogActionConfig(
                onPressed: (_) => store.startLogin(),
                popOnAction: false,
                child: const Text('Try again'),
              ),
            DialogActionConfig(
              onPressed: (_) => store.cancelLogin(),
              isDefaultAction: true,
              child: Text(
                store.authState == TwitchAuthState.error ? 'Close' : 'Cancel',
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The code the user enters at twitch.tv/activate + the button to get there
class _CodeEntryState extends StatelessWidget {
  final TwitchChatStore store;

  const _CodeEntryState({required this.store});

  @override
  Widget build(BuildContext context) {
    final code = this.store.pendingUserCode ?? '…';
    final uri = Uri.parse(this.store.pendingVerificationUri ??
        'https://www.twitch.tv/activate');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Open Twitch and enter this code:',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Pressable(
          haptic: true,
          onTap: () {
            Clipboard.setData(ClipboardData(text: code));
            OverlayHandler.showStatusOverlay(
              context: context,
              content: const BaseResult(
                icon: BaseResultIcon.Positive,
                text: 'Code copied',
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: SelectableText(
              code,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(letterSpacing: 2.0),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
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
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              'Open Twitch',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white),
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
  final TwitchChatStore store;

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
