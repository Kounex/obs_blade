import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../stores/views/statistics.dart';

class FavoriteControl extends StatelessWidget {
  const FavoriteControl({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = GetIt.instance<StatisticsStore>();

    return Observer(
      builder: (_) => SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl(
          groupValue: statisticsStore.showOnlyFavorites ?? 'null',
          padding: const EdgeInsets.all(0),
          children: {
            false: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.star,
                ),
                Icon(
                  Icons.star_border,
                ),
              ],
            ),
            true: const Icon(
              Icons.star,
            ),
            'null': const Icon(
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
