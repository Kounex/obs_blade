import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../stores/views/intro.dart';
import '../../../utils/routing_helper.dart';

class SlideControls extends StatelessWidget {
  final PageController pageController;
  final int amountChildren;

  SlideControls({@required this.pageController, @required this.amountChildren});

  @override
  Widget build(BuildContext context) {
    IntroStore introStore = context.watch<IntroStore>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Observer(builder: (_) {
          return CupertinoButton(
            child: SizedBox(
              width: 50.0,
              child: Text('Back'),
            ),
            onPressed: introStore.currentPage > 0
                ? () => this.pageController.previousPage(
                    duration: Duration(milliseconds: 250), curve: Curves.easeIn)
                : null,
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
          return CupertinoButton(
            child: SizedBox(
              width: 50.0,
              child: Text(
                introStore.currentPage < this.amountChildren - 1
                    ? 'Next'
                    : 'Start',
              ),
            ),
            onPressed: () {
              if (introStore.currentPage < this.amountChildren - 1) {
                this.pageController.nextPage(
                    duration: Duration(milliseconds: 250),
                    curve: Curves.easeIn);
              } else {
                // Hive.box(HiveKeys.Settings.name)
                //     .put(SettingsKeys.HasUserSeenIntro.name, true);
                Navigator.of(context)
                    .pushReplacementNamed(AppRoutingKeys.Tabs.route);
              }
            },
          );
        }),
      ],
    );
  }
}
