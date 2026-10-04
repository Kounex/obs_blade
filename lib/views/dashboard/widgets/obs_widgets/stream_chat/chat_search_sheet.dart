import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../models/enums/chat_type.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/base/adaptive_switch.dart';
import '../../../../../stores/views/combined_chat.dart';
import '../../../../../stores/views/kick_chat.dart';
import '../../../../../stores/views/twitch_chat.dart';
import '../../../../../stores/views/youtube_chat.dart';
import '../../../../../types/classes/kick/kick_chat_message.dart';
import '../../../../../types/classes/twitch/eventsub/channel_chat_message.dart';
import '../../../../../types/classes/youtube/youtube_chat_message.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../utils/chat_search_helper.dart';
import '../../../../../utils/modal_handler.dart';
import 'chat_tombstone.dart';
import 'kick_chat_message_row.dart';
import 'native_combined_chat_view.dart' show CombinedPlatformBadge;
import 'native_chat_appearance.dart' show ChatFilterSettings;
import 'native_chat_chrome.dart';
import 'native_chat_text_field.dart';
import 'twitch_chat_message_row.dart';
import 'youtube_chat_message_row.dart';

/// Opens the chat search sheet — the entry behind [NativeChatOptionsSheet]'s
/// "Search chat" row.
/// [onBack] (opened from the options sheet): a back chevron that closes
/// this sheet and calls it.
void showChatSearchSheet(
  BuildContext context, {
  required ChatType chatType,
  VoidCallback? onBack,
}) => ModalHandler.showBaseBottomSheet(
  context: context,
  barrierDismissible: true,
  enableDrag: true,
  maxHeightFraction: 0.86,
  builder: (context) => ChatSearchSheet(chatType: chatType, onBack: onBack),
);

/// Search over the currently buffered chat history (no persistence across
/// app restarts — the buffer is whatever the store still holds). Common
/// to every native engine: a query matches a message's author name or
/// content, case-insensitively ([chatSearchMatches]); matches render with
/// each engine's own message row for full-fidelity look (badges, colors,
/// emotes) - same idiom as [AddChatSheet]'s bounded-height
/// `SingleChildScrollView` list rather than a lazy `ListView.builder`
/// (chat buffers are bounded, so this stays cheap).
class ChatSearchSheet extends StatefulWidget {
  final ChatType chatType;

  /// Back to where it was opened from (the options sheet)
  final VoidCallback? onBack;

  const ChatSearchSheet({super.key, required this.chatType, this.onBack});

  @override
  State<ChatSearchSheet> createState() => _ChatSearchSheetState();
}

