import 'package:flutter/material.dart';
import 'package:obs_station/views/landing/widgets/refresher_app_bar/scroll_refresh_icon.dart';

class RefresherAppBar extends StatelessWidget {
  final double expandedHeight;
  final String imagePath;

  RefresherAppBar({
    this.expandedHeight,
    @required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: this.expandedHeight,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: ScrollRefreshIcon(
          expandedBarHeight: this.expandedHeight,
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
