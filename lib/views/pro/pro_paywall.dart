import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';

import '../../shared/design/design.dart';
import '../../shared/general/themed/cupertino_scaffold.dart';
import '../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../stores/pro_store.dart';
import 'widgets/pro_sales.dart';
import 'widgets/pro_unlocked.dart';

/// Full-screen Pro paywall (route-registered, never auto-presented - entry
/// points are user-initiated taps only).
///
/// State machine (Observer over [ProStore]):
/// - not Pro -> [ProSalesView] (hero, benefits browser, pricing with
///   skeleton / placeholder / priced variants, restore, legal)
/// - Pro -> [ProUnlockedView] (thank-you / manage-subscription), confetti
///   plays once on the not-Pro -> Pro edge
///
/// Hidden debug toggle: long-press the hero logo (see pro_hero.dart) to
/// flip [ProStore.setDebugOverride] - `kDebugMode` only.
class ProPaywallView extends StatefulWidget {
  /// Test seam - production uses the GetIt singleton
  final ProStore? store;

  const ProPaywallView({super.key, this.store});

  @override
  State<ProPaywallView> createState() => _ProPaywallViewState();
}

class _ProPaywallViewState extends State<ProPaywallView> {
  late final ProStore _store =
      this.widget.store ?? GetIt.instance<ProStore>();

  late final ConfettiController _confettiController =
      ConfettiController(duration: AppMotion.dramatic);

  late final ReactionDisposer _proReaction;

  @override
  void initState() {
    super.initState();

    /// Pricing loads lazily - the pro products legitimately don't exist
    /// store-side yet, in which case the sales view renders its
    /// placeholder state
    if (this._store.products.isEmpty && !this._store.pending) {
      this._store.loadProducts();
    }

    /// Celebrate only on the unlock edge (a long-time Pro opening this
    /// page gets the calm thank-you state, not confetti)
    this._proReaction = reaction(
      (_) => this._store.isPro,
      (bool isPro) {
        if (isPro) {
          this._confettiController.play();
        }
      },
    );
  }

  @override
  void dispose() {
    this._proReaction();
    this._confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemedCupertinoScaffold(
      /// Own material Scaffold so ScaffoldMessenger (placeholder-buy /
      /// debug-toggle snackbars) has a descendant to present to - the
      /// Cupertino shell doesn't register one
      body: Scaffold(
        body: TransculentCupertinoNavBarWrapper(
          /// Back-only bar (token-delta §5, v12): a title here duplicates
          /// the hero's brand mark - double naming. The body extends
          /// behind the bar so scrolling content makes the blur visible
          /// (same as the sliver-based views).
          extendBodyBehindBar: true,
          customBody: Observer(
            builder: (context) => AnimatedSwitcher(
              duration: AppMotion.medium,
              child: this._store.isPro
                  ? ProUnlockedView(
                      key: const ValueKey('pro-unlocked'),
                      confettiController: this._confettiController,
                    )
                  : ProSalesView(
                      key: const ValueKey('pro-sales'),
                      store: this._store,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
