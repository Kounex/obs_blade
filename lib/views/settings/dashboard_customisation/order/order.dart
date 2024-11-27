import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/shared/dialogs/confirmation.dart';
import 'package:obs_blade/shared/general/themed/cupertino_button.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/views/settings/dashboard_customisation/order/widgets/element_list.dart';

import '../../../../shared/general/transculent_cupertino_navbar_wrapper.dart';

class DashboardCustomisationOrderView extends StatelessWidget {
  const DashboardCustomisationOrderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        previousTitle: 'Customisation',
        title: 'Order',
        actions: ThemedCupertinoButton(
          text: 'Reset',
          padding: const EdgeInsets.all(0),
          onPressed: () => ModalHandler.showBaseDialog(
            context: context,
            dialogWidget: ConfirmationDialog(
              title: 'Reset Order',
              body:
                  'Are you sure you want to reset the order of the dashboard elements?',
              isYesDestructive: true,
              onOk: (_) => Hive.box(HiveKeys.Settings.name).clear(),
            ),
          ),
        ),
        customBody: const ElementList(),
      ),
    );
  }
}
