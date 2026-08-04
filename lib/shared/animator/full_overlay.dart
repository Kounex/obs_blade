import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../design/app_motion.dart';
import '../design/app_radius.dart';
import '../design/app_spacing.dart';

class FullOverlay extends StatefulWidget {
  final Widget content;
  final Duration animationDuration;
  final Duration showDuration;

  const FullOverlay({
    super.key,
    required this.content,
    required this.animationDuration,
    required this.showDuration,
  });

  @override
  FullOverlayState createState() => FullOverlayState();
}

class FullOverlayState extends State<FullOverlay>
    with SingleTickerProviderStateMixin {
  static const double _kMinSize = 150.0;
  static const double _kMaxWidth = 220.0;

  late AnimationController _controller;
  late Animation<double> _blur;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  late Timer _closeTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: this.widget.animationDuration);
    _blur = Tween<double>(begin: 0.0, end: 9.0)
        .animate(CurvedAnimation(curve: Curves.easeIn, parent: _controller));
    _opacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(curve: Curves.easeIn, parent: _controller));
    _scale = Tween<double>(begin: 0.96, end: 1.0)
        .animate(CurvedAnimation(curve: AppMotion.spring, parent: _controller));

    _controller.forward();
    _closeTimer = Timer(this.widget.showDuration, () => this.closeOverlay());
  }

  Future<void> closeOverlay() async {
    _closeTimer.cancel();
    if (this.mounted) {
      await _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = math.min(
      _kMaxWidth,
      MediaQuery.sizeOf(context).width - (AppSpacing.xl * 2),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _controller,
          child: const AbsorbPointer(),
          builder: (context, child) => FadeTransition(
            opacity: _opacity,
            child: ColoredBox(
              color: Colors.black26,
              child: child,
            ),
          ),
        ),
        Center(
          child: AnimatedBuilder(
            animation: _controller,
            child: this.widget.content,
            builder: (context, child) {
              return FadeTransition(
                opacity: _opacity,
                child: ScaleTransition(
                  scale: _scale,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: _blur.value,
                      sigmaY: _blur.value,
                    ),
                    // Fixed width + shrink-wrapped height (min 150).
                    // heightFactor/widthFactor keep Center from filling the screen.
                    child: SizedBox(
                      width: width,
                      child: Material(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black87
                            : Colors.white70,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(AppRadius.md),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: _kMinSize,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.md,
                              AppSpacing.lg,
                              AppSpacing.lg,
                            ),
                            child: Center(
                              widthFactor: 1.0,
                              heightFactor: 1.0,
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
