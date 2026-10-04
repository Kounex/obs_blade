import 'dart:async';
import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:mobx/mobx.dart';

import '../../types/enums/hive_keys.dart';
import '../../utils/general_helper.dart';
import '../../utils/youtube/youtube_emoji.dart';
import '../../utils/youtube/youtube_standard_emojis.dart';

part 'youtube_emojis.g.dart';

/// Where learned emojis and the recently used list live: one untyped box
/// of JSON strings (no TypeID / adapter, `docs/persistence-risk.md`).
abstract class YouTubeEmojiPersistence {
  Future<void> open();
  Iterable<YouTubeEmoji> load();
  List<String> loadRecent();
  Future<void> put(YouTubeEmoji emoji);
  Future<void> remove(String id);
  Future<void> putRecent(List<String> ids);
}

class HiveYouTubeEmojiPersistence implements YouTubeEmojiPersistence {
  static const String _recentKey = '#recent';
  Box<String>? _box;

  @override
  Future<void> open() async {
    this._box ??= await Hive.openBox<String>(HiveKeys.YouTubeEmojis.name);
  }

  @override
  Iterable<YouTubeEmoji> load() sync* {
    final box = this._box;
    if (box == null) return;
    for (final key in box.keys) {
      if (key == _recentKey) continue;
      try {
        final emoji = YouTubeEmoji.fromJson(json.decode(box.get(key)!));
        if (emoji != null) yield emoji;
      } catch (_) {}
    }
  }

