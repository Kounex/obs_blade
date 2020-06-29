import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        previousPageTitle: 'Settings',
        middle: Text('Privacy Policy'),
      ),
      body: CustomScrollView(
        slivers: [],
      ),
    );
  }
}
