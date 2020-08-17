import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base_card.dart';
import 'package:obs_blade/views/statistics/widgets/stream_entry.dart/stream_entry.dart';

import '../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import 'widgets/stream_data_panels/stream_data_panels.dart';

class StatisticsView extends StatefulWidget {
  @override
  _StatisticsViewState createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        appBarTitle: 'Statistics',
        listViewChildren: [
          BaseCard(
            title: 'Latest Stream',
            noPaddingChild: true,
            child: StreamEntry(),
          ),
          BaseCard(
            title: 'Other Streams',
            noPaddingChild: true,
            child: Column(
              children: [
                StreamDataPanels(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
