import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart' as mob_x;
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';

import '../../models/enums/log_level.dart';
import '../../shared/dialogs/info.dart';
import '../../shared/general/custom_sliver_list.dart';
import '../../shared/general/themed/cupertino_scaffold.dart';
import '../../shared/overlay/base_progress_indicator.dart';
import '../../shared/overlay/base_result.dart';
import '../../stores/shared/network.dart';
import '../../stores/views/home.dart';
import '../../utils/general_helper.dart';
import '../../utils/modal_handler.dart';
import '../../utils/overlay_handler.dart';
import '../../utils/routing_helper.dart';
import '../../utils/styling_helper.dart';
import 'widgets/connect_box/connect_box.dart';
import 'widgets/refresher_app_bar/refresher_app_bar.dart';
import 'widgets/saved_connections/saved_connections.dart';

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
  });

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  /// Since I'm using (at least one) reaction in this State, I need to dispose
  /// it when this Widget / State is disposing itself as well. I add each reaction call
  /// to this list and dispose every instance in the dispose call of this Widget
  final List<mob_x.ReactionDisposer> _disposers = [];

  /// Using [didChangeDependencies] since it is called after [initState] and has access
  /// to a [BuildContext] of this [StatelessWidget] which we need to access the MobX
  /// stores through Provider; GetIt.instance<NetworkStore>() for example
  ///
  /// NEW: Not making use of [didChangeDependencies] since it gets triggered quite often.
  /// Initially I wanted to use this since I thought I would have access to a context
  /// where the provided ViewModel for this View is accessible, but since the context
  /// passed to our build method is the one from the parent, we won't have access to the
  /// provided ViewModel on this way at all - thats why i used the Facade Pattern and
  /// used a Wrapper Widget which has the only pupose to expose the ViewModel via Provider
  /// and making it accessible with the given context here (NEW: this has also been changed
  /// since I switched to GetIt which registers the stores globally (without context) and we
  /// don't need to initialize them in a facade pattern manner and do it in main but now need
  /// to reset those stores). The reactions I registered here should only be registered once
  /// (making use of reaction and when) so thats why its now in [initState]
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

    Future.delayed(
      const Duration(milliseconds: 0),
      () => GetIt.instance<HomeStore>().updateAutodiscoverConnections(),
    );

    /// I have to import the MobX part above with 'as MobX' since the Widget Listener
    /// is part of Material and MobX therefore it can't be resolved on its own. By
    /// naming one import I have to exlicitly use the import name as an prefix to
    /// define which one i mean
    ///
    /// This case here: 'Listener' Widget is part of Material and MobX; I'm using Listener
    /// in my Widget tree; I named the MobX import so now if I mean the MobX 'Listener' I would
    /// have to write 'MobX.Listener', otherwise it's the Material one. Since I'm using Material
    /// stuff here most of the time i named the MobX import instead ob the Material one
    mob_x.when((_) => GetIt.instance<NetworkStore>().obsTerminated, () {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        GeneralHelper.advLog(
          'Your connection to OBS has been lost and the app was not able to reconnect.',
          level: LogLevel.Warning,
          includeInLogs: true,
        );
        if (this.mounted) {
          ModalHandler.showBaseDialog(
            context: context,
            barrierDismissible: true,
            dialogWidget: const InfoDialog(
                body:
                    'Your connection to OBS has been lost and the app was not able to reconnect.'),
          ).then(
            (_) => GetIt.instance<HomeStore>().updateAutodiscoverConnections(),
          );
        }
      });
    });

    /// Once we recognize a connection attempt inside our reaction ([connectionInProgress] is true)
    /// we will check whether the connection was successfull or not and display overlays and / or
    /// route to the [DashboardView]
    _disposers.add(mob_x
        .reaction((_) => GetIt.instance<NetworkStore>().connectionInProgress,
            (bool connectionInProgress) {
      NetworkStore networkStore = GetIt.instance<NetworkStore>();

      if (connectionInProgress) {
        OverlayHandler.showStatusOverlay(
          context: context,
          showDuration: const Duration(seconds: 5),
          content: BaseProgressIndicator(
            text: 'Connecting...',
          ),
        );
      } else if (!connectionInProgress) {
        if ((networkStore.connectionClodeCode ??
                WebSocketCloseCode.UnknownReason) ==
            WebSocketCloseCode.DontClose) {
          OverlayHandler.closeAnyOverlay(immediately: true);
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
        else if ([
          WebSocketCloseCode.DontClose,
          WebSocketCloseCode.AuthenticationFailed
        ].every((closeCode) => closeCode != networkStore.connectionClodeCode)) {
          OverlayHandler.showStatusOverlay(
            context: context,
            replaceIfActive: true,
            content: const Align(
              alignment: Alignment.center,
              child: BaseResult(
                icon: BaseResultIcon.Negative,
                text: 'Couldn\'t connect to a WebSocket.',
              ),
            ),
          );
        } else {
          OverlayHandler.closeAnyOverlay(immediately: true);
        }
      }
    }));
  }

  @override
  void dispose() {
    super.dispose();

    /// disposing each [ReactionDisposer] of our MobX reactions
    for (var d in _disposers) {
      d();
    }
  }

  @override
  Widget build(BuildContext context) {
    HomeStore homeStore = GetIt.instance<HomeStore>();
    return ThemedCupertinoScaffold(
      /// refreshable is being maintained in our RefresherAppBar - as soon as we reach
      /// our extendedHeight, where we are ready to trigger searching for OBS connections,
      /// it is being set to true, false otherwise. I want to trigger the actual refresh only
      /// if, once the extendedHeight is reached, the user lets go off the screen and could just
      /// scroll up again without triggering a refresh (feels more natural in my opinion)
      body: Listener(
        onPointerUp: (_) {
          if (homeStore.refreshable) {
            /// Used to globally (at least where [HomeStore] is listened to) to act on the
            /// refresh action which has now been triggered
            homeStore.initiateRefresh();

            /// Switch back to autodiscover mode (of our [SwitcherCard]) if we refresh so the
            /// user can actually see the part thats refreshing
            if (homeStore.connectMode != ConnectMode.Autodiscover) {
              homeStore.setConnectMode(ConnectMode.Autodiscover);
            }
            homeStore.updateAutodiscoverConnections();
          }
        },
        child: CustomScrollView(
          physics: StylingHelper.platformAwareScrollPhysics,
          controller:
              ModalRoute.of(context)!.settings.arguments as ScrollController,

          /// Scrolling has a unique behaviour on iOS and macOS where we bounce as soon as
          /// we reach the end. Since we are using the stretch of [RefresherAppBar], which uses
          /// [SliverAppBar] internally, to refresh (looking for OBS connections) we need to
          /// be able to scroll even though we reached the end. To achieve this we need different behaviour
          /// for iOS (macOS) and Android (and possibly the rest) where we use [AlwaysScrollableScrollPhysics]
          /// for the first group and [BouncingScrollPhysics] for the second
          // physics: StylingHelper.platformAwareScrollPhysics,
          slivers: const [
            RefresherAppBar(
              expandedHeight: 200.0,
            ),
            CustomSliverList(
              children: [
                ConnectBox(),
                SavedConnections(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
