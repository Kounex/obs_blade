import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../models/enums/chat_type.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/base/adaptive_switch.dart';
import '../../../../../shared/general/themed/cupertino_button.dart';
import '../../../../../stores/views/combined_chat.dart';
import '../../../../../stores/views/kick_chat.dart';
import '../../../../../stores/views/twitch_chat.dart';
import '../../../../../stores/views/youtube_chat.dart';
import '../../../../../types/classes/combined/combined_combo.dart';
import '../../../../../utils/modal_handler.dart';
import 'chat_type_brand.dart';
import 'combined_chat_builder_sheet.dart';
import 'kick_setup_sheet.dart';
import 'native_chat_chrome.dart';
import 'native_chat_window.dart';
import 'twitch_device_code_dialog.dart';
import 'youtube_device_code_dialog.dart';
import 'youtube_setup_sheet.dart';

/// The combined window's status: the healthiest source wins (one live
/// source means the timeline is live), then connecting; failed only when
/// every source failed.
NativeChatConnectionStatus combinedChatWindowStatus(
  Iterable<CombinedSourceStatus> statuses,
) {
  if (statuses.contains(CombinedSourceStatus.live)) {
    return NativeChatConnectionStatus.live;
  }
  if (statuses.contains(CombinedSourceStatus.connecting)) {
    return NativeChatConnectionStatus.connecting;
  }
  if (statuses.isNotEmpty &&
      statuses.every((status) => status == CombinedSourceStatus.error)) {
    return NativeChatConnectionStatus.failed;
  }
  return NativeChatConnectionStatus.offline;
}

/// The combined chat's sources: one row per platform with its status and
/// the fix for it (sign in, set up, retry), plus the "My chats" toggle.
/// [comboId] picks which combo the sheet is about ("My chats" by
/// [kMyChatsComboId], a saved combo by its id); null = the one shown.
Future<void> showCombinedSourcesSheet(
  BuildContext context, {
  String? comboId,
}) => ModalHandler.showBaseBottomSheet(
  context: context,
  barrierDismissible: true,
  enableDrag: true,
  maxHeightFraction: 0.72,
  builder: (_) => CombinedSourcesSheet(hostContext: context, comboId: comboId),
);

class CombinedSourcesSheet extends StatelessWidget {
  /// The chat pane's context — sign-in dialogs open on it, not on the
  /// sheet that closes first.
  final BuildContext hostContext;

  /// The combo this sheet manages — null follows the shown combo.
  final String? comboId;

  const CombinedSourcesSheet({
    super.key,
    required this.hostContext,
    this.comboId,
  });

  static const List<ChatType> kPlatforms = [
    ChatType.Twitch,
    ChatType.YouTube,
    ChatType.Kick,
  ];

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final store = GetIt.instance<CombinedChatStore>();
        final id = this.comboId ?? store.selectedComboId;
        CombinedCombo? combo;
        for (final candidate in store.combos) {
          if (candidate.id == id) combo = candidate;
        }
        return NativeChatSheetScaffold(
          headerGap: AppSpacing.sm,
          header: Row(
            children: [
              Expanded(
                child: Text(
                  combo?.displayName ?? 'My chats',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: nativeChatSheetTitleStyle(context),
                ),
              ),
              if (combo != null)
                ThemedCupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  text: 'Edit',
                  onPressed: () {
                    Navigator.of(context).pop();
                    showCombinedChatBuilderSheet(
                      this.hostContext,
                      combo: combo,
                    );
                  },
                ),
            ],
          ),
          body: combo == null
              ? this._myChatsBody(context, store)
              : this._comboBody(context, store, combo),
        );
      },
    );
  }

  /// "My chats": every platform, with sign-in actions and on/off toggles.
  Widget _myChatsBody(BuildContext context, CombinedChatStore store) {
    final available = {
      for (final source in store.availableSources) source.platform: source,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your own channels on each platform you are signed in to natively, merged into one chat.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final platform in kPlatforms)
          _SourceRow(
            platform: platform,
            source: available[platform],
            enabled: !store.disabledPlatforms.contains(platform),
            status: store.selectedComboId == kMyChatsComboId
                ? store.sourceStatus[platform]
                : null,
            onToggle: (value) => store.setPlatformEnabled(platform, value),
            onFix: () {
              Navigator.of(context).pop();
              combinedSourceFix(this.hostContext, platform);
            },
          ),
      ],
    );
  }

  /// A saved combo: its sources with their status and fix actions (the
  /// channel set is changed in the builder, not toggled here).
  Widget _comboBody(
    BuildContext context,
    CombinedChatStore store,
    CombinedCombo combo,
  ) {
    /// Live status exists only for the combo on screen — the platform
    /// stores are pointed at its channels, not at this one's.
    final shown = store.selectedComboId == combo.id;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final source in store.sourcesOf(combo))
          _SourceRow(
            platform: source.platform,
            source: source,
            enabled: true,
            status: shown
                ? store.sourceStatus[source.platform]
                : (source.unavailable ? CombinedSourceStatus.needsSetup : null),
            onFix: () {
              Navigator.of(context).pop();
              combinedSourceFix(
                this.hostContext,
                source.platform,
                forMyChats: false,
              );
            },
          ),
      ],
    );
  }
}

