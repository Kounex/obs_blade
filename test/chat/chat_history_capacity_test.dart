/// Capacity spike, NOT a gate test: how expensive is it to keep chat
/// messages beyond the 500-row live buffer in a separate history (for
/// long per-chatter history in the user card)?
///
/// Run explicitly (skipped by default so the chat gate stays fast):
///   flutter test test/chat/chat_history_capacity_test.dart --run-skipped
///
/// Measures, per platform model + a slim history-record candidate:
/// retained bytes/message (RSS slope across batch sizes), eviction-path
/// churn cost, per-user history query cost (scan vs per-user index), and
/// JSON serialization cost for persistence sizing.
library;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';

/// What a user-card history row actually needs (text-only history; emote
/// re-rendering from text is a separate design question).
class SlimEntry {
  final String id;
  final String authorId;
  final String authorName;
  final DateTime at;
  final String text;

  const SlimEntry({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.at,
    required this.text,
  });

  Map<String, Object?> toJson() => {
    'id': this.id,
    'a': this.authorId,
    'n': this.authorName,
    't': this.at.toIso8601String(),
    'x': this.text,
  };
}

const _words = [
  'LULW', 'GG', 'lets', 'go', 'that', 'was', 'insane', 'clip', 'it', 'POG',
  'no', 'way', 'the', 'boss', 'again', 'reset', 'run', 'pb', 'any%', 'glitch',
  'streamer', 'chat', 'mods', 'emote', ' KEKW', 'raid', 'hype', 'first', 'time',
  'watching', 'from', 'Germany', 'love', 'this', 'game', 'speedrun', 'world',
  'record', 'tonight', 'actually', 'never', 'always', 'true', 'monkaS',
];

const _emoteIds = ['425618', '305954156', '304486301', '28087', '116387'];

String _text(Random rng, int i) {
  final roll = rng.nextDouble();
  final wordCount = roll < 0.4
      ? 1 + rng.nextInt(3)
      : roll < 0.8
      ? 4 + rng.nextInt(9)
      : 13 + rng.nextInt(20);
  final buffer = StringBuffer();
  for (var w = 0; w < wordCount; w++) {
    buffer.write(_words[rng.nextInt(_words.length)]);
    buffer.write(' ');
  }

  /// Unique suffix per message: defeats string sharing so the numbers are
  /// an upper bound (real chats repeat spam, the VM keeps every instance).
  buffer.write('#$i');
  return buffer.toString();
}

class _User {
  final String id;
  final String login;
  final String name;

  const _User(this.id, this.login, this.name);
}

List<_User> _users(int count) => [
  for (var u = 0; u < count; u++)
    _User('1099114$u', 'chatter_$u', 'Chatter $u'),
];

ChatMessageEvent _twitch(Random rng, int i, _User user) {
  final text = _text(rng, i);
  final withEmotes = rng.nextDouble() < 0.3;
  final fragments = <ChatMessageFragment>[
    if (withEmotes)
      for (var e = 0; e < 1 + rng.nextInt(3); e++)
        ChatMessageFragment(
          type: 'emote',
          text: _words[rng.nextInt(_words.length)].trim(),
          emote: ChatFragmentEmote(
            id: _emoteIds[rng.nextInt(_emoteIds.length)],
          ),
        ),
    ChatMessageFragment(type: 'text', text: text),
  ];
  return ChatMessageEvent(
    broadcasterUserId: '71092938',
    chatterUserId: user.id,
    chatterUserLogin: user.login,
    chatterUserName: user.name,
    messageId: 'b8d4f2a0-3c11-4f9a-8bf2-${i.toString().padLeft(12, '0')}',
    message: ChatMessageText(text: text, fragments: fragments),
    color: '#8A2BE2',
    badges: [
      for (var b = 0; b < rng.nextInt(4); b++)
        ChatMessageBadge(
          setId: b == 0 ? 'subscriber' : 'bits',
          id: '${12 + rng.nextInt(80)}',
          info: '',
        ),
    ],
    reply: rng.nextDouble() < 0.05
        ? ChatMessageReply(
            parentMessageId: 'c9e5g3b1-4d22-5ab1-8bf2-001122334455',
            parentMessageBody: 'parent message body $i',
            parentUserId: user.id,
            parentUserName: user.name,
            parentUserLogin: user.login,
            threadMessageId: 'c9e5g3b1-4d22-5ab1-8bf2-001122334455',
            threadUserId: user.id,
            threadUserName: user.name,
            threadUserLogin: user.login,
          )
        : null,
    receivedAt: DateTime.fromMillisecondsSinceEpoch(1759600000000 + i * 700),
  );
}

