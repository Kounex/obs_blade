import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/general/social_block.dart';

import '../../stores/views/intro.dart';
import 'widgets/intro_slide.dart';
import 'widgets/slide_controls.dart';

const double kIntroControlsBottomPadding = 24.0;

class IntroView extends StatefulWidget {
  final bool manually;

  const IntroView({Key? key, this.manually = false}) : super(key: key);

  @override
  _IntroViewState createState() => _IntroViewState();
}

class _IntroViewState extends State<IntroView> {
  final PageController _pageController = PageController();
  late List<Widget> _pageChildren;

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
    GetIt.instance.resetLazySingleton<IntroStore>();

    _pageChildren = [
      const IntroSlide(
        imagePath: 'assets/images/base_logo.png',
        slideTextSpans: [
          TextSpan(
            text:
                'Control your OBS instance and easily manage your stream - live!',
          ),
        ],
      ),
      IntroSlide(
        imagePath: 'assets/images/intro/intro_obs_websocket_page.png',
        slideTextSpans: const [
          TextSpan(
            text:
                'Visit the OBS WebSocket GitHub page to get the plugin to make this app work:',
          ),
        ],
        additionalChild: SocialBlock(
          topPadding: 12.0,
          bottomPadding: 0,
          socialInfos: [
            SocialEntry(
              link: 'https://github.com/Palakis/obs-websocket',
              textStyle: Theme.of(context)
                  .textTheme
                  .headline6!
                  .copyWith(color: Colors.blue),
            ),
          ],
        ),
      ),
      const IntroSlide(
        imagePath: 'assets/images/intro/intro_obs_websocket_download.png',
        slideTextSpans: [
          TextSpan(
            text:
                'Click on \'Releases\' to get to the download area and select the correct installer (for your operating system)',
          ),
        ],
      ),
      const IntroSlide(
        imagePath: 'assets/images/intro/intro_obs_websocket_settings.png',
        slideTextSpans: [
          TextSpan(
            text:
                'After installing the correct version, make sure to restart OBS and look if Tools -> WebSocket Server Settings is available - then you are good to go!',
          ),
        ],
      ),
    ];

    return Scaffold(
      body: Container(
        color: Theme.of(context).backgroundColor,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pageChildren.length,
                itemBuilder: (context, index) => _pageChildren[index],
                onPageChanged: (page) =>
                    GetIt.instance<IntroStore>().setCurrentPage(page),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom +
                    kIntroControlsBottomPadding,
              ),
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
                  manually: this.widget.manually,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
