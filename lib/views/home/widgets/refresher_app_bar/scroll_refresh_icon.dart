import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../../../shared/design/design.dart';
import '../../../../stores/views/home.dart';
import '../../../../utils/styling_helper.dart';
import 'refresher_app_bar.dart';

class ScrollRefreshIcon extends StatefulWidget {
  final double expandedBarHeight;
  final double currentBarHeight;

  const ScrollRefreshIcon({
    super.key,
    required expandedBarHeight,
    required this.currentBarHeight,
  }) : expandedBarHeight = expandedBarHeight + kRefresherAppBarHeight,
       super();

  @override
  _ScrollRefreshIconState createState() => _ScrollRefreshIconState();
}

class _ScrollRefreshIconState extends State<ScrollRefreshIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  /// [HomeStore.doRefresh] token captured when the pull arms the refresh -
  /// a release that fires `initiateRefresh` flips it (a scroll-back cancel
  /// doesn't), which is how the pill knows to spin
  bool _armedDoRefresh = false;
  bool _refreshing = false;

  @override
  initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(curve: AppMotion.standard, parent: _animController),
    );
  }

  @override
  void didUpdateWidget(ScrollRefreshIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  /// Invisible for the first 10% of the pull (not from the very first
  /// pixel), then a plain linear ramp to fully visible by 80% of the arm
  /// threshold (not hugging the threshold itself) - deliberately no easing
  /// curve here, since `Curves.easeOut`'s steep initial rise was exactly
  /// what made the icon appear almost immediately on the first attempt.
  double _getRefreshOpacity(double barStretchOffset, double currentBarHeight) {
    final double pulled = currentBarHeight - this.widget.expandedBarHeight;
    final double start = barStretchOffset * 0.1;
    final double end = barStretchOffset * 0.8;
    return ((pulled - start) / (end - start)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    HomeStore homeStore = GetIt.instance<HomeStore>();
    double barStretchOffset = MediaQuery.sizeOf(context).height / 8;

    /// Themed indicator (was hardcoded white/black which clashed with
    /// custom themes): highlight-colored pill with a contrast-aware arrow
    final Color indicatorColor = Theme.of(context).colorScheme.secondary;

    if (this.widget.currentBarHeight - this.widget.expandedBarHeight >=
            barStretchOffset &&
        !_animController.isAnimating &&
        !homeStore.refreshable) {
      HapticFeedback.lightImpact();
      homeStore.setRefreshable(true);
      _armedDoRefresh = homeStore.doRefresh;

      /// Pulse on arm - skipped under reduced motion (the arrow stays put)
      if (!AppMotion.reduce(context)) {
        _animController.forward().then((_) => _animController.animateTo(0.5));
      }
    }
    if (this.widget.currentBarHeight - this.widget.expandedBarHeight <
            barStretchOffset &&
        homeStore.refreshable) {
      homeStore.setRefreshable(false);
      _animController.animateTo(0.0);

      /// Release while armed = the refresh actually fired - spin the pill
      /// until the new autodiscovery future settles (a scroll-back cancel
      /// leaves the token untouched, so no spinner)
      if (homeStore.doRefresh != _armedDoRefresh) {
        final refresh = homeStore.autodiscoverConnections;
        if (refresh != null) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!this.mounted) return;
            setState(() => _refreshing = true);
            refresh.whenComplete(() {
              if (this.mounted &&
                  identical(refresh, homeStore.autodiscoverConnections)) {
                setState(() => _refreshing = false);
              }
            });
          });
        }
      }
    }
    return Transform.translate(
      /// [FlexibleSpaceBar] parks the title at the bottom — lift the
      /// indicator to the vertical midpoint of the expanded bar.
      offset: Offset(0.0, -((this.widget.expandedBarHeight / 2.0) - 16.0)),
      child: Opacity(
        opacity: _getRefreshOpacity(
          barStretchOffset,
          this.widget.currentBarHeight,
        ),
        child: Container(
          width: 32.0,
          height: 32.0,
          decoration: BoxDecoration(
            color: indicatorColor,
            shape: BoxShape.circle,
          ),
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) =>
                ScaleTransition(scale: _scaleAnimation, child: child),

            /// Arrow <-> spinner crossfade inside the same highlight pill
            /// while the refresh runs
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              child: _refreshing
                  ? CupertinoActivityIndicator(
                      key: const ValueKey('refreshing'),
                      radius: 8.0,
                      color: StylingHelper.surroundingAwareAccent(
                        surroundingColor: indicatorColor,
                      ),
                    )
                  : Icon(
                      key: const ValueKey('idle'),
                      Icons.arrow_downward,
                      color: StylingHelper.surroundingAwareAccent(
                        surroundingColor: indicatorColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
