import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/shared/general/themed/cupertino_scaffold.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/obs_widgets.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/obs_widgets_mobile.dart';
import 'package:wakelock/wakelock.dart';

import '../../shared/dialogs/confirmation.dart';
import '../../shared/general/base/divider.dart';
import '../../shared/general/custom_sliver_list.dart';
import '../../shared/general/responsive_widget_wrapper.dart';
import '../../stores/shared/network.dart';
import '../../stores/views/dashboard.dart';
import '../../types/enums/hive_keys.dart';
import '../../types/enums/settings_keys.dart';
import '../../utils/modal_handler.dart';
import '../../utils/routing_helper.dart';
import 'widgets/reconnect_toast.dart';
import 'widgets/save_edit_connection_dialog.dart';
import 'widgets/scenes/scenes.dart';
import 'widgets/status_app_bar/status_app_bar.dart';

/// InheritedWidget [DashBoardScroll] is used to expose the ScrollController
/// which is being used for the main ListView in Dashboard to the descendant
/// Widgets - could be put inside the DashboardStore but I want to avoid
/// putting Flutter specific classes inside my stores
@Deprecated(
    'Don\'t necessary anymore since we expose a [ScrollController] from the Navigators used for the tabs since we want to scroll or route back if a user taps on the tab - therefore we can access the [ScrollController] from the [ModalRoute] settings argument')
class DashboardScroll extends InheritedWidget {
  final ScrollController scrollController = ScrollController();

  DashboardScroll({Key? key, required Widget child})
      : super(key: key, child: child);

  static DashboardScroll of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DashboardScroll>()!;

  @override
  bool updateShouldNotify(DashboardScroll oldWidget) =>
      oldWidget.scrollController != this.scrollController;
}

class DashboardView extends StatefulWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();

    /// Since GetIt exposes stores in a global manner and I want a view
    /// store to be clean once a view is entered / inititalized, we need to
    /// reset them on every view (just in initState)
    GetIt.instance.resetLazySingleton<DashboardStore>();

    /// Initiate the [DashboardStore] object by initiating socket listeners
    /// and first calls etc.
    GetIt.instance<DashboardStore>().init();

    if (Hive.box(HiveKeys.Settings.name)
        .get(SettingsKeys.WakeLock.name, defaultValue: true)) {
      Wakelock.enable();
    }

    when(
      (_) =>
          GetIt.instance<NetworkStore>().activeSession!.connection.name == null,
      () => SchedulerBinding.instance.addPostFrameCallback(
        (_) => _saveConnectionDialog(context),
      ),
    );

    when(
      (_) => GetIt.instance<NetworkStore>().obsTerminated,
      () => SchedulerBinding.instance.addPostFrameCallback(
        (_) => Navigator.of(context).pushReplacementNamed(
            HomeTabRoutingKeys.Landing.route,
            arguments: ModalRoute.of(context)!.settings.arguments),
      ),
    );
  }

  @override
  void dispose() {
    /// Disable [Wakelock] - does not need to check whether this is active
    /// since calling disable is idempotent
    Wakelock.disable();
    super.dispose();
  }

  _saveConnectionDialog(BuildContext context) {
    ModalHandler.showBaseDialog(
      context: context,
      dialogWidget: ConfirmationDialog(
        title: 'Save Connection',
        body:
            'Do you want to save this connection? You can do it later as well!\n\n(Click on the icon on the top right of the screen and select "Save / Edit Connection"',
        onOk: (_) {
          Future.delayed(
            ModalHandler.transitionDelayDuration,
            () => ModalHandler.showBaseDialog(
              context: context,
              dialogWidget: const SaveEditConnectionDialog(),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ThemedCupertinoScaffold(
      body: Observer(builder: (_) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            CustomScrollView(
              physics: GetIt.instance<DashboardStore>().isPointerOnChat
                  ? const NeverScrollableScrollPhysics()
                  : const ClampingScrollPhysics(),
              controller: ModalRoute.of(context)!.settings.arguments
                  as ScrollController,
              slivers: [
                const StatusAppBar(),
                CustomSliverList(
                  children: [
                    Align(
                      child: SizedBox(
                        // width: MediaQuery.of(context).size.width / 100 * 85,
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(bottom: 24.0),
                              child: Scenes(),
                            ),
                            Container(
                              padding: const EdgeInsets.only(left: 8.0),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Widgets',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                            ),
                            ResponsiveWidgetWrapper(
                              mobileWidget: Column(
                                children: const [
                                  SizedBox(height: 8.0),
                                  OBSWidgetsMobile(),
                                ],
                              ),
                              tabletWidget: Column(
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.only(top: 8.0),
                                    child: BaseDivider(),
                                  ),
                                  OBSWidgets(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // SizedBox(
                    //   height: kBottomNavigationBarHeight,
                    // ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: kToolbarHeight + MediaQuery.of(context).padding.top,
              child: const Align(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ReconnectToast(),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
