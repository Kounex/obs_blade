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
import 'dialogs/kick_mod_action_sheet.dart';
import 'dialogs/kick_user_card_sheet.dart';
import 'dialogs/mod_action_sheet.dart';
import 'dialogs/youtube_mod_action_sheet.dart';
import 'dialogs/youtube_user_card_sheet.dart';
import 'kick_chat_message_row.dart';
import 'kick_chat_notice_visibility.dart';
import 'native_chat_appearance.dart';
import 'native_chat_chrome.dart';
import 'pinned_chat_banner.dart';
import 'twitch_chat_message_row.dart';
import 'twitch_chat_notification_row.dart';
import 'youtube_chat_message_row.dart';

/// Merged timeline of the combined chat's sources
/// ([CombinedChatStore.timeline]). Every row is rendered by its platform's
/// own row widget behind a small brand-colored platform icon. Long-press
/// opens that platform's own sheet — the mod sheet where the account may
/// moderate, else Copy (+ Reply on Twitch / Kick when it may write);
/// actions run on the platform store, which the combo points at the
/// row's channel. Author taps open the platform's user card.
class NativeCombinedChatView extends StatefulWidget {
  /// Fired after a sheet's Reply sets the target — the host focuses the
  /// input (whose target chip locks to the reply's platform).
  final VoidCallback? onReplyTargetSet;

  const NativeCombinedChatView({super.key, this.onReplyTargetSet});

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

  /// Row under the open action sheet (hold wash).
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

  /// Runs [open] with [key]'s row washed as the sheet's target.
  Future<void> _withTarget(String key, Future<void> Function() open) async {
    this.setState(() => this._actionTargetKey = key);
    try {
      await open();
    } finally {
      if (this.mounted) this.setState(() => this._actionTargetKey = null);
    }
  }

  void _replyTo(Object payload) {
    this._store.setReplyTarget(payload);
    this.widget.onReplyTargetSet?.call();
  }

  /// Twitch: the mod sheet when moderating the source channel, else Copy
  /// (+ Reply with write access) — same split as the Twitch view.
  Future<void> _openTwitchActions(String key, ChatMessageEvent event) {
    final twitch = GetIt.instance<TwitchChatStore>();
    final onReply = twitch.canWriteChat ? () => this._replyTo(event) : null;
    return this._withTarget(
      key,
      () => twitch.canModerateSelectedChannel
          ? showModActionSheet(this.context, event, onReply: onReply)
          : showMessageActionSheet(
              this.context,
              authorName: event.chatterUserName,
              messageText: event.message.text,
              userListName: event.chatterUserLogin,
              onReply: onReply,
            ),
    );
  }

  /// YouTube: the mod sheet when signed in (a non-mod's action fails
  /// honestly into its snackbar), else Copy. No replies on YouTube.
  Future<void> _openYouTubeActions(String key, YouTubeChatMessage message) {
    final youTube = GetIt.instance<YouTubeChatStore>();
    return this._withTarget(
      key,
      () => youTube.canWrite
          ? showYouTubeModActionSheet(this.context, message)
          : showMessageActionSheet(
              this.context,
              authorName: message.authorName ?? 'YouTube',
              messageText: message.copyText,
            ),
    );
  }

