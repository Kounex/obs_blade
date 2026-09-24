import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../../../../../../utils/styling_helper.dart';
import '../chat_type_brand.dart';
import '../combined_chat_icon.dart';

class ChatTypeDropdown extends StatelessWidget {
  final Box settingsBox;

  const ChatTypeDropdown({super.key, required this.settingsBox});

  @override
  Widget build(BuildContext context) {
    return Container(
      /// 44pt touch target ([kMinInteractiveDimensionCupertino]) - finger
      /// friendly next to the other bar controls; the button centers inside
      constraints: const BoxConstraints(
        minHeight: kMinInteractiveDimensionCupertino,
      ),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          width: 0.0,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: DropdownButton<ChatType>(
            value: this.settingsBox.get(
              SettingsKeys.SelectedChatType.name,
              defaultValue: ChatType.Twitch,
            ),
            isExpanded: true,
            isDense: true,
            borderRadius: BorderRadius.circular(AppRadius.md),
            items: ChatType.values
                .map(
                  (chatType) => DropdownMenuItem(
                    value: chatType,
                    child: Row(
                      children: [
                        chatTypeIcon(
                          context,
                          chatType.icon,
                          combined: chatType == ChatType.Combined,
                          color: chatType.brandColor,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            chatType.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (chatType) => this.settingsBox.put(
              SettingsKeys.SelectedChatType.name,
              chatType,
            ),
          ),
        ),
      ),
    );
  }
}
