import 'package:flutter/material.dart';

import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import 'widgets/log_explanation.dart';
import 'widgets/log_filter.dart';
import 'widgets/log_grid/log_grid.dart';

class LogsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        previousTitle: 'Settings',
        title: 'Logs',
        showScrollBar: true,
        listViewChildren: [
          LogExplanation(),
          LogFilter(),
          LogGrid(),
        ],
      ),
    );
  }
}
