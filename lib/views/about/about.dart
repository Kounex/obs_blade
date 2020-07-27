import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:obs_blade/shared/general/transculent_cupertino_body.dart';
import 'package:obs_blade/views/about/widgets/license_modal.dart';

class AboutView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TransculentCupertinoBody(
        appBarPreviousTitle: 'Settings',
        appBarTitle: 'About',
        listViewChildren: [
          Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: RaisedButton(
              child: Text('Packages'),
              onPressed: () {
                showCupertinoModalBottomSheet(
                  expand: true,
                  context: context,
                  backgroundColor: Colors.transparent,
                  useRootNavigator: true,
                  builder: (context, scrollController) => LicenseModal(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
