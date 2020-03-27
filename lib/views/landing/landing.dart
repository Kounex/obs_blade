import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_station/utils/network_helper.dart';
import 'package:obs_station/views/landing/widgets/auto_discovery.dart';
import 'package:obs_station/views/landing/widgets/connect_form.dart';
import 'package:obs_station/views/landing/widgets/refresher_app_bar.dart';

class LandingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    NetworkHelper.getOBSWebsocketStream();
    return Scaffold(
      body: Listener(
        onPointerUp: (_) => print('lol'),
        child: CustomScrollView(
          slivers: <Widget>[
            RefresherAppBar(
              expandedHeight: 200.0,
              stretchTriggerOffset: 75.0,
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
  }
}
