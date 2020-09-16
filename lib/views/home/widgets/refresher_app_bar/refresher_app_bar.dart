import 'package:flutter/material.dart';

import '../../../../shared/animator/fader.dart';
import '../../../../shared/general/flutter_modified/translucent_sliver_app_bar.dart';
import 'scroll_refresh_icon.dart';

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
      expandedHeight: this.expandedHeight,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: LayoutBuilder(
          builder: (context, constraints) => Stack(
            alignment: Alignment.bottomCenter,
            children: [
              constraints.maxHeight -
                          (MediaQuery.of(context).padding.top - 20) <=
                      60
                  ? Fader(
                      child: Text(
                        'OBS Blade',
                        style: Theme.of(context)
                            .textTheme
                            .button
                            .copyWith(fontSize: 18.0),
                      ),
                    )
                  : Container(),
              ScrollRefreshIcon(
                expandedBarHeight: this.expandedHeight,
              )
            ],
          ),
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
