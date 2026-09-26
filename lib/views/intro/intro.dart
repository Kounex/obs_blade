import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';

import '../../shared/general/themed/cupertino_button.dart';
import '../../stores/views/intro.dart';
import '../../types/enums/hive_keys.dart';
import '../../types/enums/settings_keys.dart';
import '../../utils/routing_helper.dart';
import '../../utils/styling_helper.dart';
import 'widgets/intro_controls.dart';
import 'widgets/intro_page.dart';
import 'widgets/visuals/customise_visual.dart';
import 'widgets/visuals/dashboard_visual.dart';
import 'widgets/visuals/stats_visual.dart';
import 'widgets/visuals/welcome_visual.dart';

/// Intro v2 (4.0): a short, swipeable welcome - brand screen plus three
/// feature screens carrying animated live UI mockups. No setup steps (those
/// live in the FAQ), no slide locks. Shown once on launch until Skip / Start
/// persist [SettingsKeys.HasUserSeenIntro202609]; the Settings entry
/// ([manually]) returns to Settings and writes nothing.
///
/// Spec: docs/superpowers/specs/2026-09-27-intro-v2-design.md
class IntroView extends StatefulWidget {
  final bool manually;

  const IntroView({super.key, this.manually = false});

  @override
  State<IntroView> createState() => _IntroViewState();
}

class _IntroViewState extends State<IntroView> {
  final PageController _pageController = PageController();

  /// Page position as a listenable (0.0 .. pages - 1) - drives the parallax
  /// of every page and tells each mockup whether it is on screen
  final ValueNotifier<double> _page = ValueNotifier(0.0);

  bool _orientationLocked = false;

  @override
  void initState() {
    super.initState();
    GetIt.instance.resetLazySingleton<IntroStore>();
    _pageController.addListener(() {
      if (_pageController.hasClients && _pageController.page != null) {
        _page.value = _pageController.page!;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    /// Phones lock to portrait (the intro is composed for it), tablets /
    /// large screens keep every orientation - same shortest-side rule the
    /// platform uses to tell a tablet apart
    if (!_orientationLocked) {
      _orientationLocked = true;
      if (MediaQuery.sizeOf(context).shortestSide <
          StylingHelper.max_width_mobile - 100) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
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
    _pageController.dispose();
    _page.dispose();
    super.dispose();
  }

  void _finish() {
    if (!this.widget.manually) {
      Hive.box(
        HiveKeys.Settings.name,
      ).put(SettingsKeys.HasUserSeenIntro202609.name, true);
    }
    Navigator.of(context).pushReplacementNamed(
      this.widget.manually
          ? SettingsTabRoutingKeys.Landing.route
          : AppRoutingKeys.Tabs.route,
    );
  }

  void _goTo(int page) => _pageController.animateToPage(
    page,
    duration: AppMotion.slow,
    curve: AppMotion.emphasized,
  );

  List<IntroPageData> _pages(BuildContext context) => [
    IntroPageData(
      visual: (active) => WelcomeVisual(active: active),
      eyebrow: 'Welcome to OBS Blade',
      title: 'Your OBS,\nin your pocket.',
      body:
          'Control your streams and recordings from your phone or tablet - right next to your setup or across the room.',
      footer: const WelcomeFootnote(),
      hero: true,
      framed: false,
    ),
    IntroPageData(
      visual: (active) => DashboardVisual(active: active),
      framed: false,
      eyebrow: 'Dashboard',
      title: 'Your control room.',
      body:
          'Switch scenes, mix audio, toggle sources and go live or record - laid out for phone, side by side on tablet.',
    ),
    IntroPageData(
      visual: (active) => CustomiseVisual(active: active),
      eyebrow: 'Settings → Customisation',
      title: 'Make it yours.',
      body:
          'Turn on Studio Mode, pull recording, replay and hotkey controls onto the dashboard and reorder it to fit how you work.',
    ),
    IntroPageData(
      visual: (active) => StatsVisual(active: active),
      eyebrow: 'Statistics',
      title: 'Know how it went.',
      body:
          'Live stats while you\'re on air, plus a history of every stream and recording to look back on.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final List<IntroPageData> pages = _pages(context);
    final IntroStore introStore = GetIt.instance<IntroStore>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          /// Soft accent wash behind everything - brand warmth without
          /// spending the accent on a surface
          Positioned.fill(child: IntroBackdrop(page: _page)),
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: kMinInteractiveDimension,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Observer(
                        builder: (context) => AnimatedOpacity(
                          duration: AppMotion.medium,
                          opacity: introStore.currentPage < pages.length - 1
                              ? 1.0
                              : 0.0,
                          child: IgnorePointer(
                            ignoring:
                                introStore.currentPage >= pages.length - 1,
                            child: ThemedCupertinoButton(
                              text: this.widget.manually ? 'Close' : 'Skip',
                              onPressed: _finish,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pages.length,
                    onPageChanged: introStore.setCurrentPage,
                    itemBuilder: (context, index) => IntroPage(
                      index: index,
                      page: _page,
                      data: pages[index],
                    ),
                  ),
                ),
                IntroControls(
                  pageController: _pageController,
                  count: pages.length,
                  onBack: () => _goTo(introStore.currentPage - 1),
                  onNext: () => introStore.currentPage < pages.length - 1
                      ? _goTo(introStore.currentPage + 1)
                      : _finish(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
