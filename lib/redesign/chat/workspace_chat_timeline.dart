import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../stores/views/third_party_emotes.dart';
import '../../stores/views/twitch_badges.dart';
import '../../types/classes/twitch/eventsub/channel_chat_notification.dart';
import '../../views/dashboard/widgets/obs_widgets/stream_chat/chat_notice_visibility.dart';
import '../../views/dashboard/widgets/obs_widgets/stream_chat/chat_tombstone.dart';
import '../../views/dashboard/widgets/obs_widgets/stream_chat/native_chat_appearance.dart';
import '../../views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart';
import '../../views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_notification_row.dart';
import '../../views/dashboard/widgets/obs_widgets/stream_chat/youtube_chat_message_row.dart';
import 'chat_composer_controller.dart';
import 'chat_timeline.dart';

/// Reuses specialized platform rows with explicit catalog/settings dependencies.
/// The host owns account/moderation sheets; no global store lookup lives here.
class WorkspaceChatTimeline extends StatefulWidget {
  const WorkspaceChatTimeline({
    super.key,
    required this.controller,
    required this.settings,
    required this.badges,
    required this.emotes,
    this.onMessageActions,
    this.onUser,
  });
  final ChatComposerController controller;
  final Box settings;
  final TwitchBadgeStore badges;
  final ThirdPartyEmoteStore emotes;
  final ValueChanged<ChatTimelineEntry>? onMessageActions;
  final ValueChanged<String>? onUser;

  @override
  State<WorkspaceChatTimeline> createState() => _WorkspaceChatTimelineState();
}

class _WorkspaceChatTimelineState extends State<WorkspaceChatTimeline> {
  final _scroll = ScrollController();
  final _paused = <ChatConversation, bool>{};
  final _revealed = <(ChatConversation?, String)>{};
  ChatConversation? _lastConversation;
  int _lastCount = -1;
  Object? _lastTail;
  bool _userScrolling = false;
  bool _followScheduled = false;
  int _followGeneration = 0;

