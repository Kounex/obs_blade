import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/hive_builder.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/classes/twitch/chat_system_notice.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_notification.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import 'chat_notice_chrome.dart';
import 'chat_notice_visibility.dart';
import 'chat_tombstone.dart';
import 'dialogs/chat_user_card_sheet.dart';
import 'dialogs/mod_action_sheet.dart';
import 'native_chat_appearance.dart';
import 'twitch_chat_message_row.dart';
import 'twitch_chat_notification_row.dart';

/// Native read-only Twitch chat. Lives in the same dashboard slot the
/// WebView chat uses — driven by [TwitchChatStore]'s message buffer.
class NativeTwitchChatView extends StatefulWidget {
  const NativeTwitchChatView({super.key});

  @override
  State<NativeTwitchChatView> createState() => _NativeTwitchChatViewState();
}

class _NativeTwitchChatViewState extends State<NativeTwitchChatView> {
  final ScrollController _scrollController = ScrollController();

  /// Pinned to the newest message until the user scrolls up
  bool _pinnedToBottom = true;
  bool _unreadWhileScrolledUp = false;
  int _lastRenderedCount = 0;

  /// Ids of deleted messages whose actor reveal is expanded — toggled by
  /// tapping the row. Survives lifecycle rebuilds; dead ids (evicted,
  /// logged out) never render, so the set stays session-bounded.
  final Set<String> _expandedDeletedIds = <String>{};

  /// Message targeted by the open mod sheet (gray wash while sheet is up).
  /// Hold wash during the press is local to the row — do not setState here
  /// or username/link [Pressable]s get disposed mid-gesture.
  String? _modTargetMessageId;

  TwitchChatStore get _store => GetIt.instance<TwitchChatStore>();

