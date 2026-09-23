import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../models/enums/chat_type.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../stores/views/kick_chat.dart';
import '../../../../../stores/views/twitch_chat.dart';
import '../../../../../stores/views/youtube_chat.dart';
import '../../../../../types/classes/kick/kick_chat_message.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../utils/chat_search_helper.dart';
import '../../../../../utils/modal_handler.dart';
import 'kick_chat_message_row.dart';
import 'native_chat_chrome.dart';
import 'native_chat_text_field.dart';
import 'twitch_chat_message_row.dart';
import 'youtube_chat_message_row.dart';

/// Opens the chat search sheet — the entry behind [NativeChatOptionsSheet]'s
/// "Search chat" row.
void showChatSearchSheet(BuildContext context, {required ChatType chatType}) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      enableDrag: true,
      maxHeightFraction: 0.86,
      builder: (context) => ChatSearchSheet(chatType: chatType),
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

  const ChatSearchSheet({super.key, required this.chatType});

  @override
  State<ChatSearchSheet> createState() => _ChatSearchSheetState();
}

class _ChatSearchSheetState extends State<ChatSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

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
          Text('Search chat', style: nativeChatSheetTitleStyle(context)),
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

    final rows = switch (this.widget.chatType) {
      ChatType.Twitch => this._twitchResults(settingsBox),
      ChatType.Kick => this._kickResults(settingsBox),
      ChatType.YouTube => this._youTubeResults(settingsBox),
      _ => const <Widget>[],
    };

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
            ],
          ),
        ),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  List<Widget> _twitchResults(Box settingsBox) {
    if (!GetIt.instance.isRegistered<TwitchChatStore>()) return const [];
    final store = GetIt.instance<TwitchChatStore>();
    final query = this._query;
    return [
      for (final event in store.messages)
        if (chatSearchMatches(
          query: query,
          author: event.chatterUserName,
          content: event.message.text,
        ))
          TwitchChatMessageRow(
            key: ValueKey('search-${event.messageId}'),
            event: event,
            settingsBox: settingsBox,
          ),
    ];
  }

  List<Widget> _kickResults(Box settingsBox) {
    if (!GetIt.instance.isRegistered<KickChatStore>()) return const [];
    final store = GetIt.instance<KickChatStore>();
    final query = this._query;
    return [
      for (final message in store.messages)
        if (message.type != KickChatMessageType.system &&
            chatSearchMatches(
              query: query,
              author: message.authorName,
              content: message.content,
            ))
          KickChatMessageRow(
            key: ValueKey('search-${message.id}'),
            message: message,
            settingsBox: settingsBox,
          ),
    ];
  }

  List<Widget> _youTubeResults(Box settingsBox) {
    if (!GetIt.instance.isRegistered<YouTubeChatStore>()) return const [];
    final store = GetIt.instance<YouTubeChatStore>();
    final query = this._query;
    return [
      for (final message in store.messages)
        if (chatSearchMatches(
          query: query,
          author: message.authorName ?? '',
          content:
              message.snippet.textMessageDetails?.messageText ??
              message.displayText ??
              '',
        ))
          YouTubeChatMessageRow(
            key: ValueKey('search-${message.id}'),
            message: message,
            settingsBox: settingsBox,
          ),
    ];
  }
}
