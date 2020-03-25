import 'package:flutter/material.dart';
import 'package:obs_station/views/landing/widgets/scroll_refresh_icon.dart';

class RefresherAppBar extends StatelessWidget {
  final double expandedHeight;
  final double stretchTriggerOffset;
  final String imagePath;
  final Future<void> onStretchTrigger;

  RefresherAppBar(
      {this.expandedHeight,
      this.stretchTriggerOffset,
      @required this.imagePath,
      @required this.onStretchTrigger});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: this.expandedHeight,
      stretch: true,
      stretchTriggerOffset: this.stretchTriggerOffset,
      onStretchTrigger: () => this.onStretchTrigger,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: ScrollRefreshIcon(
          expandedBarHeight: this.expandedHeight,
          barStretchOffset: this.stretchTriggerOffset,
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