class _ChatSearchSheetState extends State<ChatSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  /// Include what the chat hides (ignored users, muted words) - dimmed
  bool _showHidden = false;

  @override
  void dispose() {
    this._controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box(HiveKeys.Settings.name);
    final listMaxHeight = MediaQuery.sizeOf(context).height * 0.6;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          nativeChatSheetDragHandle(context),
          Row(
            children: [
              if (this.widget.onBack case final onBack?)
                Pressable(
                  key: const Key('chat-search-back'),
                  haptic: true,
                  onTap: () {
                    Navigator.of(context).pop();
                    onBack();
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: AppSpacing.sm,
                      top: AppSpacing.md,
                      bottom: AppSpacing.md,
                    ),
                    child: Icon(
                      CupertinoIcons.chevron_back,
                      size: 20.0,
                      color:
                          (Theme.of(context).extension<AppTextColors>() ??
                                  AppTextColors.standard)
                              .highlightText,
                    ),
                  ),
                ),
              Text('Search chat', style: nativeChatSheetTitleStyle(context)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: NativeChatTextField(
              key: const Key('chat-search-field'),
              controller: this._controller,
              onChanged: (value) =>
                  this.setState(() => this._query = value.trim()),
              hintText: 'Search messages or names',
              prefixIcon: const Icon(CupertinoIcons.search, size: 16.0),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 36.0,
                minHeight: 0.0,
              ),
            ),
          ),

          /// Ignored users / muted words stay out of the results like
          /// they stay out of the chat - unless asked for
          Row(
            children: [
              Expanded(
                child: Text(
                  'Show hidden messages',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              BaseAdaptiveSwitch(
                key: const Key('chat-search-show-hidden'),
                value: this._showHidden,
                onChanged: (value) =>
                    this.setState(() => this._showHidden = value),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: listMaxHeight),
            child: SingleChildScrollView(
              child: Observer(
                builder: (_) => this._buildResults(context, settingsBox),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Read an observable up front — the empty-query branch below builds no
  /// rows, which would otherwise leave the [Observer] with nothing
  /// tracked (same fix as [AddChatSheet]'s search results).
  int _bufferedCount() => switch (this.widget.chatType) {
    ChatType.Twitch =>
      GetIt.instance.isRegistered<TwitchChatStore>()
          ? GetIt.instance<TwitchChatStore>().messages.length
          : 0,
    ChatType.Kick =>
      GetIt.instance.isRegistered<KickChatStore>()
          ? GetIt.instance<KickChatStore>().messages.length
          : 0,
    ChatType.YouTube =>
      GetIt.instance.isRegistered<YouTubeChatStore>()
          ? GetIt.instance<YouTubeChatStore>().messages.length
          : 0,
    ChatType.Combined =>
      GetIt.instance.isRegistered<CombinedChatStore>()
          ? GetIt.instance<CombinedChatStore>().timeline.length
          : 0,
    _ => 0,
  };

  Widget _buildResults(BuildContext context, Box settingsBox) {
    this._bufferedCount();
    final textColors =
        Theme.of(context).extension<AppTextColors>() ?? AppTextColors.standard;
    if (this._query.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: Text(
            'Type to search the buffered chat history',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: textColors.textTertiary),
          ),
        ),
      );
    }

    this._hiddenMatches = 0;
    final rows = switch (this.widget.chatType) {
      ChatType.Twitch => this._twitchResults(settingsBox),
      ChatType.Kick => this._kickResults(settingsBox),
      ChatType.YouTube => this._youTubeResults(settingsBox),
      ChatType.Combined => this._combinedResults(settingsBox),
      _ => const <Widget>[],
    };
    final hidden = this._hiddenMatches;

    /// "3 hidden in chat - Show" while hidden matches are left out
    final Widget? hiddenHint = hidden > 0 && !this._showHidden
        ? Padding(
            key: const Key('chat-search-hidden-hint'),
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              hidden == 1
                  ? '1 more match is hidden in the chat (ignored user or '
                        'muted word)'
                  : '$hidden more matches are hidden in the chat (ignored '
                        'users or muted words)',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: textColors.textTertiary),
            ),
          )
        : null;

    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: Column(
            children: [
              Icon(
                CupertinoIcons.search,
                size: 28.0,
                color: textColors.textOrnament,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'No matches',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: textColors.textTertiary),
              ),
              ?hiddenHint,
            ],
          ),
        ),
      );
    }

    /// Message rows assume the full row width they get from `ListView` in
    /// the live feed (left-aligned content, self-mention wash spanning
    /// edge to edge) - a plain Column's default center cross-axis would
    /// instead shrink-wrap and center each row.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [...rows, ?hiddenHint],
    );
  }

  /// Matches the chat hides, counted while [_showHidden] is off
  int _hiddenMatches = 0;

  /// A match's row as the search shows it: left out (and counted) when
  /// the chat hides it and "Show hidden" is off, dimmed when it's on
  Widget? _shown(Widget row, {required bool hidden}) {
    if (!hidden) return row;
    if (!this._showHidden) {
      this._hiddenMatches++;
      return null;
    }
    return Opacity(opacity: 0.45, child: row);
  }

  /// What the chat itself hides (ignored users, mute words in hide mode)
  ChatFilterSettings _filters(Box settingsBox) =>
      ChatFilterSettings.of(settingsBox);

  /// A Twitch row with its delete state, like the timelines draw it
  Widget _twitchRow(
    ChatMessageEvent event,
    Box settingsBox,
    String key, {
    Widget? leading,
  }) {
    final store = GetIt.instance<TwitchChatStore>();
    final tombstone = store.tombstoneInfo(event.messageId);
    return TwitchChatMessageRow(
      key: ValueKey(key),
      event: event,
      settingsBox: settingsBox,
      leading: leading,
      isDeleted: store.isMessageDeleted(event.messageId),
      deletedMarker: tombstone == null
          ? ' -Deleted'
          : chatTombstoneMarker(tombstone),
    );
  }

  List<Widget> _twitchResults(Box settingsBox) {
    if (!GetIt.instance.isRegistered<TwitchChatStore>()) return const [];
    final store = GetIt.instance<TwitchChatStore>();
    final query = this._query;
    final filters = this._filters(settingsBox);
    return [
      for (final event in store.messages)
        if (chatSearchMatches(
          query: query,
          author: event.chatterUserName,
          content: event.message.text,
        ))
          ?this._shown(
            this._twitchRow(event, settingsBox, 'search-${event.messageId}'),
            hidden: filters.hides([
              event.chatterUserLogin,
              event.chatterUserName,
            ], event.message.text),
          ),
    ];
  }

  List<Widget> _kickResults(Box settingsBox) {
    if (!GetIt.instance.isRegistered<KickChatStore>()) return const [];
    final store = GetIt.instance<KickChatStore>();
    final query = this._query;
    final filters = this._filters(settingsBox);
    return [
      for (final message in store.messages)
        if (message.type != KickChatMessageType.system &&
            chatSearchMatches(
              query: query,
              author: message.authorName,
              content: message.content,
            ))
          ?this._shown(
            KickChatMessageRow(
              key: ValueKey('search-${message.id}'),
              message: message,
              settingsBox: settingsBox,
            ),
            hidden: filters.hides([
              message.sender?.username,
              message.sender?.slug,
            ], message.content),
          ),
    ];
  }

  List<Widget> _youTubeResults(Box settingsBox) {
    if (!GetIt.instance.isRegistered<YouTubeChatStore>()) return const [];
    final store = GetIt.instance<YouTubeChatStore>();
    final query = this._query;
    final filters = this._filters(settingsBox);
    return [
      for (final message in store.messages)
        if (chatSearchMatches(
          query: query,
          author: message.authorName ?? '',
          content: _youTubeText(message),
        ))
          ?this._shown(
            YouTubeChatMessageRow(
              key: ValueKey('search-${message.id}'),
              message: message,
              settingsBox: settingsBox,
            ),
            hidden: filters.hides([message.authorName], _youTubeText(message)),
          ),
    ];
  }

  static String _youTubeText(YouTubeChatMessage message) =>
      message.snippet.textMessageDetails?.messageText ??
      message.displayText ??
      '';

  /// The combined chat's merged timeline (every platform in the combo,
  /// in time order): its messages that match, each in its platform's row
  /// with the platform badge - as in the combined chat itself.
  List<Widget> _combinedResults(Box settingsBox) {
    if (!GetIt.instance.isRegistered<CombinedChatStore>()) return const [];
    final query = this._query;
    final filters = this._filters(settingsBox);
    final rows = <Widget>[];
    void add(Widget? row) {
      if (row != null) rows.add(row);
    }

    for (final item in GetIt.instance<CombinedChatStore>().timeline) {
      final badge = CombinedPlatformBadge(platform: item.platform);
      switch (item.payload) {
        case final ChatMessageEvent event
            when chatSearchMatches(
              query: query,
              author: event.chatterUserName,
              content: event.message.text,
            ):
          add(
            this._shown(
              this._twitchRow(
                event,
                settingsBox,
                'search-${item.key}',
                leading: badge,
              ),
              hidden: filters.hides([
                event.chatterUserLogin,
                event.chatterUserName,
              ], event.message.text),
            ),
          );
        case final YouTubeChatMessage message
            when chatSearchMatches(
              query: query,
              author: message.authorName ?? '',
              content: _youTubeText(message),
            ):
          add(
            this._shown(
              YouTubeChatMessageRow(
                key: ValueKey('search-${item.key}'),
                message: message,
                settingsBox: settingsBox,
                leading: badge,
              ),
              hidden: filters.hides([
                message.authorName,
              ], _youTubeText(message)),
            ),
          );
        case final KickChatMessage message
            when message.type != KickChatMessageType.system &&
                chatSearchMatches(
                  query: query,
                  author: message.authorName,
                  content: message.content,
                ):
          add(
            this._shown(
              KickChatMessageRow(
                key: ValueKey('search-${item.key}'),
                message: message,
                settingsBox: settingsBox,
                leading: badge,
              ),
              hidden: filters.hides([
                message.sender?.username,
                message.sender?.slug,
              ], message.content),
            ),
          );
        default:
          break;
      }
    }
    return rows;
  }
}
