import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/views/dashboard/widgets/dialogs/save_edit_connection.dart';
import 'package:provider/provider.dart';

import '../../models/connection.dart';
import '../../shared/dialogs/confirmation.dart';
import '../../shared/dialogs/input.dart';
import '../../stores/shared/network.dart';
import '../../stores/views/dashboard.dart';
import '../../types/enums/hive_keys.dart';
import '../../utils/routing_helper.dart';
import 'widgets/scenes/scenes.dart';
import 'widgets/status_app_bar/status_app_bar.dart';
import 'widgets/stream_widgets/stream_widgets.dart';

/// InheritedWidget [DashBoardScroll] is used to expose the ScrollController
/// which is being used for the main ListView in Dashboard to the descendant
/// Widgets - could be put inside the DashboardStore but I want to avoid
/// putting Flutter specific classes inside my stores
class DashboardScroll extends InheritedWidget {
  final ScrollController scrollController = ScrollController();

  DashboardScroll({@required Widget child}) : super(child: child);

  static DashboardScroll of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DashboardScroll>();

  @override
  bool updateShouldNotify(DashboardScroll oldWidget) =>
      oldWidget.scrollController != this.scrollController;
}

class DashboardView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider<DashboardStore>(
        create: (_) {
          DashboardStore dashboardStore = DashboardStore();

          // Setting the active session and make initial requests
          // to display data on connect
          dashboardStore
              .setupNetworkStoreHandling(context.read<NetworkStore>());
          return dashboardStore;
        },
        builder: (context, _) => _DashboardView());
  }
}

class _DashboardView extends StatefulWidget {
  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    when(
        (_) =>
            context.read<NetworkStore>().activeSession.connection.name == null,
        () => SchedulerBinding.instance
            .addPostFrameCallback((_) => _saveConnectionDialog(context)));

    when(
        (_) => context.read<NetworkStore>().obsTerminated,
        () => Navigator.of(context)
            .pushReplacementNamed(HomeTabRoutingKeys.Landing.route));
  }

  _saveConnectionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfirmationDialog(
        title: 'Save Connection',
        body:
            'Do you want to save this connection? You can do it later as well!\n\n(Click on the icon on the top right of the screen and select "Save / Edit Connection"',
        onOk: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => SaveEditConnectionDialog(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DashboardScroll(
        child: Builder(
          builder: (context) => CustomScrollView(
            physics: ClampingScrollPhysics(),
            controller: DashboardScroll.of(context).scrollController,
            slivers: [
              StatusAppBar(),
              SliverPadding(
                padding: EdgeInsets.only(bottom: 50.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Align(
                        child: SizedBox(
                          // width: MediaQuery.of(context).size.width / 100 * 85,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 12.0, bottom: 24.0),
                                child: Scenes(),
                              ),
                              StreamWidgets(),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
