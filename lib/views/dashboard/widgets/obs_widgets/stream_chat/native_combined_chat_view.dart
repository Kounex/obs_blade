import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/hive_builder.dart';
import 'package:obs_blade/stores/views/combined_chat.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/chat_system_notice.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_notification.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

import '../../../../../models/enums/chat_type.dart';
import 'chat_notice_visibility.dart';
import 'chat_tombstone.dart';
import 'chat_type_brand.dart';
import 'dialogs/chat_user_card_sheet.dart';
import 'dialogs/kick_user_card_sheet.dart';
import 'dialogs/mod_action_sheet.dart';
import 'dialogs/youtube_user_card_sheet.dart';
import 'kick_chat_message_row.dart';
import 'kick_chat_notice_visibility.dart';
import 'native_chat_appearance.dart';
import 'native_chat_chrome.dart';
import 'pinned_chat_banner.dart';
import 'twitch_chat_message_row.dart';
import 'twitch_chat_notification_row.dart';
import 'youtube_chat_message_row.dart';

/// Read-only merged timeline of the "My chats" sources
/// ([CombinedChatStore.timeline]). Every row is rendered by its platform's
/// own row widget behind a small brand-colored platform icon; long-press
/// offers Copy only (writing / mod land in a later wave), author taps open
/// the platform's user card.
class NativeCombinedChatView extends StatefulWidget {
  const NativeCombinedChatView({super.key});

  @override
  State<NativeCombinedChatView> createState() => _NativeCombinedChatViewState();
}

class _NativeCombinedChatViewState extends State<NativeCombinedChatView> {
  final ScrollController _scrollController = ScrollController();
  final ChatRowParity _rowParity = ChatRowParity();

  bool _pinnedToBottom = true;
  bool _unreadWhileScrolledUp = false;
  int _unreadCount = 0;
  int _lastRenderedCount = 0;

  /// Identity of the newest rendered item — the merged view sits at its
  /// cap most of the time, so the tail changing is the arrival signal.
  String? _lastRenderedNewest;

  /// Row under the open Copy sheet (hold wash).
  String? _actionTargetKey;

  CombinedChatStore get _store => GetIt.instance<CombinedChatStore>();

  @override
  void initState() {
    super.initState();
    this._scrollController.addListener(this._onScroll);
  }

