import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';
import '../chat_type_brand.dart';

class ChatTypeDropdown extends StatelessWidget {
  final Box settingsBox;

  const ChatTypeDropdown({super.key, required this.settingsBox});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            // isExpanded: true,
            value: this.settingsBox.get(SettingsKeys.SelectedChatType.name,
                defaultValue: ChatType.Twitch),
            isExpanded: true,
            isDense: true,
            borderRadius: BorderRadius.circular(AppRadius.md),
            items: ChatType.values
                .map(
                  (chatType) => DropdownMenuItem(
                    value: chatType,
                    child: Row(
                      children: [
                        Icon(
                          chatType.icon,
                          color: chatType.brandColor,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(chatType.text),
                            if (chatType == ChatType.YouTube)
                              Text(
                                '\u1d47\u1d49\u1d57\u1d43',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                          ],
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (chatType) => chatType == ChatType.YouTube &&
                    !Hive.box(HiveKeys.Settings.name).get(
                        SettingsKeys.DontShowYouTubeChatBetaWarning.name,
                        defaultValue: false)
                ? ModalHandler.showBaseDialog(
                    context: context,
                    dialogWidget: ConfirmationDialog(
                      title: 'YoutTube Chat Beta',
                      body:
                          'YouTube chat support is still in beta because YouTube is giving me a hard time to integrate it.\n\nUse it with that in mind and contact me if you experience strange behaviour.',
                      enableDontShowAgainOption: true,
                      noText: 'Cancel',
                      okText: 'Ok',
                      onOk: (checked) {
                        if (checked) {
                          this.settingsBox.put(
                              SettingsKeys.DontShowYouTubeChatBetaWarning.name,
                              checked);
                        }
                        this
                            .settingsBox
                            .put(SettingsKeys.SelectedChatType.name, chatType);
                      },
                    ),
                  )
                : this
                    .settingsBox
                    .put(SettingsKeys.SelectedChatType.name, chatType),
          ),
        ),
      ),
    );
  }
}
