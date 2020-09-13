import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:obs_blade/utils/modal_handler.dart';

import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import 'widgets/license_modal/license_modal.dart';

class AboutView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoScaffold(
      body: Builder(
        builder: (context) => TransculentCupertinoNavBarWrapper(
          previousTitle: 'Settings',
          title: 'About',
          listViewChildren: [
            Padding(
              padding: EdgeInsets.only(top: 12.0),
              child: RaisedButton(
                child: Text('Packages'),
                onPressed: () {
                  ModalHandler.showBaseCupertinoBottomSheet(
                    context: context,
                    modalWidgetBuilder: (context, scrollController) =>
                        LicenseModal(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
