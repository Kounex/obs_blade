import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obs_blade/shared/design/design.dart';

class ThemedCupertinoSliverNavigationBar extends StatelessWidget {
  final Widget largeTitle;

  const ThemedCupertinoSliverNavigationBar({
    super.key,
    required this.largeTitle,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: SliverPersistentHeader(
        pinned: true,
        delegate: _GlassSliverNavigationBarDelegate(
          topInset: MediaQuery.paddingOf(context).top,
          largeTitle: this.largeTitle,
        ),
      ),
    );
  }
}

/// Geometry mirrors the framework's large-title sliver bar
/// (`_LargeTitleNavigationBarSliverDelegate`): the collapsed bar pins at the
/// shared 55pt content height (token-delta §3), the large-title extension
/// scrolls under it; the glass surface (blur, bar color, bottom-edge
/// specular) is painted by [GlassBar]
class _GlassSliverNavigationBarDelegate extends SliverPersistentHeaderDelegate {
  static const double _largeTitleHeightExtension = 52.0;
  static const double _showLargeTitleThreshold = 10.0;
  static const double _edgePadding = 16.0;
  static const double _bottomPadding = 8.0;

  final double topInset;
  final Widget largeTitle;

  _GlassSliverNavigationBarDelegate({
    required this.topInset,
    required this.largeTitle,
  });

  double get _persistentHeight => this.topInset + GlassBar.minContentHeight;

  @override
  double get minExtent => this._persistentHeight;

  @override
  double get maxExtent => this._persistentHeight + _largeTitleHeightExtension;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final bool showLargeTitle =
        shrinkOffset <
        this.maxExtent - this.minExtent - _showLargeTitleThreshold;

    /// Status bar icon parity with the framework bar's
    /// `_wrapWithBackground`: derived from the bar surface luminance, which
    /// is now the glass token
    final bool barIsDark =
        appGlassOf(context).barColor.computeLuminance() < 0.179;
    final SystemUiOverlayStyle overlayStyle = barIsDark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: overlayStyle.statusBarColor,
        statusBarBrightness: overlayStyle.statusBarBrightness,
        statusBarIconBrightness: overlayStyle.statusBarIconBrightness,
        systemStatusBarContrastEnforced:
            overlayStyle.systemStatusBarContrastEnforced,
      ),
      child: GlassBar(
        contentEdge: GlassBarEdge.bottom,
        child: Stack(
          children: [
            Positioned(
              top: this._persistentHeight,
              left: 0.0,
              right: 0.0,
              bottom: 0.0,
              child: ClipRect(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: _edgePadding,
                    bottom: _bottomPadding,
                  ),
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: AnimatedOpacity(
                      opacity: showLargeTitle ? 1.0 : 0.0,
                      duration: AppMotion.fast,
                      child: Semantics(
                        header: true,
                        child: DefaultTextStyle(
                          style: CupertinoTheme.of(
                            context,
                          ).textTheme.navLargeTitleTextStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          child: Align(
                            alignment: AlignmentDirectional.bottomStart,
                            child: this.largeTitle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0.0,
              left: 0.0,
              right: 0.0,
              child: Padding(
                padding: EdgeInsets.only(top: this.topInset),
                child: SizedBox(
                  height: GlassBar.minContentHeight,
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: NavigationToolbar(
                      leading: ModalRoute.of(context)?.canPop ?? false
                          ? const CupertinoNavigationBarBackButton()
                          : null,
                      middle: AnimatedOpacity(
                        opacity: showLargeTitle ? 0.0 : 1.0,
                        duration: AppMotion.fast,
                        child: DefaultTextStyle(
                          style: CupertinoTheme.of(
                            context,
                          ).textTheme.navTitleTextStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          child: this.largeTitle,
                        ),
                      ),
                      middleSpacing: 6.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _GlassSliverNavigationBarDelegate oldDelegate) =>
      this.topInset != oldDelegate.topInset ||
      this.largeTitle != oldDelegate.largeTitle;
}
