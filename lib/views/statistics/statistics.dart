import 'package:flutter/material.dart';

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
          StreamDataPanels(),
        ],
      ),
    );
  }
}
