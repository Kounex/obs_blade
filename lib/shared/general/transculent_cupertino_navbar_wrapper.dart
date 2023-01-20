import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../utils/styling_helper.dart';
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

  final Widget? leading;
  final Widget? actions;

  TransculentCupertinoNavBarWrapper({
    Key? key,
    this.previousTitle,
    this.title,
    this.titleWidget,
    this.scrollController,
    this.showScrollBar = false,
    this.listViewChildren = const [],
    this.customBody,
    this.leading,
    this.actions,
  })  : assert((title != null || titleWidget != null) &&
            (customBody == null || listViewChildren.isEmpty)),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget customScrollView = CustomScrollView(
      controller: this.scrollController,
      physics: StylingHelper.platformAwareScrollPhysics,
      slivers: [
        CustomSliverList(
          customTopPadding: MediaQuery.of(context).padding.top + kToolbarHeight,
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
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top +
                  kMinInteractiveDimensionCupertino,
            ),
            child: this.customBody,
          ),
        if (this.customBody == null) customScrollView,
        CupertinoNavigationBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          leading: this.leading,
          previousPageTitle: this.previousTitle,
          middle: this.titleWidget ??
              Text(
                this.title!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          trailing: this.actions,
        ),
      ],
    );
  }
}
