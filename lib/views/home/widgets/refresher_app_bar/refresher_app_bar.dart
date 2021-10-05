import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/flutter_modified/translucent_sliver_app_bar.dart';

import '../../../../shared/animator/fader.dart';
import 'scroll_refresh_icon.dart';

const double kRefresherAppBarHeight = 44.0;

class RefresherAppBar extends StatelessWidget {
  final double? expandedHeight;
  final String imagePath;

  const RefresherAppBar({
    Key? key,
    this.expandedHeight,
    required this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TransculentSliverAppBar(
      pinned: true,
      stretch: true,
      elevation: 0,
      toolbarHeight: kRefresherAppBarHeight,
      expandedHeight: this.expandedHeight,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: LayoutBuilder(
          builder: (context, constraints) {
            if ((constraints.maxHeight -
                        (MediaQuery.of(context).viewPadding.top - 16))
                    .toInt() <=
                kRefresherAppBarHeight.toInt()) {
              return Fader(
                child: Transform.translate(
                  offset: const Offset(0, 4.0),
                  child: Text(
                    'OBS Blade',
                    style:
                        CupertinoTheme.of(context).textTheme.navTitleTextStyle,
                  ),
                ),
              );
            }
            return ScrollRefreshIcon(
              expandedBarHeight: this.expandedHeight,
              currentBarHeight: constraints.maxHeight,
            );
          },
        ),
        background: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              /// TODO: Will be managed later for pro subscribers when choosing their own logo
              color: Colors.transparent,
            ),
            Image.asset(this.imagePath),
          ],
        ),
        collapseMode: CollapseMode.parallax,
        stretchModes: const [
          StretchMode.blurBackground,
          StretchMode.zoomBackground
        ],
      ),
    );
  }
}
