import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../../shared/overlay/base_result.dart';
import '../../../stores/views/dashboard.dart';
import '../../../types/enums/request_type.dart';
import '../../../utils/overlay_handler.dart';

/// Human label of an OBS hotkey name (`OBSBasic.StartStreaming` ->
/// `StartStreaming`) - same split the hotkey list shows as the title
String hotkeyDisplayName(String hotkeyName) => hotkeyName.contains('.')
    ? hotkeyName.split('.').sublist(1).join()
    : hotkeyName;

/// Fires an OBS hotkey right away and confirms WHICH one fired once OBS
/// acked it. Hotkeys map to arbitrary OBS actions (even "stop streaming"),
/// so a silent fire leaves the user guessing - failures surface through
/// the command-failure toast like every other mutation.
Future<void> triggerHotkey(BuildContext context, String hotkeyName) async {
  HapticFeedback.lightImpact();

  final ack = await GetIt.instance<DashboardStore>().sendMutation(
    RequestType.TriggerHotkeyByName,
    fields: {'hotkeyName': hotkeyName},
    label: 'Hotkey "${hotkeyDisplayName(hotkeyName)}"',
  );

  if (ack.success && context.mounted) {
    OverlayHandler.showStatusOverlay(
      context: context,
      replaceIfActive: true,
      content: BaseResult(text: 'Fired: ${hotkeyDisplayName(hotkeyName)}'),
    );
  }
}
