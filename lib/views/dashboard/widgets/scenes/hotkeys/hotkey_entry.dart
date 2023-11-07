import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import '../../../../../models/hotkey.dart';
import '../../../../../shared/general/base/icon_button.dart';
import '../../../../../stores/shared/network.dart';
import '../../../../../types/enums/request_type.dart';
import '../../../../../utils/network_helper.dart';

class HotkeyEntry extends StatelessWidget {
  final Box<Hotkey> hotkeyBox;
  final Hotkey hotkey;

  const HotkeyEntry({
    super.key,
    required this.hotkeyBox,
    required this.hotkey,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        this.hotkey.name.split('.').sublist(1).join(),
      ),
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
            backgroundColor: Theme.of(context).colorScheme.background,
            foregroundColor: this.hotkey.isInBox
                ? Colors.amber
                : Theme.of(context).colorScheme.onBackground,
            iconSize: 20.0,
            buttonSize: 32.0,
          ),
          const SizedBox(width: 18.0),
          BaseIconButton(
            onTap: () {
              Navigator.of(context).pop();
              Future.delayed(
                const Duration(milliseconds: 500),
                () {
                  NetworkHelper.makeRequest(
                    GetIt.instance<NetworkStore>().activeSession!.socket,
                    RequestType.TriggerHotkeyByName,
                    {'hotkeyName': this.hotkey.name},
                  );
                },
              );
            },
            icon: CupertinoIcons.play_arrow_solid,
            backgroundColor: Theme.of(context).colorScheme.background,
            foregroundColor: Theme.of(context).colorScheme.onBackground,
            iconSize: 20.0,
            buttonSize: 32.0,
          ),
        ],
      ),
    );
  }
}
