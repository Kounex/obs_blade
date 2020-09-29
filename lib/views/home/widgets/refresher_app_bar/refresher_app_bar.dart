import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/flutter_modified/translucent_sliver_app_bar.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import '../../../../shared/animator/fader.dart';
import 'scroll_refresh_icon.dart';

const double kRefresherAppBarHeight = 44.0;

class RefresherAppBar extends StatelessWidget {
  final double expandedHeight;
  final String imagePath;

  RefresherAppBar({
    this.expandedHeight,
    @required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return TransculentSliverAppBar(
      pinned: true,
      stretch: true,
      elevation: 0,
      toolbarHeight: kRefresherAppBarHeight,
      expandedHeight: this.expandedHeight,
      flexibleSpace: FlexibleSpaceBar(
        title: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => constraints.maxHeight -
                          (MediaQuery.of(context).padding.top - 16) <=
                      kRefresherAppBarHeight
                  ? Fader(
                      child: Transform.translate(
                        offset: Offset(0, 4.0),
                        child: Text(
                          'OBS Blade',
                          style: CupertinoTheme.of(context)
                              .textTheme
                              .navTitleTextStyle,
                        ),
                      ),
                    )
                  : Container(),
            ),
            ScrollRefreshIcon(
              expandedBarHeight: this.expandedHeight,
            ),
          ],
        ),
        background: Padding(
            padding: EdgeInsets.only(top: 32.0),
            child: Image.asset(this.imagePath)),
        collapseMode: CollapseMode.parallax,
        stretchModes: [StretchMode.blurBackground, StretchMode.zoomBackground],
      ),
    );
  }
}
