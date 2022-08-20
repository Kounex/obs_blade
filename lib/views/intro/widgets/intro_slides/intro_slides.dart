import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/shared/general/base/divider.dart';

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
  // Timer? _timerToContinue;

  final List<bool> _pagesLockedPreviously = [false, false, false];
  final List<bool> _pagesToLockOn = [true, true, true];

  final List<ReactionDisposer> _disposers = [];

  @override
  void initState() {
    super.initState();

    IntroStore introStore = GetIt.instance<IntroStore>();
    introStore.setCurrentPage(0);

    _checkAndSetSlideLock(introStore, 0);

    _disposers.add(reaction<int>(
      (_) => introStore.currentPage,
      (currentPage) {
        _checkAndSetSlideLock(introStore, currentPage);
      },
    ));
  }

  void _checkAndSetSlideLock(IntroStore introStore, int currentPage) {
    if (!this.widget.manually &&
        _pagesToLockOn[currentPage] &&
        !_pagesLockedPreviously[currentPage]) {
      introStore.setLockedOnSlide(true);
    }
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
                bottomPadding: 12.0,
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
            const TextSpan(
              text:
                  'Click on the "Releases" link in the Downloads section as seen in the screenshot or ',
            ),
            WidgetSpan(
              child: SocialBlock(
                topPadding: 0.0,
                bottomPadding: 0.0,
                socialInfos: [
                  SocialEntry(
                    linkText: 'here',
                    link:
                        'https://github.com/obsproject/obs-websocket/releases',
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
                  'Scroll down to "Assets" and download the correct installer (for your operating system)\n\n',
            ),
            TextSpan(
              text: 'IMPORTANT: Download version 5.X and above!',
              style: TextStyle(fontWeight: FontWeight.bold),
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
                  'After installing the plugin and restarting OBS, check if Tools -> obs-websocket Settings is available and use the recommended settings (above) - Enjoy!',
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
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) => _pageChildren[index],
                  onPageChanged: (page) =>
                      GetIt.instance<IntroStore>().setCurrentPage(page),
                );
              }),
            ),
            const BaseDivider(),
            const SizedBox(height: 18.0),
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
                  onSlideLockWaited: () => _pagesLockedPreviously[
                      GetIt.instance<IntroStore>().currentPage] = true,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
