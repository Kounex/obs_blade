import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../stores/views/intro.dart';
import '../../utils/styling_helper.dart';
import 'widgets/intro_slide.dart';
import 'widgets/slide_controls.dart';

const double kIntroControlsBottomPadding = 24.0;

class IntroView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider<IntroStore>(
      create: (_) => IntroStore(),
      builder: (context, _) => _IntroView(),
    );
  }
}

class _IntroView extends StatefulWidget {
  @override
  __IntroViewState createState() => __IntroViewState();
}

class __IntroViewState extends State<_IntroView> {
  PageController _pageController = PageController();
  List<Widget> _pageChildren;

  @override
  void didChangeDependencies() {
    _pageChildren = [
      IntroSlide(
        content: [
          Transform.scale(
            scale: 1.3,
            child: Transform.translate(
              offset: Offset(0.0, -MediaQuery.of(context).size.height * 0.05),
              child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height / 3,
                  ),
                  child: Image.asset('assets/images/base-logo.png')),
            ),
          ),
          Card(
            color: Colors.black12,
            child: Padding(
              padding: EdgeInsets.all(18.0),
              child: Text(
                'Control your OBS instance and your stream!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          )
        ],
      ),
      IntroSlide(
        content: [
          Transform.scale(
            scale: 1.3,
            child: Transform.translate(
              offset: Offset(0.0, -MediaQuery.of(context).size.height * 0.05),
              child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height / 3,
                  ),
                  child: Image.asset(
                      'assets/images/intro/intro_obs_websocket_page.png')),
            ),
          ),
          Card(
            color: Colors.black12,
            child: Padding(
              padding: EdgeInsets.all(18.0),
              child: Text(
                'Vist the OBS WebSocket GitHub page!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          )
        ],
      ),
      IntroSlide(
        content: [
          Transform.scale(
            scale: 1.3,
            child: Transform.translate(
              offset: Offset(0.0, -MediaQuery.of(context).size.height * 0.05),
              child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height / 3,
                  ),
                  child: Image.asset(
                      'assets/images/intro/intro_obs_websocket_download.png')),
            ),
          ),
          Card(
            color: Colors.black12,
            child: Padding(
              padding: EdgeInsets.all(18.0),
              child: Text(
                'Click on \'Releases\' to get to the download area!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          )
        ],
      ),
      IntroSlide(
        content: [
          Transform.scale(
            scale: 1.3,
            child: Transform.translate(
              offset: Offset(0.0, -MediaQuery.of(context).size.height * 0.05),
              child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height / 3,
                  ),
                  child: Image.asset(
                      'assets/images/intro/intro_obs_websocket_settings.png')),
            ),
          ),
          Card(
            color: Colors.black12,
            child: Padding(
              padding: EdgeInsets.all(18.0),
              child: Text(
                'After installing the correct version for your OS, make sure to restart OBS and look if Tools -> WebSocket Server Settings is available!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          )
        ],
      ),
    ];
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).backgroundColor,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _pageChildren.length,
              itemBuilder: (context, index) => _pageChildren[index],
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
                  pageController: _pageController,
                  amountChildren: _pageChildren.length,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
