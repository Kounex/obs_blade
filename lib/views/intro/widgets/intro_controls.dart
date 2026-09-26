import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/base/button.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../shared/general/base/constrained_box.dart';
import '../../../shared/general/themed/cupertino_button.dart';
import '../../../stores/views/intro.dart';

/// Width reserved for the Back button when the last-page CTA stretches
const double _kBackWidth = 88.0;

/// Width of the compact Next button
const double _kNextWidth = 104.0;

/// Bottom control bar of the intro: Back · page dots · Next / Start. The
/// primary button stretches into "Get started" on the last page
class IntroControls extends StatelessWidget {
  final PageController pageController;
  final int count;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const IntroControls({
    super.key,
    required this.pageController,
    required this.count,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final IntroStore introStore = GetIt.instance<IntroStore>();
    final AppTextColors textColors = Theme.of(
      context,
    ).extension<AppTextColors>()!;

    return BaseConstrainedBox(
      maxWidth: 520.0,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Observer(
        builder: (context) {
          final bool first = introStore.currentPage == 0;
          final bool last = introStore.currentPage == this.count - 1;

          /// Back left, dots centered, primary button right. On the last
          /// page the dots fade and the button stretches into a wide
          /// "Get started" CTA
          return LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: 48.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedOpacity(
                      duration: AppMotion.medium,
                      opacity: first ? 0.0 : 1.0,
                      child: IgnorePointer(
                        ignoring: first,
                        child: ThemedCupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          text: 'Back',
                          onPressed: this.onBack,
                        ),
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    duration: AppMotion.medium,
                    opacity: last ? 0.0 : 1.0,
                    child: SmoothPageIndicator(
                      controller: this.pageController,
                      count: this.count,
                      onDotClicked: (index) =>
                          this.pageController.animateToPage(
                            index,
                            duration: AppMotion.slow,
                            curve: AppMotion.emphasized,
                          ),

                      /// Unified page-dot grammar (same as the paywall
                      /// benefits): neutral active / inactive levels
                      effect: ExpandingDotsEffect(
                        dotColor: textColors.textOrnament,
                        activeDotColor: textColors.textPrimary,
                        dotHeight: 8.0,
                        dotWidth: 8.0,
                        expansionFactor: 3.0,
                        spacing: AppSpacing.sm,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedContainer(
                      duration: AppMotion.slow,
                      curve: AppMotion.emphasized,
                      width: last
                          ? constraints.maxWidth - _kBackWidth
                          : _kNextWidth,
                      height: 48.0,
                      child: BaseButton(
                        shrinkWidth: true,
                        text: last ? 'Get started' : 'Next',
                        onPressed: this.onNext,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
