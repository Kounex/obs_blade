import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../shared/design/design.dart';
import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../../stores/views/logs.dart';
import 'widgets/log_explanation.dart';
import 'widgets/log_filter.dart';
import 'widgets/log_grid/log_list.dart';

class LogsView extends StatefulWidget {
  const LogsView({super.key});

  @override
  State<LogsView> createState() => _LogsViewState();
}

class _LogsViewState extends State<LogsView> {
  @override
  void initState() {
    super.initState();

    /// Filter state starts fresh when the route is created. This used to
    /// reset in [build], which wiped it on every rebuild.
    GetIt.instance.resetLazySingleton<LogsStore>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        previousTitle: 'Settings',
        title: 'Logs',
        showScrollBar: true,
        listViewChildren: const [
          StaggeredEntrance(
            scaleFrom: 0.985,
            index: 0,
            child: LogExplanation(),
          ),
          StaggeredEntrance(scaleFrom: 0.985, index: 1, child: LogFilter()),
          StaggeredEntrance(scaleFrom: 0.985, index: 2, child: LogList()),
        ],
      ),
    );
  }
}
