import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/views/intro/widgets/back_to_start_wrapper.dart';

import '../../stores/views/intro.dart';
import 'widgets/getting_started.dart';
import 'widgets/intro_slides/intro_slides.dart';

/// Single source for the bottom padding of the intro control cluster
/// (used by the intro slides and their controls)
const double kIntroControlsBottomPadding = AppSpacing.xl;

class IntroView extends StatefulWidget {
  final bool manually;

  const IntroView({super.key, this.manually = false});

  @override
  _IntroViewState createState() => _IntroViewState();
}

class _IntroViewState extends State<IntroView> {
  @override
  void initState() {
    super.initState();

    /// Checking whether tablet (screen big enough to display intro slides
    /// correctly in landscape mode) or phone - taken from the
    /// 'flutter_device_type' package. Phones lock to portrait; tablets /
    /// large screens keep full orientation support.
    final double devicePixelRatio = ui.window.devicePixelRatio;
    final ui.Size size = ui.window.physicalSize;
    final double width = size.width;
    final double height = size.height;

    if (!(devicePixelRatio < 2 && (width >= 1000 || height >= 1000)) &&
        !(devicePixelRatio == 2 && (width >= 1920 || height >= 1920))) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    GetIt.instance.resetLazySingleton<IntroStore>();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          color: Theme.of(context).colorScheme.background,
          child: Observer(builder: (context) {
            return AnimatedSwitcher(

              /// Overlapping crossfade (fadeThrough): the incoming stage
              /// fades + settles in while the outgoing one fades away -
              /// no dead black gap between stages
              duration: AppMotion.slow,
              switchInCurve: AppMotion.standard,
              switchOutCurve: AppMotion.exit,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.98, end: 1.0)
                        .animate(animation),
                    child: child,
                  ),
                );
              },
              child: () {
                switch (GetIt.instance<IntroStore>().stage) {
                  case IntroStage.GettingStarted:
                    return const GettingStarted();
                  case IntroStage.AppSlides:
                    return BackToStartWrapper(
                      child: IntroSlides(manually: this.widget.manually),
                    );
                }
              }(),
            );
          }),
        ),
      ),
    );
  }
}
