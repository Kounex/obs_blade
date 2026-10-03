import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../shared/design/design.dart';
import '../../../shared/general/base/button.dart';
import '../../../shared/general/base/constrained_box.dart';
import '../../../stores/pro_store.dart';
import '../../../utils/manage_subscriptions.dart';
import '../../../utils/pro_ids.dart';
import '../../../utils/styling_helper.dart';
import 'pro_plan_switch.dart';

/// The already-Pro side of the paywall: thank-you + manage subscription.
/// Doubles as the purchase-success state — the confetti controller plays
/// on the not-Pro -> Pro edge (see pro_paywall.dart).
///
/// Hidden debug toggle: long-press the result icon to revert
/// [ProStore.setDebugOverride] to false - lets a debug build (or a release
/// build compiled with [kProReleaseTestUnlock]) undo the fake unlock
/// without leaving this screen. A no-op if `isPro` is actually true via a
/// real purchase (`boughtPro`), same as the paywall's own long-press.
class ProUnlockedView extends StatelessWidget {
  final ProStore store;
  final ConfettiController confettiController;

  const ProUnlockedView({
    super.key,
    required this.store,
    required this.confettiController,
  });

  void _revertDebugOverride(BuildContext context) {
    this.store.setDebugOverride(false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Debug Pro override disabled')),
      );
  }

  /// StoreKit's sheet on iOS (re-read the plan once it closes - a cancel
  /// or switch there only shows after a fresh read), the store's page
  /// elsewhere
  Future<void> _manageSubscription(BuildContext context) async {
    switch (await openManageSubscriptions()) {
      case ManageSubscriptionsResult.sheetClosed:
        await this.store.refreshPlan(fresh: true);
      case ManageSubscriptionsResult.pageOpened:
        break;
      case ManageSubscriptionsResult.failed:
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
    final AppTextColors textColors = Theme.of(
      context,
    ).extension<AppTextColors>()!;

    /// Expand: a loose Stack lets the scroll view shrink-wrap this short
    /// page and clip it at its own bottom edge while bouncing
    return Stack(
      fit: StackFit.expand,
      children: [
        SingleChildScrollView(
          physics: StylingHelper.platformAwareScrollPhysics,

          /// The body extends behind the translucent nav bar
          /// (`extendBodyBehindBar` on the wrapper) - the scroll view
          /// owns the bar's top inset
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + GlassBar.minContentHeight,
            bottom: tabBarBottomPadding(context),
          ),
          child: Center(
            child: BaseConstrainedBox(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xxl * 2),
                  StaggeredEntrance(
                    index: 0,
                    scaleFrom: 0.985,
                    child: GestureDetector(
                      key: const Key('pro-unlocked-debug-revert'),
                      onLongPress: kDebugMode || kProReleaseTestUnlock
                          ? () => this._revertDebugOverride(context)
                          : null,
                      child: AnimatedResultIcon(
                        type: AnimatedResultType.positive,
                        size: 96.0,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  StaggeredEntrance(
                    index: 1,
                    scaleFrom: 0.985,
                    child: Text(
                      'Welcome to Pro',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  StaggeredEntrance(
                    index: 2,
                    scaleFrom: 0.985,
                    child: Text(
                      'Thanks for supporting OBS Blade! Native and combined '
                      'chat, your activity feed, chat read out loud, the full '
                      'mod toolkit and custom themes are all yours. And '
                      'everything free stays free, forever.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: textColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  StaggeredEntrance(
                    index: 3,
                    scaleFrom: 0.985,
                    child: ProCancelSubscriptionNotice(
                      store: this.store,
                      onOpenSubscriptions: () =>
                          this._manageSubscription(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  StaggeredEntrance(
                    index: 4,
                    scaleFrom: 0.985,
                    child: ProPlanSwitch(store: this.store),
                  ),
                  StaggeredEntrance(
                    index: 5,
                    scaleFrom: 0.985,

                    /// Lifetime has no subscription to manage - one that
                    /// still renews gets the cancel notice's own button
                    child: Observer(
                      builder: (context) =>
                          this.store.plan.currentPlan == kProLifetimeId
                          ? const SizedBox()
                          : Column(
                              children: [
                                BaseButton(
                                  text: 'Manage subscription',
                                  onPressed: () =>
                                      this._manageSubscription(context),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'Manage or cancel anytime in your store '
                                  'account - no hoops, no dark patterns.',
                                  textAlign: TextAlign.center,

                                  /// Reassurance footnote (token-delta §2.1)
                                  style: Theme.of(context).textTheme.bodySmall!
                                      .copyWith(color: textColors.textTertiary),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!AppMotion.reduce(context))
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
