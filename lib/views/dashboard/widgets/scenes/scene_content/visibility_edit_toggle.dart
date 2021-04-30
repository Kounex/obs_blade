import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/models/enums/scene_item_type.dart';
import 'package:obs_blade/shared/dialogs/confirmation.dart';
import 'package:obs_blade/shared/general/themed/themed_cupertino_button.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/views/settings/widgets/action_block.dart/light_divider.dart';
import 'package:provider/provider.dart';

class VisibilityEditToggle extends StatelessWidget {
  final Widget? child;
  final SceneItemType sceneItemType;
  final bool tabletMode;

  VisibilityEditToggle({
    this.child,
    required this.sceneItemType,
    this.tabletMode = false,
  }) : assert(!tabletMode && child != null || tabletMode);

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = context.read<DashboardStore>();

    VoidCallback onEdit = () {
      if (this.sceneItemType == SceneItemType.Source) {
        dashboardStore.setEditSceneItemVisibility(
            !dashboardStore.editSceneItemVisibility);
      } else if (this.sceneItemType == SceneItemType.Audio)
        dashboardStore
            .setEditAudioVisibility(!dashboardStore.editAudioVisibility);
    };

    Widget editButton = Observer(
      builder: (_) => ThemedCupertinoButton(
        text: (this.sceneItemType == SceneItemType.Source
                ? dashboardStore.editSceneItemVisibility
                : dashboardStore.editAudioVisibility)
            ? 'Done'
            : 'Edit',
        onPressed: () => !(this.sceneItemType == SceneItemType.Source
                    ? dashboardStore.editSceneItemVisibility
                    : dashboardStore.editAudioVisibility) &&
                !Hive.box(HiveKeys.Settings.name).get(
                    SettingsKeys.DontShowHidingSceneItemsWarning.name,
                    defaultValue: false)
            ? ModalHandler.showBaseDialog(
                context: context,
                dialogWidget: ConfirmationDialog(
                  title: 'Warning on hiding items',
                  body:
                      'OBS WebSocket does expose limited information about items in a scene. Therefore items will get visible again automatically if the scene the item is in gets renamed, the item itself gets renamed or the item gets removed and inserted back into the scene.\n\nSorry for the inconvenience - just hide it again if this happens!',
                  enableDontShowAgainOption: true,
                  noText: 'Cancel',
                  okText: 'Ok',
                  onOk: (checked) {
                    if (checked)
                      Hive.box(HiveKeys.Settings.name).put(
                          SettingsKeys.DontShowHidingSceneItemsWarning.name,
                          checked);
                    onEdit();
                  },
                ),
              )
            : onEdit(),
      ),
    );

    return this.tabletMode
        ? editButton
        : Column(
            children: [
              Align(
                alignment: Alignment.center,
                child: editButton,
              ),
              LightDivider(),
              Expanded(
                child: this.child!,
              ),
            ],
          );
  }
}
