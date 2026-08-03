import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/base/constrained_box.dart';
import 'package:obs_blade/shared/general/base/divider.dart';

import '../../../../shared/general/themed/rich_text.dart';
import '../../../../stores/views/intro.dart';
import '../../../../utils/styling_helper.dart';
import '../../intro.dart';
import 'intro_slide.dart';
import 'slide_controls.dart';

class IntroSlides extends StatefulWidget {
  final bool manually;

  const IntroSlides({super.key, this.manually = false});

  @override
  _IntroSlidesState createState() => _IntroSlidesState();
}

class _IntroSlidesState extends State<IntroSlides> {
  final PageController _pageController = PageController();
  late List<Widget> _pageChildren;

  /// First-time users stay on early slides briefly so they actually read
  /// the WebSocket setup steps; app-tour slides stay unlocked.
  final List<bool> _pagesLockedPreviously = [false, false, false, false, false];
  final List<bool> _pagesToLockOn = [true, true, false, false, false];

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
        currentPage < _pagesToLockOn.length &&
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

  Widget _tourIcon(BuildContext context, IconData icon) {
    final Color accent = Theme.of(context).colorScheme.secondary;
    return Container(
      width: 88.0,
      height: 88.0,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, size: 40.0, color: accent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle bodyStyle = Theme.of(context).textTheme.bodyLarge!;

    _pageChildren = [
      IntroSlide(
        imagePath: 'assets/images/intro/intro_obs_websocket_settings.png',
        child: ThemedRichText(
          textSpans: [
            TextSpan(
              text: 'WebSocket is built into OBS Studio.\n\n',
              style: bodyStyle.copyWith(fontWeight: FontWeight.w600),
            ),
            const TextSpan(
              text:
                  'Open Tools → WebSocket Server Settings and turn the server on. No separate plugin install is required on current OBS versions.',
            ),
          ],
          textAlign: TextAlign.left,
          textStyle: bodyStyle,
        ),
      ),
      IntroSlide(
        imagePath: 'assets/images/intro/intro_obs_websocket_settings.png',
        child: ThemedRichText(
          textSpans: [
            const TextSpan(
              text:
                  'Use the recommended defaults, set a password, and note the port (usually 4455).\n\n',
            ),
            TextSpan(
              text: 'You\'ll enter those same details when connecting from this app.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).extension<AppStatusColors>()!.warning,
              ),
            ),
          ],
          textAlign: TextAlign.left,
          textStyle: bodyStyle,
        ),
      ),
      IntroSlide(
        leading: _tourIcon(context, CupertinoIcons.house_fill),
        child: ThemedRichText(
          textSpans: const [
            TextSpan(
              text:
                  'Home is your connection hub.\n\nAdd your OBS host (IP or hostname), port, and password, then connect. Saved connections stay one tap away next time — on phone or tablet.',
            ),
          ],
          textAlign: TextAlign.center,
          textStyle: bodyStyle,
        ),
      ),
      IntroSlide(
        leading: _tourIcon(context, CupertinoIcons.square_grid_2x2_fill),
        child: ThemedRichText(
          textSpans: const [
            TextSpan(
              text:
                  'The Dashboard is your control room.\n\nSwitch scenes, tweak audio, preview the program, and start or stop stream and recording. On larger screens, Scene Items and Audio sit side by side for faster reach.',
            ),
          ],
          textAlign: TextAlign.center,
          textStyle: bodyStyle,
        ),
      ),
      IntroSlide(
        leading: Column(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Image.asset(
                StylingHelper.brightnessAwareOBSLogo(context),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _tourIcon(context, CupertinoIcons.chart_bar_alt_fill),
          ],
        ),
        child: ThemedRichText(
          textSpans: [
            TextSpan(
              text: 'You\'re ready.\n\n',
              style: bodyStyle.copyWith(fontWeight: FontWeight.w600),
            ),
            const TextSpan(
              text:
                  'Statistics keeps past streams and recordings so you can review performance later. Explore Settings anytime to customise the dashboard layout for your setup.',
            ),
          ],
          textAlign: TextAlign.center,
          textStyle: bodyStyle,
        ),
      ),
    ];

    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.background,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pageChildren.length,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) => Center(
                  child: BaseConstrainedBox(
                    child: _pageChildren[index],
                  ),
                ),
                onPageChanged: (page) =>
                    GetIt.instance<IntroStore>().setCurrentPage(page),
              ),
            ),
            const BaseDivider(),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom +
                    kIntroControlsBottomPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: min(
                    MediaQuery.sizeOf(context).width * 0.75,
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