  Future<void> _openModActions(ChatMessageEvent event) async {
    this.setState(() => this._modTargetMessageId = event.messageId);
    try {
      await showModActionSheet(this.context, event);
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
  /// so we never race a post-frame stick-to-bottom jump (that combo could
  /// leave pixels past [maxScrollExtent] and throw every rebuild).
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
    /// Layout may still be settling after the chip disappears — one
    /// follow-up jump is enough (not a per-rebuild schedule).
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

        /// Tracked so the visible list rebuilds once when third-party
        /// emote catalogs land (pop-in) — rows resolve tokens
        /// non-reactively at build time, so this read is the only
        /// rebuild trigger.
        // ignore: unused_local_variable
        final emoteCatalogVersion =
            GetIt.instance<ThirdPartyEmoteStore>().catalogVersion;

        /// Tracked so lifecycle changes (tombstones, /clear banner,
        /// chat notifications) rebuild the list — notices live in a
        /// plain List, so this version read is their only trigger.
        // ignore: unused_local_variable
        final lifecycleVersion = this._store.lifecycleVersion;

        /// Include notices — an announce-only buffer must not stick on
        /// "waiting for messages…" until a PRIVMSG arrives.
        final items = this._store.messagesWithNotices();
        final timelineEmpty = items.isEmpty;

        if (connection == TwitchChatConnectionState.connecting &&
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
                  'Connecting to Twitch chat…',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        if (connection == TwitchChatConnectionState.failed &&
            timelineEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Text(
                    this._store.chatError ?? 'Could not connect to Twitch chat',
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
                'Connected — waiting for messages…',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          );
        }


        /// Stick to bottom only when the timeline length changes while
        /// pinned — not on every Observer rebuild (lifecycle/emote/etc.),
        /// which used to schedule a jump every frame and could race the
        /// pause-chip resume path into an overscrolled, exception-spamming
        /// state. Tombstones don't change the count (no jump / unread);
        /// a /clear banner does.
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

        /// Toggle changes re-filter badges and re-render emote tokens in
        /// place; row-level Observers pick up badge catalog arrivals
        /// (emote catalog arrivals ride the outer Observer's
        /// catalogVersion read above).
        return HiveBuilder<dynamic>(
          hiveKey: HiveKeys.Settings,
          rebuildKeys: const [
            SettingsKeys.TwitchChatBadgeBroadcaster,
            SettingsKeys.TwitchChatBadgeModerator,
            SettingsKeys.TwitchChatBadgeVip,
            SettingsKeys.TwitchChatBadgeSubscriber,
            SettingsKeys.TwitchChatBadgeFounder,
            SettingsKeys.TwitchChatBadgeBits,
            SettingsKeys.TwitchChatBadgeOther,
            SettingsKeys.TwitchChatThirdPartyEmotes,
            SettingsKeys.TwitchChatTextSize,
            SettingsKeys.TwitchChatEmoteSize,
            SettingsKeys.TwitchChatMessageSpacing,
            SettingsKeys.TwitchChatMessageSeparators,
            SettingsKeys.TwitchChatNoticeSubs,
            SettingsKeys.TwitchChatNoticeStreaks,
            SettingsKeys.TwitchChatNoticeRaids,
            SettingsKeys.TwitchChatNoticeAnnouncements,
            SettingsKeys.TwitchChatNoticeBitsBadge,
            SettingsKeys.TwitchChatNoticeCharity,
            SettingsKeys.TwitchChatNoticeModiversary,
            SettingsKeys.TwitchChatNoticeOther,
            SettingsKeys.TwitchChatNoticeFirstMessage,
          ],
          builder: (context, settingsBox, child) {
            final separators = NativeChatAppearance.separators(settingsBox);
            /// Announce bodies render on the banner — drop the twin
            /// `channel.chat.message` with the same id so it doesn't show
            /// as a plain line under the notice.
            final announceBodyIds = <String>{
              for (final item in items)
                if (item is ChatNotificationNotice &&
                    chatNoticeChrome(item.event.noticeType).color ==
                        ChatNoticeColorSeed.announce &&
                    item.event.message != null &&
                    item.event.message!.text.trim().isNotEmpty)
                  item.event.messageId,
            };
            final visibleItems = items.where((item) {
              if (item is ChatNotificationNotice) {
                return isChatNoticeTypeVisible(
                  settingsBox,
                  item.event.noticeType,
                );
              }
              if (item is ChatMessageEvent &&
                  announceBodyIds.contains(item.messageId)) {
                return false;
              }
              return true;
            }).toList();
            final chatMessageIds = {
              for (final item in visibleItems)
                if (item is ChatMessageEvent) item.messageId,
            };
            String? mentionHexFor(String userId) =>
                this._store.chatterColor(userId);
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
                          color: Theme.of(context)
                              .dividerColor
                              .withValues(alpha: 0.35),
                        )
                      : const SizedBox.shrink(),
                  itemBuilder: (context, index) {
                  final item = visibleItems[index];
                  if (item is ChatSystemNotice) {
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            child: Text(
                              'Chat was cleared by a moderator',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                    );
                  }
                  if (item is ChatNotificationNotice) {
                    final next = index + 1 < visibleItems.length
                        ? visibleItems[index + 1]
                        : null;
                    final announce = chatNoticeChrome(item.event.noticeType)
                            .color ==
                        ChatNoticeColorSeed.announce;
                    /// Announce chrome is self-contained (Twitch doesn't
                    /// paint the next PRIVMSG with announce rails). Other
                    /// notices may continue the accent onto the chatter's
                    /// following line.
                    final continues = !announce &&
                        next is ChatMessageEvent &&
                        next.chatterUserId == item.event.chatterUserId;
                    final attachedOnNotice = item.event.message != null &&
                        item.event.message!.text.trim().isNotEmpty;
                    return TwitchChatNotificationRow(
                      event: item.event,
                      settingsBox: settingsBox,
                      accentContinues: continues,
                      /// Prefer the body on the announce banner; hide the
                      /// duplicate `channel.chat.message` with the same id
                      /// below. Other notices keep the prior split layout.
                      showAttachedMessage: announce
                          ? attachedOnNotice
                          : !chatMessageIds.contains(item.event.messageId),
                      mentionHexFor: mentionHexFor,
                      onAuthorTap: () => showChatUserCardSheet(
                        context,
                        userId: item.event.chatterUserId,
                      ),
                      onMentionTap: (userId) => showChatUserCardSheet(
                        context,
                        userId: userId,
                      ),
                    );
                  }
                  final event = item as ChatMessageEvent;
                  final actor =
                      this._store.deletedMessageActor(event.messageId);
                  final deleted =
                      this._store.isMessageDeleted(event.messageId);
                  final tombstone = this._store.tombstoneInfo(event.messageId);
                  Color? accent;
                  if (index > 0) {
                    final prev = visibleItems[index - 1];
                    if (prev is ChatNotificationNotice &&
                        prev.event.chatterUserId == event.chatterUserId) {
                      final seed =
                          chatNoticeChrome(prev.event.noticeType).color;
                      /// Announce → next chat must not keep an orange strip.
                      if (seed != ChatNoticeColorSeed.announce) {
                        accent = chatNoticeAccentColor(seed);
                      }
                    }
                  }

                  return TwitchChatMessageRow(
                    event: event,
                    settingsBox: settingsBox,
                    isDeleted: deleted,
                    deletedMarker: tombstone == null
                        ? ' —Deleted'
                        : chatTombstoneMarker(tombstone),
                    deletedActor: actor,
                    isDeletedExpanded:
                        this._expandedDeletedIds.contains(event.messageId),
                    accentBarColor: accent,
                    mentionHexFor: mentionHexFor,
                    onDeletedTap: actor == null
                        ? null
                        : () => setState(() {
                              final id = event.messageId;
                              if (!this._expandedDeletedIds.remove(id)) {
                                this._expandedDeletedIds.add(id);
                              }
                            }),

                    onAuthorTap: () => showChatUserCardSheet(
                      context,
                      userId: event.chatterUserId,
                    ),
                    onMentionTap: (userId) => showChatUserCardSheet(
                      context,
                      userId: userId,
                    ),
                    highlighted: this._modTargetMessageId == event.messageId,
                    onMessageLongPress:
                        deleted || !this._store.canModerateSelectedChannel
                            ? null
                            : () => this._openModActions(event),
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
