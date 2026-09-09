import 'dart:io';

import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/design/design.dart';
import '../../../shared/general/base/button.dart';
import '../../../shared/general/base/constrained_box.dart';
import '../../../utils/styling_helper.dart';

/// Manage-subscription page of the platform the purchase ran through
/// (lazy - `Platform` must not be touched at class-load time on web)
Uri get _manageSubscriptionUri => Uri.parse(
      !kIsWeb && Platform.isIOS
          ? 'https://apps.apple.com/account/subscriptions'
          : 'https://play.google.com/store/account/subscriptions',
    );

/// The already-Pro side of the paywall: thank-you + manage subscription.
/// Doubles as the purchase-success state — the confetti controller plays
/// on the not-Pro -> Pro edge (see pro_paywall.dart).
class ProUnlockedView extends StatelessWidget {
  final ConfettiController confettiController;

  const ProUnlockedView({super.key, required this.confettiController});

  Future<void> _manageSubscription(BuildContext context) async {
    try {
      await launchUrl(
        _manageSubscriptionUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Couldn\'t open the subscription page.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).buttonTheme.colorScheme!.secondary;
    final AppTextColors textColors =
        Theme.of(context).extension<AppTextColors>()!;

    return Stack(
      children: [
        SingleChildScrollView(
          physics: StylingHelper.platformAwareScrollPhysics,
          child: Center(
            child: BaseConstrainedBox(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xxl * 2),
                  AnimatedResultIcon(
                    type: AnimatedResultType.positive,
                    size: 96.0,
                    color: accent,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Welcome to Pro',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Thanks for supporting OBS Blade — native chat and '
                    'moderation are unlocked. And everything you already '
                    'used stays free, forever.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: textColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  BaseButton(
                    text: 'Manage subscription',
                    onPressed: () => this._manageSubscription(context),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Manage or cancel anytime in your store account — '
                    'no hoops, no dark patterns.',
                    textAlign: TextAlign.center,

                    /// Reassurance footnote (token-delta §2.1)
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: textColors.textTertiary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: this.confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 24,
            colors: [
              accent,
              Theme.of(context).colorScheme.secondary,
              Colors.white,
            ],
          ),
        ),
      ],
    );
  }
}
