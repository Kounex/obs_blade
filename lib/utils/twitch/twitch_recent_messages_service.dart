import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/utils/twitch/twitch_irc_sidecar.dart';

/// Community-run history service Chatterino uses for scrollback on join
/// (`recent-messages.robotty.de`, see `docs/chatterino-comparison.md`).
/// Anonymous, no auth. Returns raw IRC lines, parsed here into the same
/// [ChatMessageEvent] shape EventSub delivers so backfilled rows render
/// through the unchanged row widget.
class TwitchRecentMessagesService {
  static const String kBaseUrl =
      'https://recent-messages.robotty.de/api/v2/recent-messages';

  final http.Client _client;

  /// Test seam for stores built without an explicit service (widget
  /// tests construct many [TwitchChatStore]s) — when set, the default
  /// constructor path uses this client instead of real HTTP.
  static http.Client? debugDefaultClient;

  TwitchRecentMessagesService({http.Client? client})
    : _client = client ?? debugDefaultClient ?? http.Client();

  /// Up to [limit] most recent chat messages of [channelLogin], oldest
  /// first. Moderated messages (deleted / timed out / banned) are dropped
  /// server-side so history never resurrects removed content. Throws on
  /// transport / service errors — backfill is best-effort, the caller
  /// swallows.
  Future<List<ChatMessageEvent>> fetch(
    String channelLogin, {
    int limit = 100,
  }) async {
    final uri = Uri.parse('$kBaseUrl/${Uri.encodeComponent(channelLogin)}')
        .replace(
          queryParameters: {
            'limit': '$limit',
            'hide_moderation_messages': 'true',
            'hide_moderated_messages': 'true',
          },
        );
    final response = await this._client.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'recent-messages ${response.statusCode}: ${response.body}',
      );
    }
    final body = json.decode(response.body) as Map<String, dynamic>;
    final lines = body['messages'];
    if (lines is! List) return const <ChatMessageEvent>[];
    return [
      for (final line in lines)
        if (line is String) ?parseIrcPrivmsgToChatMessage(line),
    ];
  }
}

