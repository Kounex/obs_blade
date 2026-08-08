import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../models/enums/chat_engine.dart';
import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/general/hive_builder.dart';
import '../../../../../../stores/views/twitch_chat.dart';
import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../native_chat_options_sheet.dart';
import 'chat_engine_switch.dart';
import 'chat_type_dropdown.dart';
import 'native_channel_dropdown.dart';
import 'twitch_account_control.dart';
import 'username_action_row.dart';
import 'username_dropdown.dart';

/// Chat control section. The platform dropdown is the single major
/// control; everything else hangs off the selected chat engine
/// ([SettingsKeys.SelectedChatEngine]):
///
/// WebView mode (default): username dropdown + add/edit/delete actions -
/// the classic behavior, unchanged.
///
/// Native mode (Twitch only, see [nativeChatAvailableFor]): the engine
/// switch plus the native controls (options sheet button + account
/// control: login/logout, connected account) - never the username
/// controls. While logged in, the multi-chat channel dropdown
/// ([NativeChannelDropdown]) takes the username dropdown's slot.
class ChatUsernameBar extends StatelessWidget {
  const ChatUsernameBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.SelectedChatType,
        SettingsKeys.SelectedChatEngine,
        SettingsKeys.TwitchUsernames,
        SettingsKeys.SelectedTwitchUsername,
        SettingsKeys.YouTubeUsernames,
        SettingsKeys.SelectedYouTubeUsername,
        SettingsKeys.OwncastUsernames,
        SettingsKeys.SelectedOwncastUsername,
      ],
      builder: (context, settingsBox, child) {
        final ChatType chatType = settingsBox.get(
          SettingsKeys.SelectedChatType.name,
          defaultValue: ChatType.Twitch,
        );
        final ChatEngine engine = settingsBox.get(
          SettingsKeys.SelectedChatEngine.name,
          defaultValue: ChatEngine.webView,
        );
        final bool nativeMode =
            nativeChatAvailableFor(chatType) && engine == ChatEngine.native;

        return Padding(
          padding:
              const EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            /// Top-aligned so the platform dropdown (and the engine switch)
            /// keep their position when the mode swap adds/removes the
            /// controls below them
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 256.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChatTypeDropdown(settingsBox: settingsBox),
                      if (!nativeMode) ...[
                        const SizedBox(height: AppSpacing.sm),
                        UsernameDropdown(
                          settingsBox: settingsBox,
                        ),
                      ] else
                        Observer(
                          builder: (_) => GetIt
                                  .instance<TwitchChatStore>()
                                  .isLoggedIn

                              /// Inner Column: [NativeChannelDropdown] roots
                              /// in a Flexible (like [UsernameDropdown]), so
                              /// it needs a direct Flex ancestor
                              ? const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: AppSpacing.sm),
                                    NativeChannelDropdown(),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (nativeChatAvailableFor(chatType)) ...[
                      ChatEngineSwitch(
                        settingsBox: settingsBox,
                        chatType: chatType,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (nativeMode)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NativeChatOptionsButton(chatType: chatType),
                          const SizedBox(width: AppSpacing.sm),
                          const TwitchAccountControl(),
                        ],
                      )
                    else
                      UsernameActionRow(
                        settingsBox: settingsBox,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
