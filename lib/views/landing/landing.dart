import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_station/views/landing/widgets/scroll_refresh_icon.dart';

const double kExpandedBarHeight = 200.0;
const double kStretchTriggerOffset = 75.0;

class LandingView extends StatelessWidget {
  double _getRefreshOpacity(double currAppBarHeight) {
    double opacity =
        (currAppBarHeight - (kExpandedBarHeight + kStretchTriggerOffset)) /
            kStretchTriggerOffset *
            1.5;
    return opacity > 1.0 ? 1.0 : opacity < 0.0 ? 0.0 : opacity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: kExpandedBarHeight,
            stretch: true,
            stretchTriggerOffset: kStretchTriggerOffset,
            onStretchTrigger: () => Future.delayed(
              Duration(milliseconds: 0),
              () => print('LOL'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: ScrollRefreshIcon(
                expandedBarHeight: kExpandedBarHeight,
                barStretchOffset: kStretchTriggerOffset,
              ),
              background: Padding(
                  padding: EdgeInsets.only(top: 32.0),
                  child: Image.asset('assets/images/base-logo.png')),
              collapseMode: CollapseMode.parallax,
              stretchModes: [
                StretchMode.blurBackground,
                StretchMode.zoomBackground
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Container(
                  padding: EdgeInsets.only(top: 50),
                  child: Icon(Icons.home),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