  @override
  void dispose() {
    this._scrollController.dispose();
    super.dispose();
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

  Future<void> _openCopy(
    String key, {
    required String authorName,
    required String text,
  }) async {
    this.setState(() => this._actionTargetKey = key);
    try {
      await showMessageActionSheet(
        this.context,
        authorName: authorName,
        messageText: text,
      );
    } finally {
      if (this.mounted) this.setState(() => this._actionTargetKey = null);
    }
  }

  /// Stick-to-bottom bookkeeping, same contract as the platform views:
  /// jump while pinned, count unread while scrolled up.
  void _trackArrivals(List<CombinedItem> items) {
    final newest = items.isEmpty ? null : items.last.key;
    final changed =
        items.length != this._lastRenderedCount ||
        newest != this._lastRenderedNewest;
    if (this._pinnedToBottom) {
      this._unreadWhileScrolledUp = false;
      this._unreadCount = 0;
      if (changed) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          this._jumpToBottomIfPossible();
        });
      }
    } else if (changed) {
      final grown = items.length - this._lastRenderedCount;
      final added = grown > 0
          ? grown
          : (newest != this._lastRenderedNewest ? 1 : 0);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (this.mounted) {
          setState(() {
            this._unreadWhileScrolledUp = true;
            this._unreadCount += added;
          });
        }
      });
    }
    this._lastRenderedCount = items.length;
    this._lastRenderedNewest = newest;
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        /// Emote catalogs resolve non-reactively inside the rows — this
        /// read makes the list rebuild once they land.
        // ignore: unused_local_variable
        final emoteCatalogVersion =
            GetIt.instance<ThirdPartyEmoteStore>().catalogVersion;
        final items = this._store.timeline;
        final sources = this._store.mySources;

        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                sources.isEmpty
                    ? 'No chats to combine yet.'
                    : 'Waiting for messages from '
                          '${sources.map((s) => s.platform.text).join(', ')}…',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          );
        }

        this._trackArrivals(items);

        final twitch = GetIt.instance<TwitchChatStore>();
        final kick = GetIt.instance<KickChatStore>();
        final twitchPin = sources.any((s) => s.platform == ChatType.Twitch)
            ? twitch.pinnedMessage
            : null;
        final kickPin = sources.any((s) => s.platform == ChatType.Kick)
            ? kick.pinnedMessage
            : null;

        final timeline = HiveBuilder<dynamic>(
          hiveKey: HiveKeys.Settings,
          rebuildKeys: const [
            SettingsKeys.TwitchChatTextSize,
            SettingsKeys.TwitchChatEmoteSize,
            SettingsKeys.TwitchChatMessageSpacing,
            SettingsKeys.TwitchChatMessageSeparators,
            SettingsKeys.TwitchChatThirdPartyEmotes,
            SettingsKeys.ChatShowTimestamps,
            SettingsKeys.ChatAlternateRows,
            SettingsKeys.ChatReadableNameColors,
            SettingsKeys.ChatHighlightSelfMention,
            SettingsKeys.ChatHighlightKeywords,
            ...ChatFilterSettings.keys,
            SettingsKeys.TwitchChatNoticeSubs,
            SettingsKeys.TwitchChatNoticeStreaks,
            SettingsKeys.TwitchChatNoticeRaids,
            SettingsKeys.TwitchChatNoticeAnnouncements,
            SettingsKeys.TwitchChatNoticeBitsBadge,
            SettingsKeys.TwitchChatNoticeCharity,
            SettingsKeys.TwitchChatNoticeModiversary,
            SettingsKeys.TwitchChatNoticeOther,
            SettingsKeys.TwitchChatNoticeFirstMessage,
            SettingsKeys.KickChatNoticeSubs,
            SettingsKeys.KickChatNoticeHosts,
            SettingsKeys.KickChatThirdPartyEmotes,
            SettingsKeys.KickChatBadges,
          ],
          builder: (context, settingsBox, child) {
            final visible = combinedVisibleItems(
              items,
              filters: ChatFilterSettings.of(settingsBox),
              twitchNoticeVisible: (type) =>
                  isChatNoticeTypeVisible(settingsBox, type),
              kickNoticeVisible: (id) =>
                  isKickChatNoticeVisible(settingsBox, id),
            );
            final historyDivider = chatHistoryDividerIndex([
              for (final item in visible) combinedItemIsHistorical(item),
            ]);
            final separators = NativeChatAppearance.separators(settingsBox);
            final tinted = NativeChatAppearance.alternateRows(settingsBox)
                ? this._rowParity.assign([for (final item in visible) item.key])
                : null;

            return Stack(
              children: [
                ListView.separated(
                  controller: this._scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  itemCount: visible.length,
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
                    final item = visible[index];
                    Widget row = CombinedSourceRow(
                      platform: item.platform,
                      child: this._rowFor(context, item, settingsBox),
                    );
                    if (tinted != null) {
                      row = chatAlternateRow(context, tinted[index], row);
                    }
                    return index == historyDivider
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ChatHistoryDivider(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              row,
                            ],
                          )
                        : row;
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

        return CombinedPinStack(
          pins: [
            if (twitchPin != null)
              CombinedPin(
                platform: ChatType.Twitch,
                messageId: twitchPin.messageId,
                senderName: twitchPin.senderUserName,
                text: twitchPin.message.text,
              ),
            if (kickPin != null)
              CombinedPin(
                platform: ChatType.Kick,
                messageId: kickPin.id,
                senderName: kickPin.authorName,
                text: kickPin.content,
              ),
          ],
          child: timeline,
        );
      },
    );
  }

  Widget _rowFor(BuildContext context, CombinedItem item, dynamic settings) {
    final payload = item.payload;
    final highlighted = this._actionTargetKey == item.key;
    switch (payload) {
      case ChatSystemNotice():
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            'Chat was cleared by a moderator',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      case ChatNotificationNotice():
        return TwitchChatNotificationRow(
          event: payload.event,
          settingsBox: settings,
          onAuthorTap: () => showChatUserCardSheet(
            context,
            userId: payload.event.chatterUserId,
          ),
        );
      case ChatMessageEvent():
        final twitch = GetIt.instance<TwitchChatStore>();
        final tombstone = twitch.tombstoneInfo(payload.messageId);
        final deleted = twitch.isMessageDeleted(payload.messageId);
        return TwitchChatMessageRow(
          event: payload,
          settingsBox: settings,
          isDeleted: deleted,
          deletedMarker: tombstone == null
              ? ' -Deleted'
              : chatTombstoneMarker(tombstone),
          highlighted: highlighted,
          mentionHexFor: twitch.chatterColor,
          selfDisplayNames: [twitch.user?.login, twitch.user?.displayName],
          onAuthorTap: () =>
              showChatUserCardSheet(context, userId: payload.chatterUserId),
          onMentionTap: (userId) =>
              showChatUserCardSheet(context, userId: userId),
          onMessageLongPress: deleted
              ? null
              : () => this._openCopy(
                  item.key,
                  authorName: payload.chatterUserName,
                  text: payload.message.text,
                ),
        );
      case YouTubeChatMessage():
        final channelId = payload.authorChannelId;
        return YouTubeChatMessageRow(
          message: payload,
          settingsBox: settings,
          highlighted: highlighted,
          selfDisplayNames: [
            GetIt.instance<YouTubeChatStore>().selfChannelTitle,
          ],
          onAuthorTap: channelId == null
              ? null
              : () => showYouTubeUserCardSheet(
                  context,
                  channelId: channelId,
                  fallbackName: payload.authorName,
                  fallbackAvatarUrl: payload.authorProfileImageUrl,
                ),
          onMessageLongPress: payload.isTombstoned || payload.copyText.isEmpty
              ? null
              : () => this._openCopy(
                  item.key,
                  authorName: payload.authorName ?? 'YouTube',
                  text: payload.copyText,
                ),
        );
      case KickChatMessage():
        final kick = GetIt.instance<KickChatStore>();
        final authorId = payload.authorId;
        final system = payload.type == KickChatMessageType.system;
        return KickChatMessageRow(
          message: payload,
          settingsBox: settings,
          broadcasterId: kick.channelInfo?.userId?.toString(),
          selfDisplayNames: [kick.selfUsername],
          highlighted: highlighted,
          onAuthorTap: authorId == null || system
              ? null
              : () => showKickUserCardSheet(
                  context,
                  userId: authorId,
                  fallbackName: payload.authorName,
                ),
          onMessageLongPress: payload.isTombstoned || system
              ? null
              : () => this._openCopy(
                  item.key,
                  authorName: payload.authorName,
                  text: payload.content,
                ),
        );
    }
    return const SizedBox.shrink();
  }
}

