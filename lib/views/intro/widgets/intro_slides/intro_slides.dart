import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/shared/general/base/divider.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import '../../../../shared/general/social_block.dart';
import '../../../../shared/general/themed/rich_text.dart';
import '../../../../stores/views/intro.dart';
import 'intro_slide.dart';
import 'slide_controls.dart';

const double kIntroControlsBottomPadding = 24.0;

class IntroSlides extends StatefulWidget {
  final bool manually;

  const IntroSlides({Key? key, this.manually = false}) : super(key: key);

  @override
  _IntroSlidesState createState() => _IntroSlidesState();
}

class _IntroSlidesState extends State<IntroSlides> {
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
            introStore.slideLockSecondsLeft--;
            if (introStore.slideLockSecondsLeft <= 0) {
              _timerToContinue!.cancel();
              introStore.setLockedOnSlide(false);
            }
          });
        }
      },
    ));
  }

  @override
  void dispose() {
    for (var d in _disposers) {
      d();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _pageChildren = [
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
              child: Observer(builder: (context) {
                return PageView.builder(
                  controller: _pageController,
                  itemCount: _pageChildren.length,
                  physics: GetIt.instance<IntroStore>().lockedOnSlide
                      ? const NeverScrollableScrollPhysics()
                      : StylingHelper.platformAwareScrollPhysics,
                  itemBuilder: (context, index) => _pageChildren[index],
                  onPageChanged: (page) =>
                      GetIt.instance<IntroStore>().setCurrentPage(page),
                );
              }),
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
