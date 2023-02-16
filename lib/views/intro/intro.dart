import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/views/intro/widgets/back_so_selection_wrapper.dart';

import '../../stores/views/intro.dart';
import 'widgets/getting_started.dart';
import 'widgets/intro_slides/intro_slides.dart';
import 'widgets/twenty_eight_party.dart';
import 'widgets/version_selection.dart';

const double kIntroControlsBottomPadding = 24.0;

class IntroView extends StatefulWidget {
  final bool manually;

  const IntroView({Key? key, this.manually = false}) : super(key: key);

  @override
  _IntroViewState createState() => _IntroViewState();
}

class _IntroViewState extends State<IntroView> {
  @override
  void initState() {
    super.initState();

    /// Checking whether tablet (screen big enough to display intro slides
    /// correctly in landscape mode) or phone - taken from the
    /// 'flutter_device_type' package
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
              duration: const Duration(milliseconds: 1000),
              switchInCurve: Curves.easeOutSine,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                    opacity: animation
                        .drive(CurveTween(curve: const Interval(0.7, 1.0))),
                    child: child);
              },
              child: () {
                switch (GetIt.instance<IntroStore>().stage) {
                  case IntroStage.GettingStarted:
                    return const GettingStarted();
                  case IntroStage.VersionSelection:
                    return const VersionSelection();
                  case IntroStage.TwentyEightParty:
                    return BackToSelectionWrapper(
                      child: TwentyEightParty(manually: this.widget.manually),
                    );
                  case IntroStage.InstallationSlides:
                    return BackToSelectionWrapper(
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
