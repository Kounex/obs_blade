import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../utils/styling_helper.dart';
import '../design/design.dart';
import 'custom_sliver_list.dart';

/// Uses a [CupertinoNavigationBar] which would usually be set for the
/// appBar property of [Scaffold] but uses it here inside a [Stack] because
/// the blurry transparent background does not work "nice" if used in
/// the appBar property - the blurry part is only visible right at the bottom
/// border instead through the whole bar (like [CupertinoSliverNavigationBar] does
/// it for example)
class TransculentCupertinoNavBarWrapper extends StatelessWidget {
  final String? previousTitle;
  final String? title;
  final Widget? titleWidget;

  final ScrollController? scrollController;
  final bool showScrollBar;

  final List<Widget> listViewChildren;
  final Widget? customBody;

  /// Lets [customBody] extend behind the translucent bar (the body then
  /// owns its own top inset) so scrolling content passes underneath and
  /// the blur is actually visible - matches the listViewChildren path,
  /// whose scroll view always sits under the bar
  final bool extendBodyBehindBar;

  final Widget? leading;
  final Widget? actions;

  TransculentCupertinoNavBarWrapper({
    super.key,
    this.previousTitle,
    this.title,
    this.titleWidget,
    this.scrollController,
    this.showScrollBar = false,
    this.listViewChildren = const [],
    this.customBody,
    this.extendBodyBehindBar = false,
    this.leading,
    this.actions,
  }) : assert(customBody == null || listViewChildren.isEmpty),
       super();

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.paddingOf(context).top;
    final double barHeight = topInset + GlassBar.minContentHeight;

    /// The framework bar derives the status bar icon style from its bar
    /// color luminance (`_wrapWithBackground`) - its surface is now
    /// transparent (painted by [GlassBar]), so hand it the luminance of
    /// the glass token instead
    final bool barIsDark =
        Theme.of(context).extension<AppGlass>()!.barColor.computeLuminance() <
        0.179;

    Widget customScrollView = CustomScrollView(
      controller: this.scrollController,
      physics: StylingHelper.platformAwareScrollPhysics,
      slivers: [
        CustomSliverList(
          customTopPadding: barHeight,
          children: this.listViewChildren,
        ),
      ],
    );

    if (this.showScrollBar) {
      customScrollView = Scrollbar(
        controller: this.scrollController,
        child: customScrollView,
      );
    }

    return Stack(
      children: [
        if (this.customBody != null)
          Padding(
            padding: this.extendBodyBehindBar
                ? EdgeInsets.zero
                : EdgeInsets.only(top: barHeight),
            child: this.customBody,
          ),
        if (this.customBody == null) customScrollView,

        /// The glass surface (blur, bar color, bottom-edge specular) is
        /// painted by [GlassBar] - the framework bar itself stays
        /// transparent, borderless and blur-free; its fixed 44pt toolbar is
        /// centered inside the shared 55pt content height (token-delta §3)
        GlassBar(
          contentEdge: GlassBarEdge.bottom,
          child: SizedBox(
            height: barHeight,
            child: Padding(
              padding: EdgeInsets.only(top: topInset),
              child: Center(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: CupertinoNavigationBar(
                    backgroundColor: Colors.transparent,
                    border: null,
                    enableBackgroundFilterBlur: false,
                    automaticBackgroundVisibility: false,
                    brightness: barIsDark ? Brightness.dark : Brightness.light,
                    leading: this.leading,
                    previousPageTitle: this.previousTitle,
                    middle:
                        this.titleWidget ??
                        (this.title != null
                            ? Text(
                                this.title!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null),
                    trailing: this.actions,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
