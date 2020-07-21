import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/basic/transculent_cupertino_body.dart';

class AboutView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TransculentCupertinoBody(
        appBarPreviousTitle: 'Settings',
        appBarTitle: 'About',
        listViewChildren: [
          Text('WTF'),
        ],
      ),
    );
  }
}
