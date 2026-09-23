import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/hive_builder.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/chat_highlight_helper.dart';
import 'package:obs_blade/utils/chat_mute_helper.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import 'kick_chat_message_row.dart';
import 'kick_chat_notice_visibility.dart';
import 'native_chat_appearance.dart';
import 'native_chat_chrome.dart';

import 'dialogs/kick_mod_action_sheet.dart';
import 'dialogs/kick_user_card_sheet.dart';
import 'dialogs/mod_action_sheet.dart';
import 'pinned_chat_banner.dart';

/// Native Kick chat timeline, driven by [KickChatStore]'s message buffer
/// (anonymous reads — channel resolution + history backfill over REST,
/// live events over Kick's public Pusher socket). Mirrors
/// [NativeYouTubeChatView]'s scroll/pin logic, pause chip and mod
/// long-press: signed-in users get the reply/mod action sheet (Kick has
/// no "am I a mod" lookup — a non-mod's action 403s honestly into the
/// snackbar, docs/kick-chat-audit.md); signed-out/anonymous viewers still
/// get a Copy-only long-press sheet.
class NativeKickChatView extends StatefulWidget {
  /// Fired after the mod sheet's Reply sets the target — the host docks
  /// the input and refocuses its field.
  final VoidCallback? onReplyTargetSet;

  const NativeKickChatView({super.key, this.onReplyTargetSet});

  @override
  State<NativeKickChatView> createState() => _NativeKickChatViewState();
}

class _NativeKickChatViewState extends State<NativeKickChatView> {
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

  KickChatStore get _store => GetIt.instance<KickChatStore>();

  Future<void> _openModActions(String messageId) async {
    final index = this._store.messages.indexWhere(
      (message) => message.id == messageId,
    );
    if (index < 0) return;
    final message = this._store.messages[index];
    this.setState(() => this._modTargetMessageId = messageId);
    try {
      await showKickModActionSheet(
        this.context,
        message,
        onReply: () {
          this._store.setReplyTarget(message);
          this.widget.onReplyTargetSet?.call();
        },
      );
    } finally {
      if (this.mounted) {
        this.setState(() => this._modTargetMessageId = null);
      }
    }
  }

  /// Read-only long-press (not signed in): Copy only — there's nothing to
  /// reply/moderate with here (Kick reads are anonymous).
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
        authorName: message.authorName,
        messageText: message.content,
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

        /// Tracked so the visible list rebuilds once when the 7TV
        /// catalog lands (pop-in) — the row resolves tokens
        /// non-reactively at build time, so this read is the only
        /// rebuild trigger (mirrors the Twitch view's equivalent read).
        // ignore: unused_local_variable
        final emoteCatalogVersion =
            GetIt.instance<ThirdPartyEmoteStore>().catalogVersion;

        /// Reading the observable list tracks it — tombstones mutate
        /// entries in place, so also read the length for the pin logic.
        final items = this._store.messages.toList();
        final timelineEmpty = items.isEmpty;

        if ((connection == KickChatConnectionState.connecting ||
                connection == KickChatConnectionState.reconnecting) &&
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
                  'Connecting to Kick chat…',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        if (connection == KickChatConnectionState.error && timelineEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Text(
                    this._store.chatError ?? 'Could not connect to Kick chat',
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
                /// `offline` = the slug does not resolve — a normal state,
                /// not an error.
                connection == KickChatConnectionState.offline
                    ? 'No chat for this channel - the slug may be wrong or the channel is unavailable.'
                    : 'Connected - waiting for messages…',
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

        /// Signed-in users get the reply/mod long-press — Kick has no
        /// cheap mod lookup, so a non-mod's action 403s into the
        /// snackbar (same honest-403 model as YouTube).
        final canWrite = this._store.canWrite;
        final pinned = this._store.pinnedMessage;

        /// Appearance toggles re-render in place (shared keys with the
        /// Twitch engine — the appearance options sheet is reused as-is).
        return HiveBuilder<dynamic>(
          hiveKey: HiveKeys.Settings,
          rebuildKeys: const [
            SettingsKeys.TwitchChatTextSize,
            SettingsKeys.TwitchChatMessageSpacing,
            SettingsKeys.TwitchChatMessageSeparators,
            SettingsKeys.KickChatNoticeSubs,
            SettingsKeys.KickChatNoticeHosts,
            SettingsKeys.KickChatThirdPartyEmotes,
            SettingsKeys.KickChatBadges,
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
            final visibleItems = items.where((message) {
              if (!isKickChatNoticeVisible(settingsBox, message.id)) {
                return false;
              }
              if (message.type != KickChatMessageType.system &&
                  chatContentIsMuted(message.content, muteWords)) {
                return false;
              }
              return true;
            }).toList();
            final timeline = Stack(
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
                    final authorId = message.authorId;
                    return KickChatMessageRow(
                      key: ValueKey(message.id),
                      message: message,
                      settingsBox: settingsBox,
                      broadcasterId: this._store.channelInfo?.userId
                          ?.toString(),
                      selfDisplayNames: [this._store.selfUsername],
                      highlighted: this._modTargetMessageId == message.id,
                      onMessageLongPress:
                          message.isTombstoned ||
                              message.type == KickChatMessageType.system
                          ? null
                          : (canWrite
                                ? () => this._openModActions(message.id)
                                : () => this._openReadOnlyActions(message.id)),
                      onAuthorTap:
                          authorId == null ||
                              message.type == KickChatMessageType.system
                          ? null
                          : () => showKickUserCardSheet(
                              context,
                              userId: authorId,
                              fallbackName: message.authorName,
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
            if (pinned == null) {
              return Column(children: [Expanded(child: timeline)]);
            }
            return PinnedChatBanner(
              messageId: pinned.id,
              senderName: pinned.authorName,
              text: pinned.content,
              child: timeline,
            );
          },
        );
      },
    );
  }
}