  void _setPaused(bool paused) {
    final key = widget.controller.conversation;
    if (key == null) return;
    if ((_paused[key] ?? false) != paused) {
      setState(() => _paused[key] = paused);
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    // A stationary long press can start a native scroll gesture without moving.
    // Only movement claims scroll ownership; a sheet can cancel that gesture
    // before ScrollEnd arrives.
    if (notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle) {
      _userScrolling = true;
    }
    if (_userScrolling &&
        (notification is ScrollUpdateNotification ||
            notification is ScrollEndNotification)) {
      _setPaused(notification.metrics.extentAfter > 32);
    }
    if (notification is ScrollEndNotification) {
      _userScrolling = false;
      _scheduleFollow();
    }
    return false;
  }

  // Lazy row measurement and composer/keyboard changes can alter the extent
  // after the first jump. Follow metric changes only while the user is live;
  // programmatic layout correction must never be mistaken for a manual pause.
  void _scheduleFollow() {
    final key = widget.controller.conversation;
    if (_followScheduled || _userScrolling || (_paused[key] ?? false)) return;
    final generation = _followGeneration;
    _followScheduled = true;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      if (!mounted || generation != _followGeneration) return;
      _followScheduled = false;
      if (key == widget.controller.conversation &&
          !_userScrolling &&
          !(_paused[key] ?? false) &&
          _scroll.hasClients &&
          _scroll.position.hasContentDimensions &&
          _scroll.position.extentAfter > .5) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
    // Metrics arrive after layout; registering a callback alone does not request
    // another frame on a native device once the keyboard animation has settled.
    binding.ensureVisualUpdate();
  }

  void _returnLive() {
    _userScrolling = false;
    _setPaused(false);
    if (_scroll.hasClients && _scroll.position.hasContentDimensions) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
    _scheduleFollow();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => ValueListenableBuilder(
      valueListenable: widget.settings.listenable(),
      builder: (context, _, _) => Observer(
        builder: (context) {
          // Plain emote fragments resolve at row build; catalog arrivals need one
          // parent invalidation. Badge rows observe their injected catalog directly.
          final catalogVersion = widget.emotes.catalogVersion;
          return _timeline(context, catalogVersion);
        },
      ),
    ),
  );

  Widget _timeline(BuildContext context, int catalogVersion) {
    final timeline = widget.controller.timeline;
    final announced = <String>{
      for (final entry in timeline.entries)
        if (entry is TwitchNoticeEntry &&
            chatNoticeChrome(entry.notice.event.noticeType).color ==
                ChatNoticeColorSeed.announce &&
            (entry.notice.event.message?.text.trim().isNotEmpty ?? false))
          entry.notice.event.messageId,
    };
    final entries = timeline.entries
        .where(
          (entry) => switch (entry) {
            TwitchNoticeEntry() => isChatNoticeTypeVisible(
              widget.settings,
              entry.notice.event.noticeType,
            ),
            TwitchMessageEntry() => !announced.contains(
              entry.message.messageId,
            ),
            _ => true,
          },
        )
        .toList();
    final key = widget.controller.conversation;
    final tail = entries.isEmpty
        ? null
        : switch (entries.last) {
            TwitchMessageEntry(:final message) => message.messageId,
            YouTubeMessageEntry(:final message) => message.id,
            TwitchNoticeEntry(:final notice) => notice.event.messageId,
            ChatSystemEntry(:final notice) => (notice.kind, notice.afterSeq),
          };
    final changed =
        key != _lastConversation ||
        entries.length != _lastCount ||
        tail != _lastTail;
    if (key != _lastConversation) {
      _followGeneration++;
      _followScheduled = false;
      _userScrolling = false;
    }
    _lastConversation = key;
    _lastCount = entries.length;
    _lastTail = tail;
    if (changed) _scheduleFollow();
    final pin = timeline.pin;
    return Column(
      children: [
        if (pin != null)
          ExpansionTile(
            key: ValueKey((key, pin.messageId)),
            leading: const Icon(Icons.push_pin_outlined, size: 18),
            title: Text(
              'Pinned · ${pin.senderUserName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(pin.message.text),
              ),
            ],
          ),
        Expanded(
          child: entries.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Waiting for chat messages…'),
                  ),
                )
              : Stack(
                  children: [
                    NotificationListener<ScrollMetricsNotification>(
                      onNotification: (_) {
                        _scheduleFollow();
                        return false;
                      },
                      child: NotificationListener<ScrollNotification>(
                        onNotification: _onScroll,
                        child: ListView.separated(
                          key: PageStorageKey(('native-chat-timeline', key)),
                          controller: _scroll,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          itemCount: entries.length,
                          separatorBuilder: (_, _) =>
                              NativeChatAppearance.separators(widget.settings)
                              ? Divider(
                                  height: 1,
                                  color: Theme.of(context).dividerColor,
                                )
                              : const SizedBox.shrink(),
                          itemBuilder: (context, index) =>
                              _row(context, entries, index),
                        ),
                      ),
                    ),
                    if (_paused[key] ?? false)
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: FilledButton.tonalIcon(
                            onPressed: _returnLive,
                            icon: const Icon(Icons.arrow_downward, size: 18),
                            label: const Text('Return live'),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    List<ChatTimelineEntry> entries,
    int index,
  ) {
    final entry = entries[index];
    switch (entry) {
      case TwitchMessageEntry():
        final event = entry.message;
        final revealKey = (widget.controller.conversation, event.messageId);
        return TwitchChatMessageRow(
          key: ValueKey((
            widget.controller.conversation,
            TwitchMessageEntry,
            event.messageId,
          )),
          event: event,
          settingsBox: widget.settings,
          badgeStore: widget.badges,
          emoteStore: widget.emotes,
          isDeleted: entry.deleted,
          deletedActor: entry.deletedBy,
          deletedMarker: entry.tombstone == null
              ? ' —Deleted'
              : chatTombstoneMarker(entry.tombstone!),
          isDeletedExpanded: _revealed.contains(revealKey),
          onDeletedTap: entry.deletedBy == null
              ? null
              : () => setState(() {
                  if (!_revealed.remove(revealKey)) _revealed.add(revealKey);
                }),
          onAuthorTap: widget.onUser == null
              ? null
              : () => widget.onUser!(event.chatterUserId),
          onMentionTap: widget.onUser,
          onMessageLongPress: entry.deleted
              ? null
              : () => _messageActions(context, entry),
        );
      case TwitchNoticeEntry():
        final event = entry.notice.event;
        return TwitchChatNotificationRow(
          key: ValueKey((
            widget.controller.conversation,
            TwitchNoticeEntry,
            event.messageId,
          )),
          event: event,
          settingsBox: widget.settings,
          badgeStore: widget.badges,
          emoteStore: widget.emotes,
          showAttachedMessage: !entries.any(
            (item) =>
                item is TwitchMessageEntry &&
                item.message.messageId == event.messageId,
          ),
          onAuthorTap: widget.onUser == null
              ? null
              : () => widget.onUser!(event.chatterUserId),
          onMentionTap: widget.onUser,
        );
      case ChatSystemEntry():
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: Text('Chat was cleared')),
        );
      case YouTubeMessageEntry():
        return YouTubeChatMessageRow(
          key: ValueKey((widget.controller.conversation, entry.message.id)),
          message: entry.message,
          settingsBox: widget.settings,
          onMessageLongPress:
              widget.onMessageActions == null || entry.message.isTombstoned
              ? null
              : () => widget.onMessageActions!(entry),
        );
    }
  }

  void _messageActions(BuildContext context, TwitchMessageEntry entry) {
    final conversation = widget.controller.conversation;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: Text('Reply to ${entry.message.chatterUserName}'),
              onTap: () {
                Navigator.pop(sheetContext);
                if (conversation == widget.controller.conversation) {
                  widget.controller.setReply(entry.message);
                }
              },
            ),
            if (widget.onMessageActions != null)
              ListTile(
                leading: const Icon(Icons.more_horiz),
                title: const Text('Message actions'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (conversation == widget.controller.conversation) {
                    widget.onMessageActions!(entry);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
