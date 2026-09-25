import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../models/enums/chat_type.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../stores/views/combined_chat.dart';
import '../../../../../stores/views/twitch_chat.dart';
import '../../../../../utils/modal_handler.dart';
import '../../../../../utils/styling_helper.dart';
import 'chat_completion_sources.dart';
import 'chat_emote_picker.dart';
import 'chat_type_brand.dart';
import 'combined_sources_sheet.dart';
import 'kick_emote_picker.dart';
import 'kick_reply_strip.dart';
import 'native_chat_chrome.dart';
import 'native_chat_input.dart';
import 'native_combined_chat_view.dart';
import 'native_reply_strip.dart';
import 'twitch_device_code_dialog.dart';

/// Input dock of the combined chat: [NativeChatInput] sending to
/// [CombinedChatStore.sendTarget]. A target chip in front of the field
/// shows (and picks) the platform; the emote picker, autocomplete, accent
/// and reply strip follow the target. A pending reply locks the chip to
/// the replied message's platform. Nothing writable (no source signed in
/// with write access) docks the read-only strip, whose action opens the
/// sources sheet.
class CombinedChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const CombinedChatInput({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final store = GetIt.instance<CombinedChatStore>();
        final target = store.sendTarget;
        final accent =
            target?.brandColor ?? Theme.of(context).colorScheme.secondary;

        if (target == null) {
          return NativeChatInput(
            canSend: false,
            inFlight: false,
            accentColor: accent,
            onSend: (_) async => false,
            onRelogin: () => showCombinedSourcesSheet(context),
            lockedHintText: 'Chat is read-only',
            lockedActionText: 'Sign in to chat',
          );
        }

        final emotePicker = switch (target) {
          ChatType.Twitch => ChatEmotePickerButton(
            controller: this.controller,
            focusNode: this.focusNode,
            canReadEmotes: GetIt.instance<TwitchChatStore>().canReadEmotes,
            accentColor: accent,
            onRelogin: () => startTwitchLogin(context),
          ),
          ChatType.Kick => KickEmotePickerButton(
            controller: this.controller,
            focusNode: this.focusNode,
            accentColor: accent,
          ),
          _ => null,
        };

        return NativeChatInput(
          controller: this.controller,
          focusNode: this.focusNode,
          canSend: true,
          inFlight: store.sendingChat,
          errorText: store.sendChatError,
          accentColor: accent,
          hintText: 'Send to ${target.text}…',
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CombinedSendTargetChip(
                target: target,
                locked: store.replyPlatform != null,
                selectable: store.writableTargets.length > 1,
                onTap: () => showCombinedSendTargetSheet(context),
              ),
              if (emotePicker != null) ...[
                const SizedBox(width: AppSpacing.xs),
                emotePicker,
              ],
            ],
          ),
          contextStrip: switch (store.replyPlatform) {
            ChatType.Twitch => NativeReplyStrip(accentColor: accent),
            ChatType.Kick => KickReplyStrip(accentColor: accent),
            _ => null,
          },
          completionSource: switch (target) {
            ChatType.Twitch => twitchChatCompletions,
            ChatType.YouTube => youTubeChatCompletions,
            ChatType.Kick => kickChatCompletions,
            _ => null,
          },
          onSend: store.send,
          onRelogin: () => showCombinedSourcesSheet(context),
        );
      },
    );
  }
}

/// The send target in the dock: the platform badge (plus a chevron when
/// there is a choice). Locked while a reply is pending — the reply goes
/// to its message's platform.
class CombinedSendTargetChip extends StatelessWidget {
  final ChatType target;
  final bool locked;
  final bool selectable;
  final VoidCallback onTap;

  const CombinedSendTargetChip({
    super.key,
    required this.target,
    required this.locked,
    required this.selectable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final interactive = this.selectable && !this.locked;
    return Semantics(
      button: interactive,
      label: 'Send to ${this.target.text}',
      child: Pressable(
        key: const Key('combined-send-target'),
        haptic: true,
        onTap: interactive ? this.onTap : null,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: kMinInteractiveDimensionCupertino,
            minHeight: kMinInteractiveDimensionCupertino,
          ),
          alignment: Alignment.bottomCenter,
          child: Container(
            height: kNativeChatDockControlSize,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: StylingHelper.lightenDarkenColor(
                Theme.of(context).cardColor,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                width: 0.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CombinedPlatformBadge(platform: this.target, size: 20.0),
                if (interactive) ...[
                  const SizedBox(width: AppSpacing.xs / 2),
                  Icon(
                    CupertinoIcons.chevron_up_chevron_down,
                    size: 12.0,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Send to" sheet: one row per writable source; picking one makes it the
/// dock's target (remembered).
Future<void> showCombinedSendTargetSheet(BuildContext context) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      enableDrag: true,
      maxHeightFraction: 0.5,
      builder: (_) => const CombinedSendTargetSheet(),
    );

class CombinedSendTargetSheet extends StatelessWidget {
  const CombinedSendTargetSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final store = GetIt.instance<CombinedChatStore>();
        final current = store.sendTarget;
        final labels = {
          for (final source in store.activeSources)
            source.platform: source.label,
        };
        return NativeChatSheetScaffold(
          header: Text('Send to', style: nativeChatSheetTitleStyle(context)),
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final platform in store.writableTargets)
                Pressable(
                  key: Key('combined-send-target-${platform.name}'),
                  haptic: true,
                  onTap: () {
                    store.selectSendTarget(platform);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: kMinInteractiveDimensionCupertino,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        CombinedPlatformBadge(platform: platform, size: 20.0),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                labels[platform] ?? platform.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                platform.text,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (platform == current)
                          Icon(
                            CupertinoIcons.checkmark_alt,
                            size: 18.0,
                            color: platform.brandColor,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
