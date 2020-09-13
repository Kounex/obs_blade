import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../widgets/action_block.dart/light_divider.dart';
import '../license_modal/license_entries.dart';

class LicenseModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // return LicensePage();
    return Column(
      children: [
        Align(
          child: Container(
            padding: EdgeInsets.only(bottom: 12.0),
            width: 300.0,
            child: Image.asset('assets/images/base-logo.png'),
          ),
        ),
        LightDivider(),
        Padding(
          padding: EdgeInsets.only(top: 12.0, bottom: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.only(right: 8.0),
                height: 32.0,
                child: Image.asset('assets/images/flutter-logo-render.png'),
              ),
              Text('Powered by Flutter'),
            ],
          ),
        ),
        LightDivider(),
        Expanded(
          child: LicenseEntries(),
        ),
      ],
    );
  }
}
