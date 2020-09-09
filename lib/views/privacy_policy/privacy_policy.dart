import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../shared/general/transculent_cupertino_navbar_wrapper.dart';

class PrivacyPolicyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        previousTitle: 'Settings',
        title: 'About',
        listViewChildren: [
          Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: Text('Privacy Policy'),
          ),
        ],
      ),
    );
  }
}
