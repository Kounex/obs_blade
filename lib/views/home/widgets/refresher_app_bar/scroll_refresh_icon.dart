import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'refresher_app_bar.dart';

import '../../../../stores/views/home.dart';

class ScrollRefreshIcon extends StatefulWidget {
  final double expandedBarHeight;
  final double currentBarHeight;

  const ScrollRefreshIcon({
    Key? key,
    required expandedBarHeight,
    required this.currentBarHeight,
  })  : expandedBarHeight = expandedBarHeight + kRefresherAppBarHeight,
        super(key: key);

  @override
  _ScrollRefreshIconState createState() => _ScrollRefreshIconState();
}

class _ScrollRefreshIconState extends State<ScrollRefreshIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(curve: Curves.bounceInOut, parent: _animController),
    );
  }

  @override
  void didUpdateWidget(ScrollRefreshIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  double _getRefreshOpacity(double barStretchOffset, double currentBarHeight) {
    double opacity = pow(
            1.4,
            0.2 * (currentBarHeight - this.widget.expandedBarHeight) -
                (barStretchOffset / 6)) -
        0.1;
    return opacity > 1.0
        ? 1.0
        : opacity < 0.0
            ? 0.0
            : opacity;
  }

  @override
  Widget build(BuildContext context) {
    HomeStore landingStore = GetIt.instance<HomeStore>();
    double barStretchOffset = MediaQuery.of(context).size.height / 15;

    if (this.widget.currentBarHeight - this.widget.expandedBarHeight >=
            barStretchOffset &&
        !_animController.isAnimating &&
        !landingStore.refreshable) {
      HapticFeedback.lightImpact();
      landingStore.setRefreshable(true);
      _animController.forward().then((_) => _animController.animateTo(0.5));
    }
    if (this.widget.currentBarHeight - this.widget.expandedBarHeight <
            barStretchOffset &&
        landingStore.refreshable) {
      landingStore.setRefreshable(false);
      _animController.animateTo(0.0);
    }
    return Padding(
      padding: EdgeInsets.only(top: this.widget.expandedBarHeight / 2),
      child: Align(
        child: Opacity(
          opacity: _getRefreshOpacity(
              barStretchOffset, this.widget.currentBarHeight),
          child: Container(
            width: 32.0,
            height: 32.0,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) => ScaleTransition(
                scale: _scaleAnimation,
                child: child,
              ),
              child: const Icon(
                Icons.arrow_downward,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
