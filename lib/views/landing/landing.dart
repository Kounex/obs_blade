import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx_helpers/flutter_mobx_helpers.dart';
import 'package:mobx_provider/mobx_provider.dart';
import 'package:obs_station/stores/landing.dart';
import 'package:obs_station/stores/network.dart';
import 'package:obs_station/utils/overlay_handler.dart';
import 'package:obs_station/views/landing/widgets/auto_discovery/auto_discovery.dart';
import 'package:obs_station/views/landing/widgets/connect_form/connect_form.dart';
import 'package:obs_station/views/landing/widgets/refresher_app_bar/refresher_app_bar.dart';
import 'package:obs_station/views/landing/widgets/switcher_card/switcher_card.dart';

class LandingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MobxStatefulProvider<NetworkStore>(
        initFunction: (networkStore) =>
            networkStore.updateAutodiscoverConnections(),
        builder: (context, networkStore) {
          return ObserverListener(
            listener: (_) {
              if (networkStore.connectionInProgress) {
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
              } else if (networkStore.connectionWasInProgress &&
                  !networkStore.connectionInProgress) {
                OverlayHandler.showStatusOverlay(
                  context: context,
                  replaceIfActive: true,
                  content: Align(
                    alignment: Alignment.center,
                    child: Text(
                      networkStore.connected.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
            },
            child: MobxStatefulProvider<LandingStore>(
              builder: (context, landingStore) => Scaffold(
                body: Listener(
                  onPointerUp: (_) {
                    if (landingStore.refreshable) {
                      networkStore.updateAutodiscoverConnections();
                    }
                  },
                  child: CustomScrollView(
                    slivers: <Widget>[
                      RefresherAppBar(
                        expandedHeight: 200.0,
                        imagePath: 'assets/images/base-logo.png',
                      ),
                      SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: MobxWidgetProvider<LandingStore>(
                                  builder: (context, landingStore) {
                                return Stack(
                                  children: <Widget>[
                                    SwitcherCard(
                                      title: landingStore.manualMode
                                          ? 'Connection'
                                          : 'Autodiscover',
                                      child: landingStore.manualMode
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 24.0,
                                                  right: 24.0,
                                                  bottom: 12.0),
                                              child: ConnectForm(),
                                            )
                                          : AutoDiscovery(),
                                    ),
                                    Positioned(
                                      right: 12.0,
                                      top: 6.0,
                                      child: CupertinoButton(
                                        child: Text(landingStore.manualMode
                                            ? 'Auto'
                                            : 'Manual'),
                                        onPressed: () =>
                                            landingStore.toggleManualMode(),
                                      ),
                                    )
                                  ],
                                );
                              }),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }
}
