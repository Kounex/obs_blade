import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';

import '../../models/connection.dart';
import '../../shared/basic/flutter_modified/translucent_sliver_app_bar.dart';
import '../../shared/basic/status_dot.dart';
import '../../shared/dialogs/confirmation.dart';
import '../../shared/dialogs/input.dart';
import '../../stores/shared/network.dart';
import '../../stores/views/dashboard.dart';
import '../../types/enums/hive_keys.dart';
import '../../utils/routing_helper.dart';
import 'widgets/scenes/scenes.dart';
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
  List<String> _appBarActions = ['Manage Stream', 'Stats'];

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
    NetworkStore networkStore = context.read<NetworkStore>();

    Box<Connection> box = Hive.box<Connection>(HiveKeys.SavedConnections.name);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfirmationDialog(
        title: 'Save Connection',
        body:
            'Do you want to save this connection? You can do it later as well.',
        onOk: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => InputDialog(
              title: 'Save Connection',
              body:
                  'Please choose a name for the connection so you can recognize it later on',
              inputCheck: (name) {
                if (name == null || name.length == 0) {
                  return 'Please provide a name!';
                }
                if (box.values.any((connection) => connection.name == name)) {
                  return 'Name already used!';
                }
                return '';
              },
              onSave: (name) {
                // if the challenge (or salt) is null, we didn't have to connect with a password.
                // a user might still enter a password, we don't want this password to be
                // saved, thats why we set it to null explicitly if thats the case
                if (networkStore.activeSession.connection.challenge == null) {
                  networkStore.activeSession.connection.pw = null;
                }
                networkStore.activeSession.connection.name = name;
                box.add(networkStore.activeSession.connection);
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    NetworkStore networkStore = context.watch<NetworkStore>();

    return Scaffold(
      body: DashboardScroll(
        child: Builder(
          builder: (context) => CustomScrollView(
            physics: ClampingScrollPhysics(),
            controller: DashboardScroll.of(context).scrollController,
            slivers: [
              TransculentSliverAppBar(
                pinned: true,
                title: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CupertinoButton(
                          child: Text('Close'),
                          onPressed: () => showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => ConfirmationDialog(
                              title: 'Close Connection',
                              body:
                                  'Are you sure you want to close the current WebSocket connection?',
                              isYesDestructive: true,
                              onOk: () {
                                networkStore.closeSession();
                                Navigator.of(context).pushReplacementNamed(
                                    HomeTabRoutingKeys.Landing.route);
                              },
                            ),
                          ),
                        ),
                        Container(
                          width: 150.0,
                          alignment: Alignment.bottomRight,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _appBarActions[0],
                              icon: Container(),
                              isExpanded: true,
                              selectedItemBuilder: (_) => [
                                Container(
                                  alignment: Alignment.centerRight,
                                  child: Icon(
                                    CupertinoIcons.ellipsis,
                                    size: 32.0,
                                  ),
                                )
                              ],
                              items: _appBarActions
                                  .map(
                                    (action) => DropdownMenuItem<String>(
                                      child: SizedBox(
                                        width: 150.0,
                                        child: Text(
                                          action,
                                        ),
                                      ),
                                      value: action,
                                    ),
                                  )
                                  .toList(),
                              onChanged: (selection) => print(selection),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Text('Dashboard'),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                          child: Observer(builder: (_) {
                            return StatusDot(
                              size: 8.0,
                              color: context.read<DashboardStore>().isLive
                                  ? Colors.green
                                  : Colors.red,
                              text: context.read<DashboardStore>().isLive
                                  ? 'Live'
                                  : 'Not Live',
                              style: Theme.of(context).textTheme.caption,
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
