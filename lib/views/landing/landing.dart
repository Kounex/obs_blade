import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_station/views/landing/widgets/connect_form.dart';
import 'package:obs_station/views/landing/widgets/refresher_app_bar.dart';
import 'package:obs_station/views/landing/widgets/scroll_refresh_icon.dart';

class LandingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          RefresherAppBar(
            expandedHeight: 200.0,
            stretchTriggerOffset: 75.0,
            imagePath: 'assets/images/base-logo.png',
            onStretchTrigger: Future.delayed(
              Duration(milliseconds: 0),
              () => print('LOL'),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Container(
                  padding: EdgeInsets.all(50.0),
                  child: ConnectForm(),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