  /// Kick: reply / mod sheet when signed in (honest 403 for non-mods),
  /// else Copy.
  Future<void> _openKickActions(String key, KickChatMessage message) {
    final kick = GetIt.instance<KickChatStore>();
    return this._withTarget(
      key,
      () => kick.canWrite
          ? showKickModActionSheet(
              this.context,
              message,
              onReply: () => this._replyTo(message),
            )
          : showMessageActionSheet(
              this.context,
              authorName: message.authorName,
              messageText: message.content,
            ),
    );
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
        final sources = this._store.activeSources;

        if (items.isEmpty) {
          final placeholder = Center(
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

          /// The strip stays up on a quiet chat — who's live and the
          /// jump into a platform matter most exactly then.
          return sources.isEmpty
              ? placeholder
              : Column(
                  children: [
                    CombinedSourceStrip(sources: sources),
                    Expanded(child: placeholder),
                  ],
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

                  /// No horizontal inset: each row's platform wash runs
                  /// edge to edge and pads its own content.
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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

        final pinned = CombinedPinStack(
          pins: [
            if (twitchPin != null)
              CombinedPin(
                platform: ChatType.Twitch,
                messageId: twitchPin.messageId,
                senderName: twitchPin.senderUserName,
                text: twitchPin.message.text,
                onUnpin: twitch.canModerateSelectedChannel
                    ? twitch.unpinMessage
                    : null,
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
        return Column(
          children: [
            CombinedSourceStrip(sources: sources),
            Expanded(child: pinned),
          ],
        );
      },
    );
  }

  Widget _rowFor(BuildContext context, CombinedItem item, dynamic settings) {
    final payload = item.payload;
    final highlighted = this._actionTargetKey == item.key;
    final badge = CombinedPlatformBadge(
      key: Key('combined-row-icon-${item.platform.name}'),
      platform: item.platform,
    );
    switch (payload) {
      case ChatSystemNotice():
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              badge,
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Chat was cleared by a moderator',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      case ChatNotificationNotice():

        /// Notices have their own icon row — the badge sits in front,
        /// aligned with the notice's first line.
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xs,
                right: AppSpacing.xs,
              ),
              child: badge,
            ),
            Expanded(
              child: TwitchChatNotificationRow(
                event: payload.event,
                settingsBox: settings,
                onAuthorTap: () => showChatUserCardSheet(
                  context,
                  userId: payload.event.chatterUserId,
                ),
              ),
            ),
          ],
        );
      case ChatMessageEvent():
        final twitch = GetIt.instance<TwitchChatStore>();
        final tombstone = twitch.tombstoneInfo(payload.messageId);
        final deleted = twitch.isMessageDeleted(payload.messageId);
        return TwitchChatMessageRow(
          event: payload,
          settingsBox: settings,
          leading: badge,
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
              : () => this._openTwitchActions(item.key, payload),
        );
      case YouTubeChatMessage():
        final channelId = payload.authorChannelId;
        return YouTubeChatMessageRow(
          message: payload,
          settingsBox: settings,
          leading: badge,
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
              : () => this._openYouTubeActions(item.key, payload),
        );
      case KickChatMessage():
        final kick = GetIt.instance<KickChatStore>();
        final authorId = payload.authorId;
        final system = payload.type == KickChatMessageType.system;
        return KickChatMessageRow(
          message: payload,
          settingsBox: settings,
          leading: badge,
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
              : () => this._openKickActions(item.key, payload),
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

/// A merged-timeline row's platform wash: a light brand tint across the
/// full row width and a brand stripe on the list's left edge (the list
/// has no horizontal padding, so both reach the window edge). The
/// platform badge itself sits inline in the row's first line (the rows'
/// `leading` slot) so it shares the name's middle line.
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: this.child,
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
    this.size = 16.0,
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

  /// Set when the account may unpin (Twitch mods).
  final Future<bool> Function()? onUnpin;

  const CombinedPin({
    required this.platform,
    required this.messageId,
    required this.senderName,
    required this.text,
    this.onUnpin,
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
        onUnpin: pin.onUnpin,
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

/// Slim strip over the merged timeline: one chip per source — platform
/// badge, channel, chat-connection dot, and a LIVE · viewers tag while
/// that streamer is on air ([CombinedChatStore.liveSources]). Tapping a chip jumps into that
/// platform's own chat on the combo's channel
/// ([CombinedChatStore.focus]) — a "↩ Combined" strip there leads back.
class CombinedSourceStrip extends StatelessWidget {
  final List<CombinedSource> sources;

  const CombinedSourceStrip({super.key, required this.sources});

  @override
  Widget build(BuildContext context) {
    final store = GetIt.instance<CombinedChatStore>();
    final statusColors =
        Theme.of(context).extension<AppStatusColors>() ??
        AppStatusColors.standard;
    final muted = Theme.of(context).textTheme.bodySmall?.color;

    /// Own Observer: the dots and LIVE tags change without the timeline
    /// changing, so the parent list's rebuilds can't be relied on.
    return Observer(
      builder: (context) {
        final live = store.liveSources;
        return SizedBox(
          height: 36.0,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            children: [
              for (final source in this.sources)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Pressable(
                    key: Key('combined-focus-${source.platform.name}'),
                    haptic: true,
                    onTap: source.unavailable
                        ? null
                        : () => store.focus(source.platform),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: (source.platform.brandColor ?? muted!)
                            .withValues(alpha: kCombinedRowTintAlpha * 2),
                        borderRadius: AppRadius.pill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CombinedPlatformBadge(
                            platform: source.platform,
                            size: 14.0,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            source.label,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            key: Key(
                              'combined-chat-dot-${source.platform.name}',
                            ),
                            width: 6.0,
                            height: 6.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: switch (store.sourceStatus[source
                                  .platform]) {
                                CombinedSourceStatus.live => statusColors.live,
                                CombinedSourceStatus.connecting =>
                                  statusColors.warning,
                                CombinedSourceStatus.error ||
                                CombinedSourceStatus.needsSetup =>
                                  statusColors.unreachable,
                                _ => muted,
                              },
                            ),
                          ),
                          if (live.containsKey(source.platform)) ...[
                            const SizedBox(width: AppSpacing.xs),
                            NativeChatStatusChip.live(
                              key: Key('combined-live-${source.platform.name}'),
                              color: statusColors.live,
                              viewerCount: live[source.platform],
                            ),
                          ],
                        ],
                      ),
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
