import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/utils/routing_helper.dart';
import 'package:obs_blade/utils/styling_helper.dart';
import 'package:obs_blade/views/intro/widgets/intro_slide.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class IntroView extends StatefulWidget {
  @override
  _IntroViewState createState() => _IntroViewState();
}

class _IntroViewState extends State<IntroView> {
  PageController _pageController = PageController();
  int _currentPage = 0;

  List<Widget> _pageChildren = [
    IntroSlide(),
    IntroSlide(),
    IntroSlide(),
  ];

  @override
  void initState() {
    _pageController.addListener(_checkPageScroll);
    super.initState();
  }

  void _checkPageScroll() {
    if (_pageController.page.floor() != _currentPage) {
      setState(() => _currentPage = _pageController.page.floor());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: StylingHelper.MAIN_BLUE,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PageView(
              controller: _pageController,
              children: _pageChildren,
            ),
            Positioned(
              bottom: 24.0,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: min(
                    MediaQuery.of(context).size.width * 0.75,
                    500.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: SizedBox(
                        width: 50.0,
                        child: Text('Back'),
                      ),
                      onPressed: _currentPage > 0
                          ? () => _pageController.previousPage(
                              duration: Duration(milliseconds: 250),
                              curve: Curves.easeIn)
                          : null,
                    ),
                    SmoothPageIndicator(
                      controller: _pageController,
                      effect: ScrollingDotsEffect(
                        activeDotColor: StylingHelper.MAIN_RED,
                        dotHeight: 12.0,
                        dotWidth: 12.0,
                      ),
                      count: _pageChildren.length,
                    ),
                    CupertinoButton(
                      child: SizedBox(
                        width: 50.0,
                        child: Text(
                          _currentPage < _pageChildren.length - 1
                              ? 'Next'
                              : 'Start',
                        ),
                      ),
                      onPressed: () => _currentPage < _pageChildren.length - 1
                          ? _pageController.nextPage(
                              duration: Duration(milliseconds: 250),
                              curve: Curves.easeIn)
                          : Navigator.of(context)
                              .pushReplacementNamed(AppRoutingKeys.Tabs.route),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
