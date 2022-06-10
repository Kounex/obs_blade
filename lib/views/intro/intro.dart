import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/shared/general/base/divider.dart';

import '../../shared/general/social_block.dart';
import '../../shared/general/themed/rich_text.dart';
import '../../stores/views/intro.dart';
import '../../utils/styling_helper.dart';
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

  /// Will be used to force the user to stay on a slide for a given time
  /// before being able to move on. This will ensure they at least see
  /// a slide for a speciic time and hopefully use this time to take
  /// a look at the instrcutions / possibilities
  Timer? _timerToContinue;

  final List<bool> _pagesLockedPreviously = [false, false, false, false];
  final List<bool> _pagesToLockOn = [false, true, false, false];

  final List<ReactionDisposer> _disposers = [];

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

    IntroStore introStore = GetIt.instance<IntroStore>();

    _disposers.add(reaction<int>(
      (_) => introStore.currentPage,
      (currentPage) {
        if (!this.widget.manually &&
            _pagesToLockOn[currentPage] &&
            !_pagesLockedPreviously[currentPage]) {
          _pagesLockedPreviously[currentPage] = true;

          introStore.setLockedOnSlide(true);

          _timerToContinue =
              Timer.periodic(const Duration(seconds: 1), (timer) {
            _slideLockSecondsLeft--;
            if (_slideLockSecondsLeft <= 0) {
              _timerToContinue!.cancel();
              introStore.setLockedOnSlide(false);
              _slideLockSecondsLeft = kSecondsToLockSlide;
            }
          });
        }
      },
    ));
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    for (var d in _disposers) {
      d();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    GetIt.instance.resetLazySingleton<IntroStore>();

    _pageChildren = [
      IntroSlide(
        imagePath: StylingHelper.brightnessAwareOBSLogo(context),
        child: ThemedRichText(
          textSpans: const [
            TextSpan(
              text:
                  'Control your OBS instance and easily manage your stream - live!',
            ),
          ],
          textAlign: TextAlign.center,
          textStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                fontSize: 20,
              ),
        ),
      ),
      IntroSlide(
        imagePath: 'assets/images/intro/intro_obs_websocket_page.png',
        child: ThemedRichText(
          textSpans: [
            const TextSpan(
              text:
                  'Visit the OBS WebSocket GitHub page to get the plugin to make this app work:',
            ),
            WidgetSpan(
              child: SocialBlock(
                topPadding: 12.0,
                bottomPadding: 0,
                socialInfos: [
                  SocialEntry(
                    link: 'https://github.com/obsproject/obs-websocket',
                    textStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                          fontSize: 16,
                        ),
                  ),
                ],
              ),
            ),
          ],
          textAlign: TextAlign.left,
          textStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                fontSize: 16,
              ),
        ),
      ),
      IntroSlide(
        imagePath: 'assets/images/intro/intro_obs_websocket_download.png',
        child: ThemedRichText(
          textSpans: const [
            TextSpan(
              text:
                  'Click on \'Releases\' to get to the download area and select the correct installer (for your operating system)\n\nIMPORTANT: Download version 4.9.1!',
            ),
          ],
          textAlign: TextAlign.left,
          textStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                fontSize: 16,
              ),
        ),
      ),
      IntroSlide(
        imagePath: 'assets/images/intro/intro_obs_websocket_settings.png',
        child: ThemedRichText(
          textSpans: const [
            TextSpan(
              text:
                  'After installing the plugin and restarting OBS, look if Tools -> WebSocket Server Settings is available and use the recommended settings (above) - Enjoy!',
            ),
          ],
          textAlign: TextAlign.left,
          textStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                fontSize: 16,
              ),
        ),
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
            const BaseDivider(),
            const SizedBox(height: 24.0),
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
