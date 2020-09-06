import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/custom_sliver_list.dart';

import '../../utils/styling_helper.dart';

/// Uses a [CupertinoNavigationBar] which would usually be set for the
/// appBar property of [Scaffold] but uses it here inside a [Stack] because
/// the blurry transoarent background does not work "nice" if used in
/// the appBar property - the blurry part is only visible right at the bottom
/// border instead through the whole bar (like [CupertinoSliverNavigationBar] does
/// it for example)
class TransculentCupertinoNavBarWrapper extends StatelessWidget {
  final String appBarPreviousTitle;
  final String appBarTitle;

  final ScrollController scrollController;

  final List<Widget> listViewChildren;

  final Widget actions;

  TransculentCupertinoNavBarWrapper({
    this.appBarPreviousTitle,
    @required this.appBarTitle,
    this.scrollController,
    this.listViewChildren = const [],
    this.actions,
  }) : assert(listViewChildren != null);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          controller: this.scrollController,
          physics: StylingHelper.platformAwareScrollPhysics,
          slivers: [
            CustomSliverList(
              customTopPadding:
                  MediaQuery.of(context).padding.top + kToolbarHeight,
              children: this.listViewChildren,
            ),
          ],
        ),
        CupertinoNavigationBar(
          previousPageTitle: this.appBarPreviousTitle,
          middle: Text(this.appBarTitle),
          trailing: this.actions,
        ),
      ],
    );
  }
}
