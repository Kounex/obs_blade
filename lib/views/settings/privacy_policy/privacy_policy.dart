import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../shared/general/base_card.dart';
import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';

class PrivacyPolicyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        previousTitle: 'Settings',
        title: 'Privacy Policy',
        listViewChildren: [
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Column(
              children: [
                Icon(
                  CupertinoIcons.airplane,
                  size: 92.0,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Privacy Policy',
                    style: Theme.of(context).textTheme.headline5,
                  ),
                ),
              ],
            ),
          ),
          BaseCard(
            paddingChild: const EdgeInsets.all(12.0),
            child: Text('Wow, just wow'),
          ),
        ],
      ),
    );
  }
}