/// What tapping a source's status does: set up where the platform isn't
/// configured, sign in where the source needs the account (Twitch always;
/// YouTube / Kick only for "My chats", whose sources ARE the own
/// channels), else retry.
void combinedSourceFix(
  BuildContext context,
  ChatType platform, {
  bool forMyChats = true,
}) {
  switch (platform) {
    case ChatType.Twitch:
      final store = GetIt.instance<TwitchChatStore>();
      store.isLoggedIn ? store.connectChat() : startTwitchLogin(context);
    case ChatType.YouTube:
      final store = GetIt.instance<YouTubeChatStore>();
      if (store.authState == YouTubeAuthState.unconfigured) {
        showYouTubeSetupSheet(context);
      } else if (forMyChats && store.ownChannel == null) {
        startYouTubeLogin(context);
      } else {
        store.connectChat();
      }
    case ChatType.Kick:
      final store = GetIt.instance<KickChatStore>();
      forMyChats && store.ownChannelSlug == null
          ? showKickSetupSheet(context)
          : store.connectChat();
    case ChatType.Owncast:
    case ChatType.Combined:
      break;
  }
}

class _SourceRow extends StatelessWidget {
  final ChatType platform;

  /// The own channel — null while not signed in on [platform].
  final CombinedSource? source;
  final bool enabled;
  final CombinedSourceStatus? status;

  /// Null hides the switch (saved combos).
  final ValueChanged<bool>? onToggle;
  final VoidCallback onFix;

  const _SourceRow({
    required this.platform,
    required this.source,
    required this.enabled,
    required this.status,
    this.onToggle,
    required this.onFix,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall;
    final source = this.source;
    final (String label, String? action) = source == null
        ? ('Not signed in', 'Sign in')
        : !this.enabled
        ? ('Off', null)
        : switch (this.status) {
            CombinedSourceStatus.live => ('Live', null),
            CombinedSourceStatus.connecting => ('Connecting…', null),
            CombinedSourceStatus.needsSetup => ('Needs setup', 'Set up'),
            CombinedSourceStatus.error => ('Failed', 'Retry'),
            CombinedSourceStatus.offline => ('Offline', null),

            /// Not the combo on screen — no live status to report.
            null => ('Ready', null),
          };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(this.platform.icon, color: this.platform.brandColor, size: 20.0),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source?.label ?? this.platform.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  key: Key('combined-source-status-${this.platform.name}'),
                  style: muted,
                ),
              ],
            ),
          ),
          if (action != null)
            ThemedCupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              text: action,
              onPressed: this.onFix,
            ),
          if (source != null && this.onToggle != null)
            BaseAdaptiveSwitch(value: this.enabled, onChanged: this.onToggle!),
        ],
      ),
    );
  }
}
