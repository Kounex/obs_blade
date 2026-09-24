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
import '../../../../../utils/modal_handler.dart';
import 'chat_type_brand.dart';
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
Future<void> showCombinedSourcesSheet(BuildContext context) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      enableDrag: true,
      maxHeightFraction: 0.72,
      builder: (_) => CombinedSourcesSheet(hostContext: context),
    );

class CombinedSourcesSheet extends StatelessWidget {
  /// The chat pane's context — sign-in dialogs open on it, not on the
  /// sheet that closes first.
  final BuildContext hostContext;

  const CombinedSourcesSheet({super.key, required this.hostContext});

  static const List<ChatType> kPlatforms = [
    ChatType.Twitch,
    ChatType.YouTube,
    ChatType.Kick,
  ];

  @override
  Widget build(BuildContext context) {
    return NativeChatSheetScaffold(
      headerGap: AppSpacing.sm,
      header: Text('My chats', style: nativeChatSheetTitleStyle(context)),
      body: Observer(
        builder: (_) {
          final store = GetIt.instance<CombinedChatStore>();
          final available = {
            for (final source in store.availableSources)
              source.platform: source,
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
                  status: store.sourceStatus[platform],
                  onToggle: (value) =>
                      store.setPlatformEnabled(platform, value),
                  onFix: () {
                    Navigator.of(context).pop();
                    combinedSourceFix(this.hostContext, platform);
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

/// What tapping a source's status does: sign in where there is no own
/// channel yet, set up where the platform isn't configured, else retry.
void combinedSourceFix(BuildContext context, ChatType platform) {
  switch (platform) {
    case ChatType.Twitch:
      final store = GetIt.instance<TwitchChatStore>();
      store.isLoggedIn ? store.connectChat() : startTwitchLogin(context);
    case ChatType.YouTube:
      final store = GetIt.instance<YouTubeChatStore>();
      if (store.authState == YouTubeAuthState.unconfigured) {
        showYouTubeSetupSheet(context);
      } else if (store.ownChannel == null) {
        startYouTubeLogin(context);
      } else {
        store.connectChat();
      }
    case ChatType.Kick:
      final store = GetIt.instance<KickChatStore>();
      store.ownChannelSlug == null
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
  final ValueChanged<bool> onToggle;
  final VoidCallback onFix;

  const _SourceRow({
    required this.platform,
    required this.source,
    required this.enabled,
    required this.status,
    required this.onToggle,
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
            CombinedSourceStatus.offline || null => ('Offline', null),
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
          if (source != null)
            BaseAdaptiveSwitch(value: this.enabled, onChanged: this.onToggle),
        ],
      ),
    );
  }
}
