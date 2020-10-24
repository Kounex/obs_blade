import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:obs_blade/stores/views/statistics.dart';
import 'package:provider/provider.dart';

class FavoriteControl extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = context.watch<StatisticsStore>();

    return Observer(
      builder: (_) => SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl(
          groupValue: statisticsStore.showOnlyFavorites == null
              ? 'null'
              : statisticsStore.showOnlyFavorites,
          padding: EdgeInsets.all(0),
          // selectedColor: Theme.of(context).toggleableActiveColor,
          // borderColor: Theme.of(context).toggleableActiveColor,
          // unselectedColor: Theme.of(context).cardColor,
          children: {
            false: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star,
                ),
                Icon(
                  Icons.star_border,
                ),
              ],
            ),
            true: Icon(
              Icons.star,
            ),
            'null': Icon(
              Icons.star_border,
            ),
          },
          onValueChanged: (value) => statisticsStore
              .setShowOnlyFavorites(value == 'null' ? null : value),
        ),
      ),
    );
  }
}
