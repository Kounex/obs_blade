import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

  final List<Widget> listViewChildren;

  TransculentCupertinoNavBarWrapper(
      {this.appBarPreviousTitle,
      @required this.appBarTitle,
      this.listViewChildren = const []})
      : assert(listViewChildren != null);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          physics: StylingHelper.platformAwareScrollPhysics,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  this.listViewChildren,
                ),
              ),
            ),
          ],
        ),
        CupertinoNavigationBar(
          previousPageTitle: this.appBarPreviousTitle,
          middle: Text(this.appBarTitle),
        ),
      ],
    );
  }
}