/// Whether [item] is backfilled history (dimmed, before the divider).
bool combinedItemIsHistorical(CombinedItem item) => switch (item.payload) {
  final ChatMessageEvent event => event.isHistorical,
  final YouTubeChatMessage message => message.isHistorical,
  final KickChatMessage message => message.isHistorical,
  _ => false,
};

/// The rows the combined view renders: shared mute/ignore filters, each
/// platform's notice toggles, and Twitch's announce twin (the body shows
/// on the announcement notice, so the same-id chat message is dropped) —
/// the same rules the platform views apply.
List<CombinedItem> combinedVisibleItems(
  List<CombinedItem> items, {
  required ChatFilterSettings filters,
  required bool Function(String noticeType) twitchNoticeVisible,
  required bool Function(String messageId) kickNoticeVisible,
}) {
  final announceBodyIds = <String>{
    for (final item in items)
      if (item.payload case final ChatNotificationNotice notice
          when chatNoticeChrome(notice.event.noticeType).color ==
                  ChatNoticeColorSeed.announce &&
              (notice.event.message?.text.trim().isNotEmpty ?? false))
        notice.event.messageId,
  };
  return [
    for (final item in items)
      if (switch (item.payload) {
        final ChatNotificationNotice notice => twitchNoticeVisible(
          notice.event.noticeType,
        ),
        final ChatMessageEvent event =>
          !announceBodyIds.contains(event.messageId) &&
              !filters.hides([
                event.chatterUserLogin,
                event.chatterUserName,
              ], event.message.text),
        final YouTubeChatMessage message => !filters.hides(
          [message.authorName],
          message.snippet.textMessageDetails?.messageText ??
              message.displayText ??
              '',
        ),
        final KickChatMessage message =>
          kickNoticeVisible(message.id) &&
              (message.type == KickChatMessageType.system ||
                  !filters.hides([
                    message.sender?.username,
                    message.sender?.slug,
                  ], message.content)),
        _ => true,
      })
        item,
  ];
}

