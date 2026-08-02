import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../shared/design/design.dart';
import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../../stores/views/logs.dart';
import 'widgets/log_explanation.dart';
import 'widgets/log_filter.dart';
import 'widgets/log_grid/log_list.dart';

class LogsView extends StatelessWidget {
  const LogsView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    GetIt.instance.resetLazySingleton<LogsStore>();

    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        previousTitle: 'Settings',
        title: 'Logs',
        showScrollBar: true,
        listViewChildren: const [
          StaggeredEntrance(index: 0, child: LogExplanation()),
          StaggeredEntrance(index: 1, child: LogFilter()),
          StaggeredEntrance(index: 2, child: LogList()),
        ],
      ),
    );
  }
}
