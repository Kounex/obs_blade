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
import 'package:obs_blade/utils/chat_highlight_helper.dart';
import 'package:obs_blade/utils/chat_mute_helper.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import 'dialogs/mod_action_sheet.dart';
import 'dialogs/youtube_mod_action_sheet.dart';
import 'dialogs/youtube_user_card_sheet.dart';
import 'native_chat_appearance.dart';
import 'native_chat_chrome.dart';
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

  /// Messages that arrived since scrolling up — shown inline on the pill
  /// (`"3 new messages ↓"`). Resets whenever [_unreadWhileScrolledUp]
  /// clears.
  int _unreadCount = 0;

  /// Message targeted by the open mod sheet (gray wash while sheet is up).
  String? _modTargetMessageId;

  YouTubeChatStore get _store => GetIt.instance<YouTubeChatStore>();

  Future<void> _openModActions(String messageId) async {
    final index = this._store.messages.indexWhere(
      (message) => message.id == messageId,
    );
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

  /// Read-only long-press (not a moderator/signed out): Copy only — there
  /// is nothing to reply with here (YouTube reads work signed-out).
  Future<void> _openReadOnlyActions(String messageId) async {
    final index = this._store.messages.indexWhere(
      (message) => message.id == messageId,
    );
    if (index < 0) return;
    final message = this._store.messages[index];
    this.setState(() => this._modTargetMessageId = messageId);
    try {
      await showMessageActionSheet(
        this.context,
        authorName: message.authorName ?? 'this user',
        messageText: message.copyText,
      );
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
        this._unreadCount = 0;
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
      this._unreadCount = 0;
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 17.0,
                        fontWeight: FontWeight.w700,
                      ),
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
          this._unreadCount = 0;
          if (countChanged) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              this._jumpToBottomIfPossible();
            });
          }
        } else if (countChanged) {
          final added = items.length - this._lastRenderedCount;
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (this.mounted) {
              setState(() {
                this._unreadWhileScrolledUp = true;
                if (added > 0) this._unreadCount += added;
              });
            }
          });
        }
        this._lastRenderedCount = items.length;

        /// Signed-in users get the mod long-press — YouTube has no cheap
        /// mod lookup, so a non-mod's action 403s into the snackbar
        /// (plan §7). Signed-out/read-only viewers still get a
        /// Copy-only long-press via [_openReadOnlyActions].
        final canModerate = this._store.canWrite;

        /// Appearance toggles re-render in place (shared keys with the
        /// Twitch engine — the appearance options sheet is reused as-is).
        return HiveBuilder<dynamic>(
          hiveKey: HiveKeys.Settings,
          rebuildKeys: const [
            SettingsKeys.TwitchChatTextSize,
            SettingsKeys.TwitchChatMessageSpacing,
            SettingsKeys.TwitchChatMessageSeparators,
            SettingsKeys.ChatHighlightSelfMention,
            SettingsKeys.ChatHighlightKeywords,
            SettingsKeys.ChatMuteWords,
          ],
          builder: (context, settingsBox, child) {
            final separators = NativeChatAppearance.separators(settingsBox);
            final muteWords = parseChatHighlightKeywords(
              settingsBox.get(
                SettingsKeys.ChatMuteWords.name,
                defaultValue: '',
              ),
            );
            final visibleItems = items
                .where(
                  (message) => !chatContentIsMuted(
                    message.snippet.textMessageDetails?.messageText ??
                        message.displayText ??
                        '',
                    muteWords,
                  ),
                )
                .toList();
            return Stack(
              children: [
                ListView.separated(
                  controller: this._scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  itemCount: visibleItems.length,
                  separatorBuilder: (context, index) => separators
                      ? Divider(
                          height: 1.0,
                          thickness: 0.5,
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.35),
                        )
                      : const SizedBox.shrink(),
                  itemBuilder: (context, index) {
                    final message = visibleItems[index];
                    final channelId = message.authorChannelId;
                    return YouTubeChatMessageRow(
                      key: ValueKey(message.id),
                      message: message,
                      settingsBox: settingsBox,
                      selfDisplayNames: [this._store.selfChannelTitle],
                      highlighted: this._modTargetMessageId == message.id,
                      onMessageLongPress: message.isTombstoned
                          ? null
                          : (canModerate
                                ? () => this._openModActions(message.id)
                                : (message.copyText.isNotEmpty
                                      ? () => this._openReadOnlyActions(
                                          message.id,
                                        )
                                      : null)),
                      onAuthorTap: channelId == null
                          ? null
                          : () => showYouTubeUserCardSheet(
                              context,
                              channelId: channelId,
                              fallbackName: message.authorName,
                              fallbackAvatarUrl: message.authorProfileImageUrl,
                            ),
                    );
                  },
                ),
                if (!this._pinnedToBottom)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: AppSpacing.sm,
                    child: Center(
                      child: NativeChatScrollPill(
                        hasNewMessages: this._unreadWhileScrolledUp,
                        newMessageCount: this._unreadCount,
                        onTap: this._resumePinnedToBottom,
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
