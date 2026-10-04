import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

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
import 'kick_native_channel_dropdown.dart';
import 'native_channel_dropdown.dart';
import 'twitch_account_control.dart';
import 'username_action_row.dart';
import 'username_dropdown.dart';
import 'youtube_account_control.dart';
import 'youtube_native_channel_dropdown.dart';

/// Chat control section. The platform dropdown is the single major
/// control; everything else hangs off the selected chat engine
/// ([SettingsKeys.SelectedChatEngine]):
///
/// WebView mode (default): username dropdown + add/edit/delete actions -
/// the classic behavior, unchanged.
///
/// Native mode (see [nativeChatAvailableFor]): the engine switch on the
/// top row, then the multi-chat channel dropdown filling a second row
/// next to the native controls (mod shield, options sheet button, the
/// sign-in pill while signed out) - never the username controls.
///
/// Native engines are a Pro entitlement: without [ProStore.isPro] the
/// native cluster (channel dropdown, options, account control) stays
/// hidden - legacy users with a persisted native engine must not get
/// dead-end login pills; the pane's locked Pro upsell is their
/// experience (the engine switch always applies, the lock badge marks
/// the gated segment).
class ChatUsernameBar extends StatefulWidget {
  const ChatUsernameBar({super.key});

  @override
  State<ChatUsernameBar> createState() => _ChatUsernameBarState();
}

class _ChatUsernameBarState extends State<ChatUsernameBar> {
  /// Native and WebView build different trees around the engine switch;
  /// the key moves its element across the swap, so a tap still slides
  /// the thumb (a fresh control would just jump). Per instance: the Chat
  /// tab and the streaming-mode header each have their own bar.
  final GlobalKey _engineSwitchKey = GlobalKey();

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
        ///
        /// Native mode: the platform dropdown + engine switch on top, then
        /// one row with the channel dropdown filling everything the
        /// right cluster (shield / options / sign-in pill) leaves - long
        /// names and the menu's LIVE chips get the room. WebView keeps
        /// its two columns (username dropdown under the platform, the
        /// add / edit / delete actions under the switch).
        if (nativeMode) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ChatBarTopRow(
                settingsBox: settingsBox,
                chatType: chatType,
                engineSwitchKey: this._engineSwitchKey,
              ),
              _NativeChannelRow(chatType: chatType),
            ],
          );
        }

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
                    const SizedBox(height: AppSpacing.sm),
                    UsernameDropdown(settingsBox: settingsBox),
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
                      key: this._engineSwitchKey,
                      settingsBox: settingsBox,
                      chatType: chatType,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
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

/// Native mode's first row: platform dropdown left, engine switch right -
/// laid out like the WebView columns' tops, so neither moves when the
/// engine switch swaps the layout below.
class _ChatBarTopRow extends StatelessWidget {
  final Box<dynamic> settingsBox;
  final ChatType chatType;

  final GlobalKey engineSwitchKey;

  const _ChatBarTopRow({
    required this.settingsBox,
    required this.chatType,
    required this.engineSwitchKey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 256.0),
            child: ChatTypeDropdown(settingsBox: this.settingsBox),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        if (nativeChatAvailableFor(this.chatType))
          Flexible(
            child: Align(
              alignment: Alignment.topRight,
              child: ChatEngineSwitch(
                key: this.engineSwitchKey,
                settingsBox: this.settingsBox,
                chatType: this.chatType,
              ),
            ),
          ),
      ],
    );
  }
}

/// Native mode's second row: the channel dropdown takes all the width the
/// right cluster doesn't need (Twitch gates it on login; YouTube reads
/// work signed out, so it gates on configuration; Kick on having a
/// channel). Without a dropdown the cluster stays right-aligned. Both
/// need the Pro entitlement - without it the row is gone (no dead-end
/// controls while the pane shows the Pro upsell).
///
/// The cluster is capped at [_kClusterMaxFraction] of the row: its
/// sign-in pill is [Flexible] and the shield fit check reads the cap
/// ([nativeModClusterFitsWithShield]).
class _NativeChannelRow extends StatelessWidget {
  static const double _kClusterMaxFraction = 0.6;

  final ChatType chatType;

  const _NativeChannelRow({required this.chatType});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        if (!GetIt.instance<ProStore>().isPro) return const SizedBox.shrink();

        final showDropdown = switch (this.chatType) {
          ChatType.Twitch => GetIt.instance<TwitchChatStore>().isLoggedIn,
          ChatType.YouTube =>
            GetIt.instance<YouTubeChatStore>().authState !=
                YouTubeAuthState.unconfigured,
          ChatType.Kick =>
            GetIt.instance<KickChatStore>().nativeChannels.isNotEmpty,
          _ => false,
        };

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                /// The channel dropdowns root in a [Flexible] themselves -
                /// the only flexible child here, so it gets the rest.
                if (showDropdown) ...[
                  if (this.chatType == ChatType.Kick)
                    const KickNativeChannelDropdown()
                  else if (this.chatType == ChatType.YouTube)
                    const YouTubeNativeChannelDropdown()
                  else
                    const NativeChannelDropdown(),
                  const SizedBox(width: AppSpacing.sm),
                ] else
                  const Spacer(),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * _kClusterMaxFraction,
                  ),
                  child: _NativeRightCluster(chatType: this.chatType),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Native right cluster: optional Mod shield + options, plus the sign-in
/// pill while signed out. Signed in there is no account chip - the
/// account and its sign-out live in the chat header's sheet - so the
/// shield + options (~96pt) fit any phone.
///
/// Twitch: the shield shows when moderating; should it ever not fit, Mod
/// folds into a combined options chip
/// ([NativeChatOptionsButton.modFoldedIntoOptions]).
///
/// YouTube and Kick: neither has a cheap "am I a mod" lookup, so the
/// shield shows whenever the account may write; a refused action toasts
/// why ([chatNotModeratorText]).
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
            final signedIn = kick
                ? GetIt.instance<KickChatStore>().isSignedInState
                : GetIt.instance<YouTubeChatStore>().isSignedInState;
            final canWrite =
                signedIn &&
                (kick
                    ? GetIt.instance<KickChatStore>().canWrite
                    : GetIt.instance<YouTubeChatStore>().canWrite);
            final showShield =
                canWrite &&
                nativeModClusterFitsWithShield(maxWidth: constraints.maxWidth);
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
                    ? const NativeChatOptionsButton(chatType: ChatType.Kick)
                    : const NativeChatOptionsButton(chatType: ChatType.YouTube),
                if (!signedIn) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: kick
                        ? const KickAccountControl()
                        : const YouTubeAccountControl(),
                  ),
                ],
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
            final showShield =
                canMod &&
                nativeModClusterFitsWithShield(maxWidth: constraints.maxWidth);
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
                if (!store.isLoggedIn) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const Flexible(child: TwitchAccountControl()),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