/// Row wash alpha per platform brand color - light enough that zebra
/// rows, highlights and name colors still read on top of it.
const double kCombinedRowTintAlpha = 0.07;

/// A merged-timeline row: a brand-colored rail on the leading edge, a
/// light platform tint over the whole row and a contained platform badge
/// in front of the row — a square tile, unlike the round role/sub badges
/// users carry, so the source never reads as one of theirs. Screen readers
/// hear "from Twitch" etc.
class CombinedSourceRow extends StatelessWidget {
  final ChatType platform;
  final Widget child;

  const CombinedSourceRow({
    super.key,
    required this.platform,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final brand =
        this.platform.brandColor ?? Theme.of(context).colorScheme.secondary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: brand.withValues(alpha: kCombinedRowTintAlpha),
        border: Border(left: BorderSide(color: brand, width: 3.0)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3.0, right: AppSpacing.xs),
              child: CombinedPlatformBadge(platform: this.platform),
            ),
            Expanded(child: this.child),
          ],
        ),
      ),
    );
  }
}

/// The source platform as a small filled tile: brand-colored square with
/// the platform glyph in a contrasting color.
class CombinedPlatformBadge extends StatelessWidget {
  final ChatType platform;
  final double size;

  const CombinedPlatformBadge({
    super.key,
    required this.platform,
    this.size = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    final brand =
        this.platform.brandColor ?? Theme.of(context).colorScheme.secondary;

    /// Kick's neon green needs a dark glyph; Twitch purple / YouTube red a
    /// light one.
    final glyph = ThemeData.estimateBrightnessForColor(brand) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Semantics(
      label: 'from ${this.platform.text}',
      child: Container(
        key: Key('combined-row-icon-${this.platform.name}'),
        width: this.size,
        height: this.size,
        decoration: BoxDecoration(
          color: brand,
          borderRadius: BorderRadius.circular(AppRadius.sm / 2),
        ),
        alignment: Alignment.center,
        child: Icon(this.platform.icon, size: this.size * 0.66, color: glyph),
      ),
    );
  }
}

/// One source's pinned message in the combined view.
class CombinedPin {
  final ChatType platform;
  final String messageId;
  final String senderName;
  final String text;

  const CombinedPin({
    required this.platform,
    required this.messageId,
    required this.senderName,
    required this.text,
  });
}

/// Stacks one [PinnedChatBanner] per source over [child] — each with its
/// platform icon and its own tuck / restore state. Banners nest (each
/// floats over the next), offset downwards so they never overlap.
class CombinedPinStack extends StatelessWidget {
  final List<CombinedPin> pins;
  final Widget child;

  const CombinedPinStack({super.key, required this.pins, required this.child});

  /// Vertical step between stacked banners / tucked pins (the collapsed
  /// banner's height plus a gap).
  static const double kStackStep = 48.0;

  @override
  Widget build(BuildContext context) {
    Widget current = this.child;
    for (var i = this.pins.length - 1; i >= 0; i--) {
      final pin = this.pins[i];
      current = PinnedChatBanner(
        key: ValueKey('combined-pin-${pin.platform.name}'),
        messageId: pin.messageId,
        senderName: pin.senderName,
        text: pin.text,
        topOffset: i * kStackStep,
        leading: Icon(
          pin.platform.icon,
          size: 14.0,
          color: pin.platform.brandColor,
        ),
        child: current,
      );
    }
    return current;
  }
}
