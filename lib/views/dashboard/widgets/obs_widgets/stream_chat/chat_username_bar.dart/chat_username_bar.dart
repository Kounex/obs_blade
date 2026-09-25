import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../models/enums/chat_engine.dart';
import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/general/hive_builder.dart';
import '../../../../../../stores/pro_store.dart';
import '../../../../../../stores/views/combined_chat.dart';
import '../../../../../../stores/views/kick_chat.dart';
import '../../../../../../stores/views/twitch_chat.dart';
import '../../../../../../stores/views/youtube_chat.dart';
import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../channel_mod_button.dart';
import '../dialogs/combined_channel_mod_sheet.dart';
import '../dialogs/kick_channel_mod_sheet.dart';
import '../dialogs/youtube_channel_mod_sheet.dart';
import '../native_chat_options_sheet.dart';
import 'chat_engine_switch.dart';
import 'chat_type_dropdown.dart';
import 'combined_chat_picker.dart';
import 'kick_account_control.dart';
import 'kick_chat_options_sheet.dart';
import 'kick_native_channel_dropdown.dart';
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
/// Native mode (see [nativeChatAvailableFor]): the engine
/// switch plus the native controls (options sheet button + account
/// control where the platform has one) - never the username
/// controls. While available, the multi-chat channel dropdown
/// takes the username dropdown's slot.
///
/// Native engines are a Pro entitlement: without [ProStore.isPro] the
/// native cluster (channel dropdown, options, account control) stays
/// hidden - legacy users with a persisted native engine must not get
/// dead-end login pills; the pane's locked Pro upsell is their
/// experience (the engine switch always applies, the lock badge marks
/// the gated segment).
class ChatUsernameBar extends StatelessWidget {
  const ChatUsernameBar({super.key});

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
        SettingsKeys.KickUsernames,
        SettingsKeys.SelectedKickUsername,
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
            isNativeOnly(chatType) ||
            (nativeChatAvailableFor(chatType) && engine == ChatEngine.native);

        /// Combined has no engine switch or account pill: type dropdown +
        /// options share the first row, and its combo card gets a full
        /// width row of its own (the narrow left column truncated it).
        if (chatType == ChatType.Combined) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 256.0),
                      child: ChatTypeDropdown(settingsBox: settingsBox),
                    ),
                  ),
                  const Spacer(),
                  Observer(
                    builder: (_) => GetIt.instance<ProStore>().isPro
                        ? const _NativeRightCluster(chatType: ChatType.Combined)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              Observer(
                builder: (_) => GetIt.instance<ProStore>().isPro
                    ? const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.sm),
                        child: CombinedChatPicker(),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        }

        /// No horizontal inset of its own — the host owns the page margin,
        /// so the bar's controls align edge-to-edge with the chat window
        /// below (Chat tab: [BaseConstrainedBox] padding; streaming mode:
        /// the floating header panel's uniform padding).
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          /// Top-aligned so the platform dropdown (and the engine switch)
          /// keep their position when the mode swap adds/removes the
          /// controls below them
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 256.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ChatTypeDropdown(settingsBox: settingsBox),
                    if (!nativeMode) ...[
                      const SizedBox(height: AppSpacing.sm),
                      UsernameDropdown(settingsBox: settingsBox),
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
                            ChatType.Twitch =>
                              GetIt.instance<TwitchChatStore>().isLoggedIn,
                            ChatType.YouTube =>
                              GetIt.instance<YouTubeChatStore>().authState !=
                                  YouTubeAuthState.unconfigured,
                            ChatType.Kick =>
                              GetIt.instance<KickChatStore>()
                                  .nativeChannels
                                  .isNotEmpty,
                            _ => false,
                          };

                          /// Inner Column: the channel dropdowns root
                          /// in a Flexible (like [UsernameDropdown]), so
                          /// they need a direct Flex ancestor
                          return showDropdown
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: AppSpacing.sm),
                                    if (chatType == ChatType.Kick)
                                      const KickNativeChannelDropdown()
                                    else if (chatType == ChatType.YouTube)
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
                    UsernameActionRow(settingsBox: settingsBox),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Native right cluster: optional Mod shield (fit-gated) + options + account.
/// Shield shows when moderating and the cluster fits; otherwise Mod folds
/// into a combined options chip ([NativeChatOptionsButton.modFoldedIntoOptions]).
///
/// YouTube and Kick: shield + options + account. Neither has a cheap "am
/// I a mod" lookup, so the shield shows whenever the account may write;
/// a refused action toasts why ([chatNotModeratorText]). The shield drops
/// first when the cluster doesn't fit.
///
/// Combined: shield (whenever the combo has sources — its tabbed sheet
/// explains per platform) + options.
class _NativeRightCluster extends StatelessWidget {
  final ChatType chatType;

  const _NativeRightCluster({required this.chatType});

  @override
  Widget build(BuildContext context) {
    /// Combined: options only - the sources (and their sign-ins) live in
    /// the "My chats" picker next to the type dropdown.
    if (this.chatType == ChatType.Combined) {
      return Observer(
        builder: (_) {
          /// Always with sources: the sheet's per-platform tabs explain
          /// what can't be moderated and why.
          final canMod =
              GetIt.instance<CombinedChatStore>().activeSources.isNotEmpty;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canMod) ...[
                const ChannelModButton(onTap: showCombinedChannelModSheet),
                const SizedBox(width: AppSpacing.sm),
              ],
              const NativeChatOptionsButton(chatType: ChatType.Combined),
            ],
          );
        },
      );
    }

    if (this.chatType == ChatType.Kick || this.chatType == ChatType.YouTube) {
      final kick = this.chatType == ChatType.Kick;
      return LayoutBuilder(
        builder: (context, constraints) => Observer(
          builder: (_) {
            final canWrite = kick
                ? GetIt.instance<KickChatStore>().isSignedInState &&
                      GetIt.instance<KickChatStore>().canWrite
                : GetIt.instance<YouTubeChatStore>().isSignedInState &&
                      GetIt.instance<YouTubeChatStore>().canWrite;

            /// The account chip is at most ~140pt wide.
            final showShield =
                canWrite &&
                nativeModClusterFitsWithShield(
                  maxWidth: constraints.maxWidth,
                  accountWidth: 140.0,
                );
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showShield) ...[
                  ChannelModButton(
                    key: Key('channel-mod-button-${this.chatType.name}'),
                    onTap: kick
                        ? showKickChannelModSheet
                        : showYouTubeChannelModSheet,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                kick
                    ? const KickChatOptionsButton()
                    : const YouTubeChatOptionsButton(),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: kick
                      ? const KickAccountControl()
                      : const YouTubeAccountControl(),
                ),
              ],
            );
          },
        ),
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
            final accountWidth = accountChipPreferredWidth(
              context,
              displayName,
            );
            final showShield =
                canMod &&
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
