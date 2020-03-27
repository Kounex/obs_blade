import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobx_provider/mobx_provider.dart';
import 'package:obs_station/models/landing.dart';
import 'package:obs_station/utils/network_helper.dart';
import 'package:obs_station/views/landing/widgets/auto_discovery.dart';
import 'package:obs_station/views/landing/widgets/connect_form.dart';
import 'package:obs_station/views/landing/widgets/refresher_app_bar.dart';

class LandingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //NetworkHelper.getOBSWebsocketStream();
    return MobxStatefulProvider<LandingStore>(
        initFunction: (landingStore) =>
            landingStore.updateObsNetworkAddresses(),
        builder: (context, landingStore) {
          return Scaffold(
            body: Listener(
              onPointerUp: (_) {
                if (landingStore.refreshable) {
                  print('LOOOOOL');
                  landingStore.updateObsNetworkAddresses();
                }
              },
              child: CustomScrollView(
                slivers: <Widget>[
                  RefresherAppBar(
                    expandedHeight: 200.0,
                    stretchTriggerOffset: 125.0,
                    imagePath: 'assets/images/base-logo.png',
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: AutoDiscovery(),
                        ),
                        Container(
                          padding: EdgeInsets.all(24.0),
                          child: ConnectForm(),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