YouTubeChatMessage _youtube(Random rng, int i, _User user) {
  final text = _text(rng, i);
  return YouTubeChatMessage(
    id: 'LCC.CjgqDQoLYWJjZA$i',
    snippet: YouTubeChatMessageSnippet(
      type: YouTubeChatMessageType.textMessage,
      liveChatId: 'Cg0KC2F1dG9fbGl2ZQ',
      authorChannelId: 'UC9ya0yO8n3aB7y8kZa${user.id}',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1759600000000 + i * 700),
      hasDisplayContent: true,
      displayMessage: text,
      textMessageDetails: YouTubeTextMessageDetails(messageText: text),
    ),
    authorDetails: YouTubeChatAuthorDetails(
      channelId: 'UC9ya0yO8n3aB7y8kZa${user.id}',
      channelUrl: 'https://www.youtube.com/channel/UC9ya0yO8n3aB7y8kZa${user.id}',
      displayName: user.name,
      profileImageUrl:
          'https://yt4.ggpht.com/ytc/${user.login}-s88-c-k-c0x00ffffff-no-rj',
      isChatSponsor: rng.nextDouble() < 0.1,
      isChatModerator: rng.nextDouble() < 0.02,
      isVerified: rng.nextDouble() < 0.01,
    ),
  );
}

KickChatMessage _kick(Random rng, int i, _User user) => KickChatMessage(
  id: 'b7a3f1c0-2d44-4e5b-9a$i',
  chatroomId: 512345,
  content: _text(rng, i),
  createdAt: DateTime.fromMillisecondsSinceEpoch(1759600000000 + i * 700),
  sender: KickChatSender(
    id: int.parse(user.id),
    username: user.name,
    slug: user.login,
    identity: KickChatIdentity(
      color: '#53FC18',
      badgesV2: [
        for (var b = 0; b < rng.nextInt(3); b++)
          KickChatBadgeV2(
            name: b == 0 ? 'Subscriber' : 'Early Supporter',
            badgeType: b == 0 ? 'subscriber' : 'early_supporter',
            imageUrl:
                'https://files.kick.com/badges/${b == 0 ? 'subscriber' : 'early'}.png',
          ),
      ],
    ),
  ),
);

/// Allocate + release ~256 MB of junk to push the VM through a GC, so the
/// RSS readings reflect retained data rather than pre-GC noise.
void _gcChurn() {
  for (var i = 0; i < 32; i++) {
    final junk = List<int>.filled(1 << 20, i);
    if (junk.length == -1) print(junk);
  }
}

int _rss() {
  _gcChurn();
  return ProcessInfo.currentRss;
}

String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

