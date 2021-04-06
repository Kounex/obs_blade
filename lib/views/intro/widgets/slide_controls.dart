import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../shared/general/themed/themed_cupertino_button.dart';
import '../../../stores/views/intro.dart';
import '../../../types/enums/hive_keys.dart';
import '../../../types/enums/settings_keys.dart';
import '../../../utils/routing_helper.dart';

class SlideControls extends StatelessWidget {
  final PageController pageController;
  final int amountChildren;
  final bool manually;

  SlideControls({
    required this.pageController,
    required this.amountChildren,
    this.manually = false,
  });

  @override
  Widget build(BuildContext context) {
    IntroStore introStore = context.watch<IntroStore>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Observer(builder: (_) {
          return SizedBox(
            width: 50.0,
            child: ThemedCupertinoButton(
              padding: EdgeInsets.all(0),
              onPressed: introStore.currentPage > 0
                  ? () => this.pageController.previousPage(
                      duration: Duration(milliseconds: 250),
                      curve: Curves.easeIn)
                  : null,
              text: 'Back',
            ),
          );
        }),
        SmoothPageIndicator(
            controller: this.pageController,
            effect: ScrollingDotsEffect(
              activeDotColor: Theme.of(context).toggleableActiveColor,
              dotHeight: 12.0,
              dotWidth: 12.0,
            ),
            count: this.amountChildren),
        Observer(builder: (_) {
          return SizedBox(
            width: 50.0,
            child: ThemedCupertinoButton(
              padding: EdgeInsets.all(0),
              onPressed: () {
                if (introStore.currentPage < this.amountChildren - 1) {
                  this.pageController.nextPage(
                      duration: Duration(milliseconds: 250),
                      curve: Curves.easeIn);
                } else {
                  Hive.box(HiveKeys.Settings.name)
                      .put(SettingsKeys.HasUserSeenIntro.name, true);
                  Navigator.of(context).pushReplacementNamed(this.manually
                      ? SettingsTabRoutingKeys.Landing.route
                      : AppRoutingKeys.Tabs.route);
                }
              },
              text: introStore.currentPage < this.amountChildren - 1
                  ? 'Next'
                  : 'Start',
            ),
          );
        }),
      ],
    );
  }
}
