import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart' as MobX;
import 'package:provider/provider.dart';

import '../../shared/dialogs/info.dart';
import '../../stores/shared/network.dart';
import '../../stores/views/home.dart';
import '../../types/classes/stream/responses/base.dart';
import '../../utils/overlay_handler.dart';
import '../../utils/routing_helper.dart';
import 'widgets/auto_discovery/auto_discovery.dart';
import 'widgets/connect_form/connect_form.dart';
import 'widgets/refresher_app_bar/refresher_app_bar.dart';
import 'widgets/saved_connections/saved_connections.dart';
import 'widgets/switcher_card/switcher_card.dart';

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  /// Since I'm using (at least one) reaction in this State, I need to dispose
  /// it when this Widget / State is disposing itself as well. I add each reaction call
  /// to this list and dispose every instance in the dispose call of this Widget
  List<MobX.ReactionDisposer> _disposers = [];

  /// Using [didChangeDependencies] since it is called after [initState] and has access
  /// to a [BuildContext] of this [StatelessWidget] which we need to access the MobX
  /// stores through Provider; context.read<NetworkStore>() for example
  ///
  /// Since I'm checking here if the [obsTerminated] value is true (meaning we came to this
  /// view because OBS has terminated) I want to disaplay dialog informing the user about it.
  /// [didChangeDependencies] will get called relatively fast, in this case during the
  /// [pushReplacementNamed] call. Since showing a dialog is also using [Navigator] stuff (it
  /// will push the dialog into the stack) we will get an exepction indicating that problem.
  /// To avoid that I added [SchedulerBinding.instance.addPostFrameCallback] which ensures that
  /// our dialog is pushed when the current build/render cycle is done, thats where our
  /// [pushReplacementNamed] is done and it is safe to use [Navigator] again
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    /// I have to import the MobX part above with 'as MobX' since the Widget Listener
    /// is part of Material and MobX therefore it can't be resolved on its own. By
    /// naming one import I have to exlicitly use the import name as an prefix to
    /// define which one i mean
    ///
    /// This case here: 'Listener' Widget is part of Material and MobX; I'm using Listener
    /// in my Widget tree; I named the MobX import so now if I mean the MobX 'Listener' I would
    /// have to write 'MobX.Listener', otherwise it's the Material one. Since I'm using Material
    /// stuff here most of the time i named the MobX import instead ob the Material one
    MobX.when((_) => context.read<NetworkStore>().obsTerminated, () {
      context.read<NetworkStore>().obsTerminated = false;
      SchedulerBinding.instance.addPostFrameCallback((_) => showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                InfoDialog(body: 'Your OBS instance terminated!'),
          ).then((_) =>
              context.read<HomeStore>().updateAutodiscoverConnections()));
    });

    /// Once we recognize a connection attempt inside our reaction ([connectionInProgress] is true)
    /// we will check whether the connection was successfull or not and display overlays and / or
    /// route to the [DashboardView]
    _disposers.add(
        MobX.reaction((_) => context.read<NetworkStore>().connectionInProgress,
            (connectionInProgress) {
      /// For now I have to wrap this function with [addPostFrameCallback] since
      /// without doing so this function will sometimes not execute correctly (in my tests
      /// the first line was executed, no more) - need to investigate the cause. This
      /// workaround has no impact performance wise, at least as far as I know.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (connectionInProgress) {
          OverlayHandler.showStatusOverlay(
            context: context,
            showDuration: Duration(seconds: 5),
            content: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 2.0,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Text('Connecting...'),
                ),
              ],
            ),
          );
        } else if (!connectionInProgress) {
          if (context.read<NetworkStore>().connectionResponse.status ==
              BaseResponse.ok) {
            OverlayHandler.closeAnyOverlay();
            Navigator.pushReplacementNamed(
                context, HomeTabRoutingKeys.Dashboard.route);
          }

          /// If the error for the connection attempt results in an 'Authentication' error,
          /// it is due to providing a wrong password (or none at all) and we don't want to
          /// display an overlay for that - we trigger the validation of the password field
          /// in our [ConnectForm]
          else if (!context
              .read<NetworkStore>()
              .connectionResponse
              .error
              .contains('Authentication')) {
            OverlayHandler.showStatusOverlay(
              context: context,
              replaceIfActive: true,
              content: Align(
                alignment: Alignment.center,
                child: Text(
                  'Couldn\'t connect to a WebSocket!',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
        }
      });
    }));
  }

  @override
  void dispose() {
    super.dispose();

    /// disposing each [ReactionDisposer] of our MobX reactions
    _disposers.forEach((d) => d());
  }

  @override
  Widget build(BuildContext context) {
    HomeStore landingStore = Provider.of<HomeStore>(context);

    return Scaffold(
      /// refreshable is being maintained in our RefresherAppBar - as soon as we reach
      /// our extendedHeight, where we are ready to trigger searching for OBS connections,
      /// it is being set to true, false otherwise. I want to trigger the actual refresh only
      /// if, once the extendedHeight is reached, the user lets go off the screen and could just
      /// scroll up again without triggering a refresh (feels more natural in my opinion)
      body: Listener(
        onPointerUp: (_) {
          if (landingStore.refreshable) {
            /// Switch back to autodiscover mode (of our [SwitcherCard]) if we refresh so the
            /// user can actually see the part thats refreshing
            if (landingStore.manualMode) landingStore.toggleManualMode();
            landingStore.updateAutodiscoverConnections();
          }
        },
        child: CustomScrollView(
          /// Scrolling has a unique behaviour on iOS and macOS where we bounce as soon as
          /// we reach the end. Since we are using the stretch of [RefresherAppBar], which uses
          /// [SliverAppBar] internally, to refresh (looking for OBS connections) we need to
          /// be able to scroll even though we reached the end. To achieve this we need different behaviour
          /// for iOS (macOS) and Android (and possibly the rest) where we use [AlwaysScrollableScrollPhysics]
          /// for the first group and [BouncingScrollPhysics] for the second
          physics: Platform.isIOS || Platform.isMacOS
              ? AlwaysScrollableScrollPhysics()
              : BouncingScrollPhysics(),
          slivers: <Widget>[
            RefresherAppBar(
              expandedHeight: 200.0,
              imagePath: 'assets/images/base-logo.png',
            ),
            SliverPadding(
              padding: EdgeInsets.only(bottom: 50.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Observer(
                      builder: (context) => Stack(
                        children: <Widget>[
                          SwitcherCard(
                            title: landingStore.manualMode
                                ? 'Connection'
                                : 'Autodiscover',
                            child: landingStore.manualMode
                                ? Padding(
                                    padding: const EdgeInsets.only(
                                        left: 24.0, right: 24.0, bottom: 12.0),
                                    child: ConnectForm(
                                      connection:
                                          landingStore.typedInConnection,
                                      saveCredentials: true,
                                    ),
                                  )
                                : AutoDiscovery(),
                          ),
                          Positioned(
                            right: 36.0,
                            top: 30.0,
                            child: CupertinoButton(
                              child: Text(
                                  landingStore.manualMode ? 'Auto' : 'Manual'),
                              onPressed: () => landingStore.toggleManualMode(),
                            ),
                          )
                        ],
                      ),
                    ),
                    SavedConnections(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
