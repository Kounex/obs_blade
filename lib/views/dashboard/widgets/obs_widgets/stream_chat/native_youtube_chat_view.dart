import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/hive_builder.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import 'dialogs/youtube_mod_action_sheet.dart';
import 'native_chat_appearance.dart';
import 'youtube_chat_message_row.dart';

/// Native YouTube chat timeline, driven by [YouTubeChatStore]'s message
/// buffer (REST polling — reads work signed-out once an API key is
/// configured). Mirrors [NativeTwitchChatView]'s scroll/pin logic and
/// pause chip; no notices/pin/emote layers — YouTube's API surface for
/// those is either absent or not wired this wave.
class NativeYouTubeChatView extends StatefulWidget {
  const NativeYouTubeChatView({super.key});

  @override
  State<NativeYouTubeChatView> createState() => _NativeYouTubeChatViewState();
}

class _NativeYouTubeChatViewState extends State<NativeYouTubeChatView> {
  final ScrollController _scrollController = ScrollController();

  /// Pinned to the newest message until the user scrolls up
  bool _pinnedToBottom = true;
  bool _unreadWhileScrolledUp = false;
  int _lastRenderedCount = 0;

  /// Message targeted by the open mod sheet (gray wash while sheet is up).
  String? _modTargetMessageId;

  YouTubeChatStore get _store => GetIt.instance<YouTubeChatStore>();

  Future<void> _openModActions(String messageId) async {
    final index =
        this._store.messages.indexWhere((message) => message.id == messageId);
    if (index < 0) return;
    final message = this._store.messages[index];
    this.setState(() => this._modTargetMessageId = messageId);
    try {
      await showYouTubeModActionSheet(this.context, message);
    } finally {
      if (this.mounted) {
        this.setState(() => this._modTargetMessageId = null);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    this._scrollController.addListener(this._onScroll);
  }

  void _onScroll() {
    if (!this._scrollController.hasClients) return;
    final position = this._scrollController.position;
    if (!position.hasContentDimensions) return;
    final atBottom = position.pixels >= position.maxScrollExtent - 24.0;
    if (atBottom && !this._pinnedToBottom) {
      setState(() {
        this._pinnedToBottom = true;
        this._unreadWhileScrolledUp = false;
      });
    } else if (!atBottom && this._pinnedToBottom) {
      setState(() => this._pinnedToBottom = false);
    }
  }

  /// Instant pin to the newest message. Prefer [jumpTo] over [animateTo]
  /// so we never race a post-frame stick-to-bottom jump.
  void _jumpToBottomIfPossible() {
    if (!this.mounted || !this._scrollController.hasClients) return;
    final position = this._scrollController.position;
    if (!position.hasContentDimensions) return;
    final target = position.maxScrollExtent;
    if ((position.pixels - target).abs() < 0.5) return;
    position.jumpTo(target);
  }

  void _resumePinnedToBottom() {
    setState(() {
      this._pinnedToBottom = true;
      this._unreadWhileScrolledUp = false;
    });
    this._jumpToBottomIfPossible();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      this._jumpToBottomIfPossible();
    });
  }

  @override
  void dispose() {
    this._scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final connection = this._store.chatConnection;

        /// Reading the observable list tracks it — tombstones mutate
        /// entries in place, so also read the length for the pin logic.
        final items = this._store.messages.toList();
        final timelineEmpty = items.isEmpty;

        if (connection == YouTubeChatConnectionState.connecting &&
            timelineEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StylingHelper.isApple(context)
                    ? const CupertinoActivityIndicator()
                    : const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Connecting to YouTube chat…',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        if (connection == YouTubeChatConnectionState.error && timelineEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Text(
                    this._store.chatError ??
                        'Could not connect to YouTube chat',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Pressable(
                  haptic: true,
                  onTap: () => this._store.connectChat(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: AppRadius.pill,
                    ),
                    child: Text(
                      'Retry',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (timelineEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                /// `offline` = the video has no active live chat (not live
                /// / chat disabled) — a normal state, not an error.
                connection == YouTubeChatConnectionState.offline
                    ? 'No active live chat — the stream is offline or chat is disabled.'
                    : 'Connected — waiting for messages…',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          );
        }

        /// Stick to bottom only when the timeline length changes while
        /// pinned — tombstones don't change the count (no jump / unread).
        final countChanged = items.length != this._lastRenderedCount;
        if (this._pinnedToBottom) {
          this._unreadWhileScrolledUp = false;
          if (countChanged) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              this._jumpToBottomIfPossible();
            });
          }
        } else if (countChanged) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (this.mounted) {
              setState(() => this._unreadWhileScrolledUp = true);
            }
          });
        }
        this._lastRenderedCount = items.length;

        /// Signed-in users get the mod long-press — YouTube has no cheap
        /// mod lookup, so a non-mod's action 403s into the snackbar
        /// (plan §7).
        final canModerate = this._store.canWrite;

        /// Appearance toggles re-render in place (shared keys with the
        /// Twitch engine — the appearance options sheet is reused as-is).
        return HiveBuilder<dynamic>(
          hiveKey: HiveKeys.Settings,
          rebuildKeys: const [
            SettingsKeys.TwitchChatTextSize,
            SettingsKeys.TwitchChatMessageSpacing,
            SettingsKeys.TwitchChatMessageSeparators,
          ],
          builder: (context, settingsBox, child) {
            final separators = NativeChatAppearance.separators(settingsBox);
            return Stack(
              children: [
                ListView.separated(
                  controller: this._scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => separators
                      ? Divider(
                          height: 1.0,
                          thickness: 0.5,
                          color: Theme.of(context)
                              .dividerColor
                              .withValues(alpha: 0.35),
                        )
                      : const SizedBox.shrink(),
                  itemBuilder: (context, index) {
                    final message = items[index];
                    return YouTubeChatMessageRow(
                      key: ValueKey(message.id),
                      message: message,
                      settingsBox: settingsBox,
                      highlighted: this._modTargetMessageId == message.id,
                      onMessageLongPress:
                          message.isTombstoned || !canModerate
                              ? null
                              : () => this._openModActions(message.id),
                    );
                  },
                ),
                if (!this._pinnedToBottom)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: AppSpacing.sm,
                    child: Center(
                      child: Pressable(
                        haptic: true,
                        onTap: this._resumePinnedToBottom,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: this._unreadWhileScrolledUp
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: AppRadius.pill,
                          ),
                          child: Text(
                            this._unreadWhileScrolledUp
                                ? 'New messages ↓'
                                : 'Paused ↓',
                            style: this._unreadWhileScrolledUp
                                ? Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.white)
                                : Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