void main() {
  group(
    'chat history capacity spike',
    skip: 'capacity spike - run explicitly with --run-skipped',
    () {
      test('retained memory: full models vs slim records', () {
        final rng = Random(42);
        final users = _users(2000);
        final out = StringBuffer('\n== retained memory (RSS slope) ==\n');

        void slope<T>(
          String label,
          T Function(int i) make,
          List<int> sizes,
        ) {
          List<T>? retained = <T>[];
          var prevRss = _rss();
          var prevN = 0;
          final line = StringBuffer(label.padRight(24));
          for (final n in sizes) {
            for (var i = prevN; i < n; i++) {
              retained!.add(make(i));
            }
            final rss = _rss();
            final perMsg = (rss - prevRss) / (n - prevN);
            line.write(
              '${n >= 1000 ? '${n ~/ 1000}k' : n}: +${_mb(rss - prevRss)}MB '
              '(${perMsg.toStringAsFixed(0)}B/msg)  ',
            );
            prevRss = rss;
            prevN = n;
          }
          out.writeln(line);
          // Keep alive past the measurement, then release.
          if (retained!.length == -1) print(retained.length);
          retained = null;
          _gcChurn();
        }

        slope<ChatMessageEvent>(
          'twitch full model',
          (i) => _twitch(rng, i, users[i % users.length]),
          const [10000, 50000, 100000, 250000],
        );
        slope<YouTubeChatMessage>(
          'youtube full model',
          (i) => _youtube(rng, i, users[i % users.length]),
          const [10000, 50000, 100000, 250000],
        );
        slope<KickChatMessage>(
          'kick full model',
          (i) => _kick(rng, i, users[i % users.length]),
          const [10000, 50000, 100000, 250000],
        );
        slope<SlimEntry>(
          'slim record',
          (i) => SlimEntry(
            id: 'b8d4f2a0-3c11-4f9a-$i',
            authorId: users[i % users.length].id,
            authorName: users[i % users.length].name,
            at: DateTime.fromMillisecondsSinceEpoch(1759600000000 + i * 700),
            text: _text(rng, i),
          ),
          const [10000, 100000, 500000, 1000000],
        );
        print(out);
        expect(ProcessInfo.currentRss, greaterThan(0));
      });

      test('per-user index overhead + query cost (slim records)', () {
        final rng = Random(7);
        final users = _users(2000);
        final out = StringBuffer('\n== per-user index vs scan ==\n');

        for (final n in [100000, 500000]) {
          final flatRssBefore = _rss();
          final flat = <SlimEntry>[
            for (var i = 0; i < n; i++)
              SlimEntry(
                id: 'b8d4f2a0-3c11-4f9a-$i',
                authorId: users[i % users.length].id,
                authorName: users[i % users.length].name,
                at: DateTime.fromMillisecondsSinceEpoch(
                  1759600000000 + i * 700,
                ),
                text: _text(rng, i),
              ),
          ];
          final flatRss = _rss();

          final index = <String, List<SlimEntry>>{};
          for (final e in flat) {
            index.putIfAbsent(e.authorId, () => []).add(e);
          }
          final indexRss = _rss();

          // Query: the last 20 messages of one author, mid-history.
          final target = users[1234].id;
          final scanWatch = Stopwatch()..start();
          var scanned = 0;
          for (var r = 0; r < 5; r++) {
            final matches = <SlimEntry>[];
            for (var i = flat.length - 1; i >= 0 && matches.length < 20; i--) {
              if (flat[i].authorId == target) matches.add(flat[i]);
            }
            scanned = matches.length;
          }
          scanWatch.stop();

          // Worst case: an author with no recent (here: no) messages -
          // the scan walks the whole history.
          final missWatch = Stopwatch()..start();
          for (var r = 0; r < 5; r++) {
            final matches = <SlimEntry>[];
            for (var i = flat.length - 1; i >= 0 && matches.length < 20; i--) {
              if (flat[i].authorId == 'not-in-this-chat') matches.add(flat[i]);
            }
          }
          missWatch.stop();

          final indexWatch = Stopwatch()..start();
          var indexed = 0;
          for (var r = 0; r < 5; r++) {
            final list = index[target]!;
            indexed = list.length >= 20
                ? list.sublist(list.length - 20).length
                : list.length;
          }
          indexWatch.stop();

          out.writeln(
            '${n ~/ 1000}k: flat ${_mb(flatRss - flatRssBefore)}MB, '
            '+index ${_mb(indexRss - flatRss)}MB | '
            'last-20-of-user: scan ${scanWatch.elapsedMicroseconds / 5}us '
            '(worst case ${missWatch.elapsedMicroseconds / 5}us) '
            'vs index ${indexWatch.elapsedMicroseconds / 5}us '
            '($scanned/$indexed found)',
          );
        }
        print(out);
      });

      test('eviction-path churn (live 500 + history sink)', () {
        final rng = Random(13);
        final users = _users(2000);
        final out = StringBuffer('\n== eviction churn ==\n');

        for (final n in [10000, 100000]) {
          final live = Queue<ChatMessageEvent>();
          final history = <String, List<ChatMessageEvent>>{};
          final watch = Stopwatch()..start();
          for (var i = 0; i < n; i++) {
            final message = _twitch(rng, i, users[i % users.length]);
            live.addLast(message);
            if (live.length > 500) {
              final evicted = live.removeFirst();
              history.putIfAbsent(evicted.chatterUserId, () => []).add(evicted);
            }
          }
          watch.stop();
          out.writeln(
            '$n messages through a 500-row buffer + per-user history: '
            '${watch.elapsedMilliseconds}ms total '
            '(${(watch.elapsedMicroseconds / n).toStringAsFixed(1)}us/msg '
            'incl. generation)',
          );
        }
        print(out);
      });

      test('serialization sizing (slim records)', () {
        final rng = Random(21);
        final users = _users(2000);
        final out = StringBuffer('\n== JSON sizing (slim) ==\n');

        for (final n in [10000, 100000]) {
          final entries = [
            for (var i = 0; i < n; i++)
              SlimEntry(
                id: 'b8d4f2a0-3c11-4f9a-$i',
                authorId: users[i % users.length].id,
                authorName: users[i % users.length].name,
                at: DateTime.fromMillisecondsSinceEpoch(
                  1759600000000 + i * 700,
                ),
                text: _text(rng, i),
              ),
          ];
          final encodeWatch = Stopwatch()..start();
          final json = jsonEncode([for (final e in entries) e.toJson()]);
          encodeWatch.stop();
          final decodeWatch = Stopwatch()..start();
          final decoded = jsonDecode(json) as List;
          decodeWatch.stop();
          out.writeln(
            '${n ~/ 1000}k: ${_mb(json.length)}MB '
            '(${(json.length / n).toStringAsFixed(0)}B/entry), '
            'encode ${encodeWatch.elapsedMilliseconds}ms, '
            'decode ${decodeWatch.elapsedMilliseconds}ms '
            '(${decoded.length} entries)',
          );
        }
        out.writeln(
          'note: the full models declare toJson: false - persisting THEM '
          'needs new serializers; the slim record is trivially persistable.',
        );
        print(out);
      });
    },
  );
}
