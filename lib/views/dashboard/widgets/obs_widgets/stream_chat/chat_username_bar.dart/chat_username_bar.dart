import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../models/enums/chat_engine.dart';
import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/general/hive_builder.dart';
import '../../../../../../stores/pro_store.dart';
import '../../../../../../stores/views/twitch_chat.dart';
import '../../../../../../stores/views/youtube_chat.dart';
import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../channel_mod_button.dart';
import '../native_chat_options_sheet.dart';
import 'chat_engine_switch.dart';
import 'chat_type_dropdown.dart';
import 'native_channel_dropdown.dart';
import 'twitch_account_control.dart';
import 'username_action_row.dart';
import 'username_dropdown.dart';
import 'youtube_account_control.dart';
import 'youtube_chat_options_sheet.dart';
import 'youtube_native_channel_dropdown.dart';

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
///
/// Native engines are a Pro entitlement: without [ProStore.isPro] the
/// native cluster (channel dropdown, options, account control) stays
/// hidden - legacy users with a persisted native engine must not get
/// dead-end login pills; the pane's Pro upsell is their experience and
/// the engine switch (lock badge) is the way out.
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
                        /// Native-mode channel dropdown slot — per
                        /// platform. Twitch gates on login; YouTube reads
                        /// work signed-out, so it gates on configuration.
                        /// Both gate on the Pro entitlement: without it
                        /// the slot stays empty (no dead-end controls).
                        Observer(
                          builder: (_) {
                            if (!GetIt.instance<ProStore>().isPro) {
                              return const SizedBox.shrink();
                            }

                            final showDropdown = switch (chatType) {
                              ChatType.Twitch => GetIt
                                  .instance<TwitchChatStore>()
                                  .isLoggedIn,
                              ChatType.YouTube => GetIt
                                      .instance<YouTubeChatStore>()
                                      .authState !=
                                  YouTubeAuthState.unconfigured,
                              _ => false,
                            };

                            /// Inner Column: the channel dropdowns root
                            /// in a Flexible (like [UsernameDropdown]), so
                            /// they need a direct Flex ancestor
                            return showDropdown
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: AppSpacing.sm),
                                      if (chatType == ChatType.YouTube)
                                        const YouTubeNativeChannelDropdown()
                                      else
                                        const NativeChannelDropdown(),
                                    ],
                                  )
                                : const SizedBox.shrink();
                          },
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
                      /// Native cluster hidden without the entitlement -
                      /// login pills / options would be dead ends while
                      /// the pane shows the Pro upsell
                      Observer(
                        builder: (_) => GetIt.instance<ProStore>().isPro
                            ? _NativeRightCluster(chatType: chatType)
                            : const SizedBox.shrink(),
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

/// Native right cluster: optional Mod shield (fit-gated) + options + account.
/// Shield shows when moderating and the cluster fits; otherwise Mod folds
/// into a combined options chip ([NativeChatOptionsButton.modFoldedIntoOptions]).
///
/// YouTube dispatches to its own minimal cluster (options + account) — no
/// shield: YouTube has no cheap "am I a mod" lookup, so mod actions live on
/// the per-message long-press only (plan §7).
class _NativeRightCluster extends StatelessWidget {
  final ChatType chatType;

  const _NativeRightCluster({required this.chatType});

  @override
  Widget build(BuildContext context) {
    if (this.chatType == ChatType.YouTube) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          YouTubeChatOptionsButton(),
          SizedBox(width: AppSpacing.sm),
          Flexible(child: YouTubeAccountControl()),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Observer(
          builder: (_) {
            final store = GetIt.instance<TwitchChatStore>();
            // Touch observables so fit/gate rebuilds on channel / auth change.
            store.authState;
            store.selectedChannelId;
            store.moderatedChannelIds.length;
            final canMod = store.canModerateSelectedChannel;
            final displayName = store.user?.displayName ?? store.user?.login;
            final accountWidth =
                accountChipPreferredWidth(context, displayName);
            final showShield = canMod &&
                nativeModClusterFitsWithShield(
                  maxWidth: constraints.maxWidth,
                  accountWidth: accountWidth,
                );
            final modFoldedIntoOptions = canMod && !showShield;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showShield) ...[
                  const ChannelModButton(),
                  const SizedBox(width: AppSpacing.sm),
                ],
                NativeChatOptionsButton(
                  chatType: this.chatType,
                  modFoldedIntoOptions: modFoldedIntoOptions,
                ),
                const SizedBox(width: AppSpacing.sm),
                const Flexible(child: TwitchAccountControl()),
              ],
            );
          },
        );
      },
    );
  }
}