  @override
  List<String> loadRecent() {
    try {
      final raw = this._box?.get(_recentKey);
      final list = raw == null ? null : json.decode(raw);
      return list is List ? list.whereType<String>().toList() : [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> put(YouTubeEmoji emoji) async =>
      this._box?.put(emoji.id, json.encode(emoji.toJson()));

  @override
  Future<void> remove(String id) async => this._box?.delete(id);

  @override
  Future<void> putRecent(List<String> ids) async =>
      this._box?.put(_recentKey, json.encode(ids));
}

class MemoryYouTubeEmojiPersistence implements YouTubeEmojiPersistence {
  final Map<String, YouTubeEmoji> emojis = {};
  List<String> recent = [];

  @override
  Future<void> open() async {}

  @override
  Iterable<YouTubeEmoji> load() => this.emojis.values;

  @override
  List<String> loadRecent() => List.of(this.recent);

  @override
  Future<void> put(YouTubeEmoji emoji) async => this.emojis[emoji.id] = emoji;

  @override
  Future<void> remove(String id) async => this.emojis.remove(id);

  @override
  Future<void> putRecent(List<String> ids) async => this.recent = List.of(ids);
}

/// An unknown code waits this long before the chat page is read - a
/// burst of messages is one read
const Duration kYouTubeEmojiUnknownDebounce = Duration(seconds: 4);

class YouTubeEmojiStore = _YouTubeEmojiStore with _$YouTubeEmojiStore;

/// YouTube live-chat emojis - the standard set everyone can use and
/// channels' member emojis. The Data API only sends `:code:` text; images
/// come from the bundled standard set and from the stream's web chat page
/// (`/live_chat?v=`, quota-free), learned when a chat attaches and when a
/// message carries a code we don't know yet (that page holds the recent
/// messages, so it has the image). Learned emojis stay on the device.
abstract class _YouTubeEmojiStore with Store {
  /// A chat page is read at most this often per stream
  static const Duration learnInterval = Duration(minutes: 2);

  static const int maxRecent = 24;

  /// Member emojis kept on the device (oldest learned go first)
  static const int maxMemberEmojis = 1500;

  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0 Safari/537.36';

  final http.Client _client;
  final DateTime Function() _clock;
  final YouTubeEmojiPersistence _persistence;

  _YouTubeEmojiStore({
    http.Client? client,
    DateTime Function()? clock,
    YouTubeEmojiPersistence? persistence,
  }) : _client = client ?? http.Client(),
       _clock = clock ?? DateTime.now,
       _persistence = persistence ?? HiveYouTubeEmojiPersistence() {
    for (final emoji in kYouTubeStandardEmojis) {
      this._add(YouTubeEmoji.fromStandard(emoji));
    }
  }

  /// `:code:` → emoji (every code of every emoji)
  final ObservableMap<String, YouTubeEmoji> _byCode = ObservableMap();

  /// Emoji id → emoji, insertion order = learned order
  final Map<String, YouTubeEmoji> _byId = {};

  final ObservableList<String> _recent = ObservableList();

  /// Bumped when emojis were added - the picker reads it
  @observable
  int revision = 0;

  final Map<String, DateTime> _learnedAt = {};
  final Set<String> _learning = {};
  final Map<String, Timer> _pending = {};
  bool _initialized = false;

  void _add(YouTubeEmoji emoji) {
    this._byId[emoji.id] = emoji;
    for (final code in emoji.codes) {
      this._byCode[code] = emoji;
    }
  }

  /// Restore what was learned before. Safe to call twice.
  Future<void> init() async {
    if (this._initialized) return;
    this._initialized = true;
    try {
      await this._persistence.open();
      runInAction(() {
        for (final emoji in this._persistence.load()) {
          this._add(emoji);
        }
        this._recent.addAll(this._persistence.loadRecent());
        this._capMembers();
        this.revision++;
      });
    } catch (e) {
      GeneralHelper.logFailure('YouTube emojis: could not open storage', e);
    }
  }

  /// The emoji written as [code] (with its colons), if known. Reactive.
  YouTubeEmoji? lookup(String code) => this._byCode[code];

  /// YouTube's standard set, A-Z
  List<YouTubeEmoji> get standard {
    this.revision;
    return [
      for (final emoji in this._byId.values)
        if (emoji.isStandard) emoji,
    ]..sort((a, b) => a.code.toLowerCase().compareTo(b.code.toLowerCase()));
  }

  /// Member emojis of the channel [ownerChannelId] seen so far, A-Z
  List<YouTubeEmoji> membersOf(String? ownerChannelId) {
    this.revision;
    if (ownerChannelId == null) return const [];
    return [
      for (final emoji in this._byId.values)
        if (emoji.ownerChannelId == ownerChannelId) emoji,
    ]..sort((a, b) => a.code.toLowerCase().compareTo(b.code.toLowerCase()));
  }

  /// Recently picked, newest first
  List<YouTubeEmoji> get recent => [
    for (final id in this._recent) ?this._byId[id],
  ];

  @action
  void used(YouTubeEmoji emoji) {
    this._recent
      ..remove(emoji.id)
      ..insert(0, emoji.id);
    if (this._recent.length > maxRecent) {
      this._recent.removeRange(maxRecent, this._recent.length);
    }
    unawaited(this._persistence.putRecent(List.of(this._recent)));
  }

  /// A message of stream [videoId] arrived: a `:code:` we can't draw
  /// yet makes the store read that stream's chat page (soon, once per
  /// burst, at most every [learnInterval]).
  void noteText(String text, {required String? videoId}) {
    if (videoId == null || !text.contains(':')) return;
    final unknown = kYouTubeEmojiCodePattern
        .allMatches(text)
        .any((match) => this._byCode[match.group(0)!] == null);
    if (!unknown || this._pending.containsKey(videoId)) return;
    this._pending[videoId] = Timer(kYouTubeEmojiUnknownDebounce, () {
      this._pending.remove(videoId);
      unawaited(this.learn(videoId));
    });
  }

  /// Read the chat page of [videoId] and keep every custom emoji on it.
  /// Rate-limited per stream ([learnInterval]); failures are logged and
  /// leave the codes as text.
  Future<void> learn(String videoId) async {
    final now = this._clock();
    final last = this._learnedAt[videoId];
    if (last != null && now.difference(last) < learnInterval) return;
    if (!this._learning.add(videoId)) return;
    this._learnedAt[videoId] = now;
    try {
      final response = await this._client
          .get(
            Uri.https('www.youtube.com', '/live_chat', {
              'v': videoId,
              'is_popout': '1',
            }),
            headers: const {
              'User-Agent': _userAgent,
              'Cookie': 'SOCS=CAI; CONSENT=YES+1',
              'Accept-Language': 'en-US',
            },
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      this.addAll(parseYouTubeEmojis(response.body));
    } catch (e) {
      GeneralHelper.logFailure('YouTube emojis: chat page read failed', e);
    } finally {
      this._learning.remove(videoId);
    }
  }

  /// Keep [emojis] (new or changed ones are stored).
  @action
  void addAll(Iterable<YouTubeEmoji> emojis) {
    var changed = false;
    for (final emoji in emojis) {
      final known = this._byId[emoji.id];
      if (known != null &&
          known.imageBase == emoji.imageBase &&
          known.codes.length == emoji.codes.length) {
        continue;
      }
      this._add(emoji);
      unawaited(this._persistence.put(emoji));
      changed = true;
    }
    if (!changed) return;
    this._capMembers();
    this.revision++;
  }

  void _capMembers() {
    final members = [
      for (final emoji in this._byId.values)
        if (!emoji.isStandard) emoji,
    ];
    if (members.length <= maxMemberEmojis) return;
    for (final emoji in members.take(members.length - maxMemberEmojis)) {
      this._byId.remove(emoji.id);
      unawaited(this._persistence.remove(emoji.id));
      for (final code in emoji.codes) {
        if (this._byCode[code]?.id == emoji.id) this._byCode.remove(code);
      }
    }
  }

  void dispose() {
    for (final timer in this._pending.values) {
      timer.cancel();
    }
    this._pending.clear();
  }
}
