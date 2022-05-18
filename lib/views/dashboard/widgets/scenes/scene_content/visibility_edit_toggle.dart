import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import '../../../../../models/enums/scene_item_type.dart';
import '../../../../../shared/dialogs/confirmation.dart';
import '../../../../../shared/general/base/divider.dart';
import '../../../../../shared/general/themed/cupertino_button.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/modal_handler.dart';

class VisibilityEditToggle extends StatelessWidget {
  final Widget? child;
  final SceneItemType sceneItemType;
  final bool tabletMode;

  const VisibilityEditToggle({
    Key? key,
    this.child,
    required this.sceneItemType,
    this.tabletMode = false,
  })  : assert(!tabletMode && child != null || tabletMode),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    // ignore: prefer_function_declarations_over_variables
    VoidCallback onEdit = () {
      if (this.sceneItemType == SceneItemType.Source) {
        dashboardStore.setEditSceneItemVisibility(
            !dashboardStore.editSceneItemVisibility);
      } else if (this.sceneItemType == SceneItemType.Audio) {
        dashboardStore
            .setEditAudioVisibility(!dashboardStore.editAudioVisibility);
      }
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
                      'OBS WebSocket does expose limited information about items in a scene. Therefore items will get visible again automatically if the scene the item is in gets renamed, the item itself gets renamed or the item gets removed and inserted back into the scene.\n\nSorry for the inconvenience - just hide it again if this happens.',
                  enableDontShowAgainOption: true,
                  noText: 'Cancel',
                  okText: 'Ok',
                  onOk: (checked) {
                    if (checked) {
                      Hive.box(HiveKeys.Settings.name).put(
                          SettingsKeys.DontShowHidingSceneItemsWarning.name,
                          checked);
                    }
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
              const BaseDivider(),
              Expanded(
                child: this.child!,
              ),
            ],
          );
  }
}