/// IRCv3 tag-value unescaping (`\s` space, `\:` semicolon, `\\`, `\r`,
/// `\n`).
String unescapeIrcTagValue(String value) {
  if (!value.contains(r'\')) return value;
  final out = StringBuffer();
  for (var i = 0; i < value.length; i++) {
    final c = value[i];
    if (c != r'\' || i == value.length - 1) {
      if (c != r'\') out.write(c);
      continue;
    }
    i++;
    out.write(switch (value[i]) {
      's' => ' ',
      ':' => ';',
      r'\' => r'\',
      'r' => '\r',
      'n' => '\n',
      final other => other,
    });
  }
  return out.toString();
}

/// Parse one tagged `PRIVMSG` line into a [ChatMessageEvent] (null for
/// anything else — CLEARCHAT, USERNOTICE, untagged lines). `emotes=` tag
/// ranges become emote fragments (indices are UTF-16-independent code
/// point offsets per the IRC spec), `@login` tokens become mention
/// fragments, `/me` actions are unwrapped.
ChatMessageEvent? parseIrcPrivmsgToChatMessage(String line) {
  if (!line.startsWith('@')) return null;
  final space = line.indexOf(' ');
  if (space <= 1) return null;
  final tags = parseIrcTags(line.substring(1, space));
  final rest = line.substring(space + 1);

  /// `:nick!user@host PRIVMSG #channel :text`
  final match = RegExp(
    r'^:([^!\s]+)(?:![^\s]+)? PRIVMSG #(\S+) :(.*)$',
    dotAll: true,
  ).firstMatch(rest);
  if (match == null) return null;
  final id = tags['id'];
  final userId = tags['user-id'];
  final roomId = tags['room-id'];
  if (id == null || id.isEmpty || userId == null || roomId == null) {
    return null;
  }
  final login = match.group(1)!;
  var text = match.group(3)!;
  if (text.startsWith('\u0001ACTION ') && text.endsWith('\u0001')) {
    text = text.substring(8, text.length - 1);
  }

  final displayName = unescapeIrcTagValue(tags['display-name'] ?? '');
  final color = tags['color'];

  final replyParentId = tags['reply-parent-msg-id'];
  ChatMessageReply? reply;
  if (replyParentId != null && replyParentId.isNotEmpty) {
    reply = ChatMessageReply(
      parentMessageId: replyParentId,
      parentMessageBody: unescapeIrcTagValue(
        tags['reply-parent-msg-body'] ?? '',
      ),
      parentUserId: tags['reply-parent-user-id'] ?? '',
      parentUserName: unescapeIrcTagValue(
        tags['reply-parent-display-name'] ?? '',
      ),
      parentUserLogin: tags['reply-parent-user-login'] ?? '',
      threadMessageId: tags['reply-thread-parent-msg-id'] ?? replyParentId,
      threadUserId: tags['reply-thread-parent-user-id'] ?? '',
      threadUserName: unescapeIrcTagValue(
        tags['reply-thread-parent-display-name'] ??
            tags['reply-thread-parent-user-login'] ??
            '',
      ),
      threadUserLogin: tags['reply-thread-parent-user-login'] ?? '',
    );
  }

  final sentMs = int.tryParse(tags['tmi-sent-ts'] ?? '');

  return ChatMessageEvent(
    broadcasterUserId: roomId,
    chatterUserId: userId,
    chatterUserLogin: login,
    chatterUserName: displayName.isEmpty ? login : displayName,
    messageId: id,
    message: ChatMessageText(
      text: text,
      fragments: _fragments(text, tags['emotes'] ?? ''),
    ),
    color: color == null || color.isEmpty ? null : color,
    badges: _badges(tags['badges'] ?? '', tags['badge-info'] ?? ''),
    messageType: tags['msg-id'] == 'user-intro' ? 'user_intro' : 'text',
    reply: reply,
    receivedAt: sentMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(sentMs, isUtc: true),
    isFirstMessage: tags['first-msg'] == '1',
    isHistorical: true,
  );
}

/// `badges=subscriber/24,moderator/1` + `badge-info=subscriber/26`.
List<ChatMessageBadge> _badges(String badges, String badgeInfo) {
  if (badges.isEmpty) return const <ChatMessageBadge>[];
  final info = <String, String>{};
  for (final entry in badgeInfo.split(',')) {
    final slash = entry.indexOf('/');
    if (slash > 0) info[entry.substring(0, slash)] = entry.substring(slash + 1);
  }
  return [
    for (final entry in badges.split(','))
      if (entry.indexOf('/') > 0)
        ChatMessageBadge(
          setId: entry.substring(0, entry.indexOf('/')),
          id: entry.substring(entry.indexOf('/') + 1),
          info: info[entry.substring(0, entry.indexOf('/'))] ?? '',
        ),
  ];
}

final RegExp _kMention = RegExp(r'@(\w{1,25})');

/// Split [text] into text / emote / mention fragments. `emotes=` is
/// `id:start-end,start-end/id2:start-end` in code-point offsets.
List<ChatMessageFragment> _fragments(String text, String emotesTag) {
  final runes = text.runes.toList();
  final ranges = <({int start, int end, String id})>[];
  if (emotesTag.isNotEmpty) {
    for (final emote in emotesTag.split('/')) {
      final colon = emote.indexOf(':');
      if (colon <= 0) continue;
      final id = emote.substring(0, colon);
      for (final range in emote.substring(colon + 1).split(',')) {
        final dash = range.indexOf('-');
        final start = int.tryParse(range.substring(0, dash < 0 ? 0 : dash));
        final end = int.tryParse(range.substring(dash + 1));
        if (dash < 0 || start == null || end == null) continue;
        if (start < 0 || end >= runes.length || end < start) continue;
        ranges.add((start: start, end: end, id: id));
      }
    }
    ranges.sort((a, b) => a.start.compareTo(b.start));
  }

  final fragments = <ChatMessageFragment>[];
  void addText(String chunk) {
    if (chunk.isEmpty) return;
    var cursor = 0;
    for (final m in _kMention.allMatches(chunk)) {
      final before = m.start == 0 ? '' : chunk[m.start - 1];
      if (before.isNotEmpty && RegExp(r'\w').hasMatch(before)) continue;
      if (m.start > cursor) {
        fragments.add(
          ChatMessageFragment(
            type: 'text',
            text: chunk.substring(cursor, m.start),
          ),
        );
      }
      final login = m.group(1)!;
      fragments.add(
        ChatMessageFragment(
          type: 'mention',
          text: m.group(0)!,
          mention: ChatFragmentMention(
            userId: '',
            userLogin: login.toLowerCase(),
            userName: login,
          ),
        ),
      );
      cursor = m.end;
    }
    if (cursor < chunk.length) {
      fragments.add(
        ChatMessageFragment(type: 'text', text: chunk.substring(cursor)),
      );
    }
  }

  var cursor = 0;
  for (final range in ranges) {
    if (range.start < cursor) continue;
    addText(String.fromCharCodes(runes.sublist(cursor, range.start)));
    fragments.add(
      ChatMessageFragment(
        type: 'emote',
        text: String.fromCharCodes(runes.sublist(range.start, range.end + 1)),
        emote: ChatFragmentEmote(id: range.id),
      ),
    );
    cursor = range.end + 1;
  }
  addText(String.fromCharCodes(runes.sublist(cursor)));
  return fragments;
}
