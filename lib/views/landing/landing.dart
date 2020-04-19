import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_mobx_helpers/flutter_mobx_helpers.dart';
import 'package:obs_station/shared/animator/fader.dart';
import 'package:obs_station/shared/basic/base_card.dart';
import 'package:obs_station/stores/views/landing.dart';
import 'package:obs_station/stores/shared/network.dart';
import 'package:obs_station/utils/overlay_handler.dart';
import 'package:obs_station/views/landing/widgets/auto_discovery/auto_discovery.dart';
import 'package:obs_station/views/landing/widgets/connect_form/connect_form.dart';
import 'package:obs_station/views/landing/widgets/refresher_app_bar/refresher_app_bar.dart';
import 'package:obs_station/views/landing/widgets/switcher_card/switcher_card.dart';
import 'package:provider/provider.dart';

class LandingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ObserverListener(
      listener: (_) {
        if (Provider.of<NetworkStore>(context, listen: false)
            .connectionInProgress) {
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
        } else if (Provider.of<NetworkStore>(context, listen: false)
                .connectionWasInProgress &&
            !Provider.of<NetworkStore>(context, listen: false)
                .connectionInProgress) {
          OverlayHandler.showStatusOverlay(
            context: context,
            replaceIfActive: true,
            content: Align(
              alignment: Alignment.center,
              child: Text(
                Provider.of<NetworkStore>(context, listen: false).connected
                    ? 'WebSocket connection established!'
                    : 'Couldn\'t connect to a WebSocket!',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
      },
      child: Scaffold(
        body: Listener(
          onPointerUp: (_) {
            if (Provider.of<LandingStore>(context, listen: false).refreshable) {
              Provider.of<NetworkStore>(context, listen: false)
                  .updateAutodiscoverConnections();
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
                    Observer(
                      builder: (context) => Stack(
                        children: <Widget>[
                          SwitcherCard(
                            title: Provider.of<LandingStore>(context,
                                        listen: false)
                                    .manualMode
                                ? 'Connection'
                                : 'Autodiscover',
                            child: Provider.of<LandingStore>(context,
                                        listen: false)
                                    .manualMode
                                ? Padding(
                                    padding: const EdgeInsets.only(
                                        left: 24.0, right: 24.0, bottom: 12.0),
                                    child: ConnectForm(),
                                  )
                                : AutoDiscovery(),
                          ),
                          Positioned(
                            right: 36.0,
                            top: 30.0,
                            child: CupertinoButton(
                              child: Text(Provider.of<LandingStore>(context,
                                          listen: false)
                                      .manualMode
                                  ? 'Auto'
                                  : 'Manual'),
                              onPressed: () => Provider.of<LandingStore>(
                                      context,
                                      listen: false)
                                  .toggleManualMode(),
                            ),
                          )
                        ],
                      ),
                    ),
                    Observer(builder: (context) {
                      NetworkStore networkStore =
                          Provider.of<NetworkStore>(context);
                      return networkStore.connected
                          ? Fader(
                              child: BaseCard(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      networkStore.activeSession.connection.ip,
                                    ),
                                    CupertinoButton(
                                      child: Text('Close'),
                                      onPressed: () =>
                                          networkStore.closeSession(),
                                    )
                                  ],
                                ),
                              ),
                            )
                          : Container();
                    })
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
