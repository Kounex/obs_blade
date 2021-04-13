import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mobx/mobx.dart' as MobX;
import 'package:provider/provider.dart';

import '../../shared/dialogs/info.dart';
import '../../shared/general/custom_sliver_list.dart';
import '../../shared/overlay/base_progress_indicator.dart';
import '../../shared/overlay/base_result.dart';
import '../../stores/shared/network.dart';
import '../../stores/views/home.dart';
import '../../types/classes/stream/responses/base.dart';
import '../../utils/modal_handler.dart';
import '../../utils/overlay_handler.dart';
import '../../utils/routing_helper.dart';
import '../../utils/styling_helper.dart';
import 'widgets/connect_box/connect_box.dart';
import 'widgets/refresher_app_bar/refresher_app_bar.dart';
import 'widgets/saved_connections/saved_connections.dart';

/// Using the "Facade Pattern" here, where I wrap my actual ViewWidget with a WrapperWidget
/// which only purpose is to expose the ViewModel via Provider. Since the context available in
/// our build / state is effectively the context of our parent, without the WrapperWidget I would
/// not have access to the provided ViewModel directly.
/// I can counter this by using the builder property of Provider to solve this problem in the build
/// method, but it does not work in my structure where I also register MobX reactions in
/// [initState] where i (might) access the ViewModel which is part of this View and is
/// provided just here. With the WrapperWidget in this Facade Pattern the parent has just provided
/// the ViewModel and I can access it in my reactions!
/// It does not use a special name, instead the actual View got private (_) since it is nothing which
/// has to be exposed (logically)
class HomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider<HomeStore>(
      create: (_) {
        HomeStore landingStore = HomeStore();

        // if (!context.read<NetworkStore>().obsTerminated) {
        //   context.read<NetworkStore>().obsTerminated = false;

        /// Trigger autodiscover on startup
        /// Delay autodiscover to let the view render and ask for permission etc.
        Future.delayed(
          Duration(milliseconds: 1000),
          () => landingStore.updateAutodiscoverConnections(),
        );
        // }
        return landingStore;
      },
      builder: (context, _) => _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  /// Since I'm using (at least one) reaction in this State, I need to dispose
  /// it when this Widget / State is disposing itself as well. I add each reaction call
  /// to this list and dispose every instance in the dispose call of this Widget
  List<MobX.ReactionDisposer> _disposers = [];

  /// Using [didChangeDependencies] since it is called after [initState] and has access
  /// to a [BuildContext] of this [StatelessWidget] which we need to access the MobX
  /// stores through Provider; context.read<NetworkStore>() for example
  ///
  /// NEW: Not making use of [didChangeDependencies] since it gets triggered quite often.
  /// Initially I wanted to use this since I thought I would have access to a context
  /// where the provided ViewModel for this View is accessible, but since the context
  /// passed to our build method is the one from the parent, we won't have access to the
  /// provided ViewModel on this way at all - thats why i used the Facade Pattern and
  /// used a Wrapper Widget which has the only pupose to expose the ViewModel via Provider
  /// and making it accessible with the given context here. The reactions I registered
  /// here should only be registered once (making use of reaction and when) so thats why
  /// its now in [initState]
  ///
  /// Since I'm checking here if the [obsTerminated] value is true (meaning we came to this
  /// view because OBS has terminated) I want to disaplay dialog informing the user about it.
  /// [initState] will get called relatively fast, in this case during the
  /// [pushReplacementNamed] call. Since showing a dialog is also using [Navigator] stuff (it
  /// will push the dialog into the stack) we will get an exepction indicating that problem.
  /// To avoid that I added [SchedulerBinding.instance.addPostFrameCallback] which ensures that
  /// our dialog is pushed when the current build/render cycle is done, thats where our
  /// [pushReplacementNamed] is done and it is safe to use [Navigator] again
  @override
  void initState() {
    super.initState();

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
      SchedulerBinding.instance!.addPostFrameCallback((_) =>
          ModalHandler.showBaseDialog(
            context: context,
            dialogWidget: InfoDialog(
                body:
                    'Your connection to OBS has been lost and the app was not able to reconnect!'),
          ).then((_) =>
              context.read<HomeStore>().updateAutodiscoverConnections()));
    });

    /// Once we recognize a connection attempt inside our reaction ([connectionInProgress] is true)
    /// we will check whether the connection was successfull or not and display overlays and / or
    /// route to the [DashboardView]
    _disposers.add(
        MobX.reaction((_) => context.read<NetworkStore>().connectionInProgress,
            (bool connectionInProgress) {
      NetworkStore networkStore = context.read<NetworkStore>();

      if (connectionInProgress) {
        OverlayHandler.showStatusOverlay(
            context: context,
            showDuration: Duration(seconds: 5),
            content: BaseProgressIndicator(
              text: 'Connecting...',
            ));
      } else if (!connectionInProgress) {
        if (networkStore.connectionResponse!.status == BaseResponse.ok) {
          OverlayHandler.closeAnyOverlay();
          Navigator.pushReplacementNamed(
            context,
            HomeTabRoutingKeys.Dashboard.route,
            arguments: ModalRoute.of(context)!.settings.arguments,
          );
        }

        /// If the error for the connection attempt results in an 'Authentication' error,
        /// it is due to providing a wrong password (or none at all) and we don't want to
        /// display an overlay for that - we trigger the validation of the password field
        /// in our [ConnectForm]
        else if (!networkStore.connectionResponse!.error!
            .contains(BaseResponse.failedAuthentication)) {
          OverlayHandler.showStatusOverlay(
            context: context,
            replaceIfActive: true,
            content: Align(
              alignment: Alignment.center,
              child: BaseResult(
                icon: BaseResultIcon.Negative,
                text: 'Couldn\'t connect to a WebSocket!',
              ),
            ),
          );
        } else {
          OverlayHandler.closeAnyOverlay();
        }
      }
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
    HomeStore landingStore = context.watch<HomeStore>();
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
          controller:
              ModalRoute.of(context)!.settings.arguments as ScrollController,

          /// Scrolling has a unique behaviour on iOS and macOS where we bounce as soon as
          /// we reach the end. Since we are using the stretch of [RefresherAppBar], which uses
          /// [SliverAppBar] internally, to refresh (looking for OBS connections) we need to
          /// be able to scroll even though we reached the end. To achieve this we need different behaviour
          /// for iOS (macOS) and Android (and possibly the rest) where we use [AlwaysScrollableScrollPhysics]
          /// for the first group and [BouncingScrollPhysics] for the second
          physics: StylingHelper.platformAwareScrollPhysics,
          slivers: <Widget>[
            RefresherAppBar(
              expandedHeight: 200.0,
              imagePath: 'assets/images/base_logo.png',
            ),
            CustomSliverList(
              children: [
                Align(
                  child: ConnectBox(),
                ),
                SavedConnections(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
