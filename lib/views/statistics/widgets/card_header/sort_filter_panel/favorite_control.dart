import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../stores/views/statistics.dart';

class FavoriteControl extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = GetIt.instance<StatisticsStore>();

    return Observer(
      builder: (_) => SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl(
          groupValue: statisticsStore.showOnlyFavorites == null
              ? 'null'
              : statisticsStore.showOnlyFavorites,
          padding: EdgeInsets.all(0),
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
              .setShowOnlyFavorites(value == 'null' ? null : value as bool),
        ),
      ),
    );
  }
}
