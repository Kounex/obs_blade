import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/base/button.dart';
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
    super.key,
    required this.pageController,
    required this.amountChildren,
    required this.onSlideLockWaited,
    this.manually = false,
  });

  @override
  State<SlideControls> createState() => _SlideControlsState();
}

class _SlideControlsState extends State<SlideControls> {
  @override
  Widget build(BuildContext context) {
    IntroStore introStore = GetIt.instance<IntroStore>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Observer(
              builder: (context) {
                return ThemedCupertinoButton(
                  padding: const EdgeInsets.all(0),
                  onPressed: introStore.currentPage > 0
                      ? () {
                          introStore.setLockedOnSlide(false);
                          this.widget.pageController.previousPage(
                            duration: AppMotion.medium,
                            curve: AppMotion.standard,
                          );
                        }
                      : null,
                  text: 'Back',
                );
              },
            ),
          ),
        ),
        SmoothPageIndicator(
          controller: this.widget.pageController,

          /// Unified page-dot grammar (same as the paywall benefits): worm
          /// effect, neutral active/inactive levels
          effect: WormEffect(
            dotColor: Theme.of(
              context,
            ).extension<AppTextColors>()!.textOrnament,
            activeDotColor: Theme.of(
              context,
            ).extension<AppTextColors>()!.textPrimary,
            dotHeight: 8.0,
            dotWidth: 8.0,
            spacing: AppSpacing.sm,
          ),
          count: this.widget.amountChildren,
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Observer(
              builder: (context) {
                return SizedBox(
                  height: 52.0,
                  child: AnimatedSwitcher(
                    duration: AppMotion.medium,

                    /// While the per-slide lock is running the countdown ring
                    /// takes the place of the (locked) primary CTA
                    child: introStore.lockedOnSlide
                        ? BaseProgressIndicator(
                            size: 52.0,
                            countdownInSeconds: introStore.slideLockSeconds,
                            onCountdownDone: () {
                              introStore.setLockedOnSlide(false);
                              this.widget.onSlideLockWaited();
                            },
                          )
                        : BaseButton(
                            onPressed: () {
                              if (introStore.currentPage <
                                  this.widget.amountChildren - 1) {
                                this.widget.pageController.nextPage(
                                  duration: AppMotion.medium,
                                  curve: AppMotion.standard,
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
                            },
                            text:
                                introStore.currentPage <
                                    this.widget.amountChildren - 1
                                ? 'Next'
                                : 'Start',
                          ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
