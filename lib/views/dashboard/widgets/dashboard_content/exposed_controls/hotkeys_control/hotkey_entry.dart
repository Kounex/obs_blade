import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../../models/hotkey.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/general/base/icon_button.dart';
import '../../../../services/hotkey_trigger.dart';

class HotkeyEntry extends StatelessWidget {
  final Box<Hotkey> hotkeyBox;
  final Hotkey hotkey;

  const HotkeyEntry({super.key, required this.hotkeyBox, required this.hotkey});

  @override
  Widget build(BuildContext context) {
    final AppStatusColors statusColors = Theme.of(
      context,
    ).extension<AppStatusColors>()!;

    return ListTile(
      title: Text(hotkeyDisplayName(this.hotkey.name)),
      subtitle: Text(this.hotkey.name),
      contentPadding: const EdgeInsets.all(0),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BaseIconButton(
            onTap: () => this.hotkey.isInBox
                ? this.hotkeyBox.delete(this.hotkey.key)
                : this.hotkeyBox.add(this.hotkey),
            icon: this.hotkey.isInBox
                ? CupertinoIcons.star_fill
                : CupertinoIcons.star,
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: this.hotkey.isInBox
                ? statusColors.favorite
                : Theme.of(context).colorScheme.onSurface,
            iconSize: 18.0,
            buttonSize: 32.0,
          ),
          const SizedBox(width: 18.0),
          BaseIconButton(
            /// Fires immediately with the sheet still open - the confirm
            /// overlay names the hotkey, so several can be fired in a row
            onTap: () => triggerHotkey(context, this.hotkey.name),
            icon: CupertinoIcons.play_arrow_solid,
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            iconSize: 18.0,
            buttonSize: 32.0,
          ),
        ],
      ),
    );
  }
}
