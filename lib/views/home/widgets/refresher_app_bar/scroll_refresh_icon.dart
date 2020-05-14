import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obs_station/stores/views/landing.dart';
import 'package:provider/provider.dart';

class ScrollRefreshIcon extends StatefulWidget {
  final double expandedBarHeight;

  ScrollRefreshIcon({@required expandedBarHeight})
      : expandedBarHeight = expandedBarHeight + 28.0;

  @override
  _ScrollRefreshIconState createState() => _ScrollRefreshIconState();
}

class _ScrollRefreshIconState extends State<ScrollRefreshIcon>
    with SingleTickerProviderStateMixin {
  AnimationController _animController;
  Animation<double> _scaleAnimation;

  @override
  initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(curve: Curves.bounceInOut, parent: _animController),
    );
  }

  double _getRefreshOpacity(double barStretchOffset, double currentBarHeight) {
    double opacity = pow(
            1.4,
            0.2 * (currentBarHeight - widget.expandedBarHeight) -
                (barStretchOffset / 6)) -
        0.1;
    return opacity > 1.0 ? 1.0 : opacity < 0.0 ? 0.0 : opacity;
  }

  @override
  Widget build(BuildContext context) {
    LandingStore landingStore = Provider.of<LandingStore>(context);
    double barStretchOffset = MediaQuery.of(context).size.height / 15;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight - widget.expandedBarHeight >=
                barStretchOffset &&
            !_animController.isAnimating &&
            !landingStore.refreshable) {
          HapticFeedback.lightImpact();
          landingStore.setRefreshable(true);
          _animController.forward().then((_) => _animController.animateTo(0.5));
        }
        if (constraints.maxHeight - widget.expandedBarHeight <
                barStretchOffset &&
            landingStore.refreshable) {
          landingStore.setRefreshable(false);
          _animController.animateTo(0.0);
        }
        return Padding(
          padding: EdgeInsets.only(top: widget.expandedBarHeight / 2),
          child: Align(
            child: Opacity(
              opacity:
                  _getRefreshOpacity(barStretchOffset, constraints.maxHeight),
              child: Container(
                width: 32.0,
                height: 32.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) => ScaleTransition(
                    scale: _scaleAnimation,
                    child: child,
                  ),
                  child: Icon(
                    Icons.arrow_downward,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
