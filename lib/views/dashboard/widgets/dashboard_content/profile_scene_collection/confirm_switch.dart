import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../shared/dialogs/confirmation.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/modal_handler.dart';

/// Scene collection / profile switches replace every scene or output
/// setting in OBS at once - a mis-tap on the dropdown mid-stream is more
/// disruptive than stopping a recording, which already asks. Same
/// "don't show again" pattern as the stream / record confirmations; one
/// opt-out covers both dropdowns.
void confirmCollectionProfileSwitch(
  BuildContext context, {
  required String kind,
  required String target,
  required VoidCallback onConfirmed,
}) {
  final Box settingsBox = Hive.box(HiveKeys.Settings.name);
  if (settingsBox.get(
    SettingsKeys.DontShowSwitchCollectionProfileMessage.name,
    defaultValue: false,
  )) {
    onConfirmed();
    return;
  }

  ModalHandler.showBaseDialog(
    context: context,
    dialogWidget: ConfirmationDialog(
      title: 'Switch $kind',
      body:
          'Switch to "$target"? OBS swaps it in right away - if you\'re live, your viewers see the change.',
      okText: 'Switch',
      noText: 'Cancel',
      enableDontShowAgainOption: true,
      onOk: (checked) {
        settingsBox.put(
          SettingsKeys.DontShowSwitchCollectionProfileMessage.name,
          checked,
        );
        onConfirmed();
      },
    ),
  );
}
