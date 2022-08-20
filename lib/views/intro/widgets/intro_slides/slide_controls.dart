import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/shared/overlay/base_progress_indicator.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../shared/general/themed/cupertino_button.dart';
import '../../../../stores/views/intro.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/enums/settings_keys.dart';
import '../../../../utils/routing_helper.dart';

class SlideControls extends StatefulWidget {
  final PageController pageController;
  final int amountChildren;
  final VoidCallback onSlideLockWaited;

  final bool manually;

  const SlideControls({
    Key? key,
    required this.pageController,
    required this.amountChildren,
    required this.onSlideLockWaited,
    this.manually = false,
  }) : super(key: key);

  @override
  State<SlideControls> createState() => _SlideControlsState();
}

class _SlideControlsState extends State<SlideControls> {
  Timer? _lockTimer;

  final List<ReactionDisposer> _disposers = [];

  @override
  void initState() {
    super.initState();

    _disposers.add(
      reaction<bool>((_) => GetIt.instance<IntroStore>().lockedOnSlide,
          (lockedOnSlide) {
        if (lockedOnSlide && _lockTimer == null) {
          // _lockTimer = Timer.periodic(duration, (timer) { })
        }
        if (!lockedOnSlide) {
          _lockTimer?.cancel();
          _lockTimer = null;
        }
      }),
    );
  }

  @override
  void dispose() {
    for (final d in _disposers) {
      d();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    IntroStore introStore = GetIt.instance<IntroStore>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Observer(builder: (_) {
          return SizedBox(
            height: 52.0,
            width: 52.0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ThemedCupertinoButton(
                  padding: const EdgeInsets.all(0),
                  onPressed: introStore.currentPage > 0
                      ? () {
                          introStore.setLockedOnSlide(false);
                          this.widget.pageController.previousPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeIn,
                              );
                        }
                      : null,
                  text: 'Back',
                ),
                // if (introStore.lockedOnSlide && introStore.currentPage != 0)
                //   BaseProgressIndicator(
                //     size: 52.0,
                //     countdownInSeconds: introStore.slideLockSeconds,
                //     onCountdownDone: () => introStore.setLockedOnSlide(false),
                //   )
              ],
            ),
          );
        }),
        SmoothPageIndicator(
          controller: this.widget.pageController,
          effect: ScrollingDotsEffect(
            activeDotColor: Theme.of(context)
                .switchTheme
                .trackColor!
                .resolve({MaterialState.selected})!,
            dotHeight: 12.0,
            dotWidth: 12.0,
          ),
          count: this.widget.amountChildren,
        ),
        Observer(builder: (_) {
          return SizedBox(
            height: 52.0,
            width: 52.0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ThemedCupertinoButton(
                  padding: const EdgeInsets.all(0),
                  onPressed: !introStore.lockedOnSlide
                      ? () {
                          if (introStore.currentPage <
                              this.widget.amountChildren - 1) {
                            this.widget.pageController.nextPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeIn,
                                );
                          } else {
                            Hive.box(HiveKeys.Settings.name).put(
                              SettingsKeys.HasUserSeenIntro202208.name,
                              true,
                            );
                            Navigator.of(context).pushReplacementNamed(
                              this.widget.manually
                                  ? SettingsTabRoutingKeys.Landing.route
                                  : AppRoutingKeys.Tabs.route,
                            );
                          }
                        }
                      : null,
                  text: introStore.currentPage < this.widget.amountChildren - 1
                      ? 'Next'
                      : 'Start',
                ),
                if (introStore.lockedOnSlide)
                  BaseProgressIndicator(
                    size: 52.0,
                    countdownInSeconds: introStore.slideLockSeconds,
                    onCountdownDone: () {
                      introStore.setLockedOnSlide(false);
                      this.widget.onSlideLockWaited();
                    },
                  )
              ],
            ),
          );
        }),
      ],
    );
  }
}
