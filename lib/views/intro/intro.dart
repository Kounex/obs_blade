import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../stores/views/intro.dart';
import '../../utils/styling_helper.dart';
import 'widgets/intro_slide.dart';
import 'widgets/slide_controls.dart';

const double kIntroControlsBottomPadding = 32.0;

class IntroView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider<IntroStore>(
      create: (_) => IntroStore(),
      builder: (context, _) => _IntroView(),
    );
  }
}

class _IntroView extends StatelessWidget {
  final PageController pageController = PageController();

  final List<Widget> pageChildren = [
    IntroSlide(),
    IntroSlide(),
    IntroSlide(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: StylingHelper.MAIN_BLUE,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PageView(
              controller: this.pageController,
              children: this.pageChildren,
              onPageChanged: (page) =>
                  context.read<IntroStore>().setCurrentPage(page),
            ),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom +
                  kIntroControlsBottomPadding,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: min(
                    MediaQuery.of(context).size.width * 0.75,
                    500.0,
                  ),
                ),
                child: SlideControls(
                  pageController: this.pageController,
                  amountChildren: this.pageChildren.length,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
