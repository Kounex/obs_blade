import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base_card.dart';
import 'package:obs_blade/views/settings/about/widgets/social_block/social_block.dart';
import 'package:obs_blade/views/settings/widgets/action_block.dart/light_divider.dart';

import '../../../shared/general/themed/themed_cupertino_scaffold.dart';
import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../../utils/modal_handler.dart';
import 'widgets/about_header/about_header.dart';
import 'widgets/license_modal/license_modal.dart';

class AboutView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ThemedCupertinoScaffold(
      body: Builder(
        builder: (context) => TransculentCupertinoNavBarWrapper(
          previousTitle: 'Settings',
          title: 'About',
          listViewChildren: [
            Padding(
              padding: EdgeInsets.only(top: 12.0),
              child: Column(
                children: [
                  AboutHeader(),
                  // LightDivider(
                  //   height: 32.0,
                  // ),
                  BaseCard(
                    child: SocialBlock(),
                  ),
                  // LightDivider(
                  //   height: 32.0,
                  // ),
                  RaisedButton(
                    child: Text('Packages'),
                    onPressed: () => ModalHandler.showBaseCupertinoBottomSheet(
                      context: context,
                      modalWidgetBuilder: (context, scrollController) =>
                          LicenseModal(
                        scrollController: scrollController,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
