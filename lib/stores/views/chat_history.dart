library;

import 'dart:collection';

import 'package:hive_ce/hive.dart';

import '../../types/enums/hive_keys.dart';
import '../../types/enums/settings_keys.dart';

/// Session chat history beyond the live buffers' 500-row cap: messages
/// evicted from the Twitch / YouTube / Kick buffers because of the cap
/// (and only then - not on /clear, not on logout wipes) land here as
/// full-fidelity models, so the user card can answer "what has this
/// chatter said" further back than the ~500 rows the timeline keeps.
///
/// In-memory only, never persisted (chat content never touches Hive);
/// session-scoped by design. One global FIFO cap summed across all
/// platforms — a quiet session next to a busy one lends it its room.
/// The cap is user-configurable (the native chat options' Chat history
/// page) between [kChatHistoryCapMin] and [kChatHistoryCapMax], defaults
/// to [kChatHistoryCapDefault], and persists as
/// [SettingsKeys.ChatHistoryCap]; [ChatHistoryStore.cap] applies a change
/// at runtime. Consumed only by the user-card sheets; chat search and
/// the timeline deliberately don't read it.
///
/// Erase semantics: the platform stores call [clearChannel] when a
/// channel leaves the user's list, [clearPlatform] on logout / invalid
/// auth / session reset (Kick signs out without wiping its buffers -
/// anonymous reads - so it wipes no history either), never on channel
/// switch / stream rollover / backgrounding. `/clear` deliberately does
/// NOT erase: the buffer's /clear UX is content-visible tombstones, so
/// the history mirrors it - rows evicted after a /clear carry that
/// tombstone into their snapshot.
///
/// Memory: ~1.0-1.4 KB per retained message (the capacity spike in
/// `test/chat/chat_history_capacity_test.dart`) — see
/// [chatHistoryEstimatedMb]: ~64 MB worst case at the 50k default,
/// ~256 MB at the 200k maximum, bounded and session-scoped either way.
const int kChatHistoryCapMin = 10000;
const int kChatHistoryCapDefault = 50000;
const int kChatHistoryCapMax = 200000;

/// Retained bytes per message used for the options page's worst-case
/// estimate: the spike's 1.0-1.4 KB range, at 1.25 KB (1280 bytes).
const int kChatHistoryBytesPerMessage = 1280;

/// Estimated worst-case memory for [cap] retained full models, rounded
/// decimal MB: ~13 MB at 10k, ~64 MB at 50k, ~128 MB at 100k, ~256 MB
/// at 200k.
int chatHistoryEstimatedMb(int cap) =>
    (cap * kChatHistoryBytesPerMessage / 1e6).round();

enum ChatHistoryPlatform { twitch, youtube, kick }

/// Deleted/tombstone state frozen when a message left its live buffer.
/// Twitch keeps that state in store-side maps that eviction forgets, so
/// it must be captured at feed time; YouTube/Kick carry `isTombstoned`
/// on the model itself (snapshotted anyway for a uniform seam).
class ChatHistoryTombstone {
  final bool isDeleted;

  /// Marker copy for the dimmed row (` —Deleted`, ` —Timed out (10m)`).
  final String marker;

  /// Display name of the deleting moderator when known (Twitch delete
  /// actions only; purges and /clear never carry one).
  final String? actor;

  const ChatHistoryTombstone({
    required this.isDeleted,
    this.marker = ' -Deleted',
    this.actor,
  });
}

/// One retained message: the full platform model (`ChatMessageEvent` /
/// `YouTubeChatMessage` / `KickChatMessage` in [message]) plus where it
/// was said and its feed-time tombstone snapshot.
class ChatHistoryEntry {
  final ChatHistoryPlatform platform;

  /// Twitch: broadcaster id. Kick: channel slug. YouTube: the channel
  /// **entry label** (survives the auto-rollover to the channel's next
  /// stream — keyed by entry, not video id).
  final String channelKey;

  /// Twitch: chatter user id. YouTube: author channel id. Kick: sender
  /// id as a string.
  final String authorKey;

  final Object message;
  final ChatHistoryTombstone tombstone;

  const ChatHistoryEntry({
    required this.platform,
    required this.channelKey,
    required this.authorKey,
    required this.message,
    required this.tombstone,
  });
}

/// One row of a user card's message list: the model plus its feed-time
/// tombstone snapshot. A null [tombstoneSnapshot] means the message is
/// still in the live buffer — live tombstone state applies.
class UserCardMessage<T> {
  final T message;
  final ChatHistoryTombstone? tombstoneSnapshot;

  const UserCardMessage(this.message, {this.tombstoneSnapshot});
}

typedef _AuthorKey = ({ChatHistoryPlatform platform, String channel, String author});

/// The global FIFO queue plus a per-(platform, channel, author) index of
/// append-only chronological queues, so `historyFor` is an index lookup
/// instead of a full scan. Global eviction pops the queue front —
/// always the front of its author queue too (per-author order is global
/// order filtered), so both sides stay O(1).
class ChatHistoryStore {
  final Queue<ChatHistoryEntry> _global = Queue<ChatHistoryEntry>();
  final Map<_AuthorKey, Queue<ChatHistoryEntry>> _byAuthor =
      <_AuthorKey, Queue<ChatHistoryEntry>>{};

  int _cap;

  /// [cap] is the test seam: passed verbatim (NOT clamped) so tests can
  /// exercise eviction with small numbers. Production passes nothing —
  /// the persisted [SettingsKeys.ChatHistoryCap] wins (clamped), falling
  /// back to [kChatHistoryCapDefault] when no setting/box exists.
  ChatHistoryStore({int? cap})
    : _cap = cap ?? _clampCap(_persistedCap() ?? kChatHistoryCapDefault);

  /// The active global FIFO cap.
  int get cap => this._cap;

  /// Runtime change (the options sheet's Chat history page): clamps to
  /// [kChatHistoryCapMin] / [kChatHistoryCapMax]; lowering trims the
  /// oldest entries right away (author index included), raising just
  /// un-gates growth.
  set cap(int value) {
    this._cap = _clampCap(value);
    this._trimToCap();
  }

  static int _clampCap(int value) =>
      value.clamp(kChatHistoryCapMin, kChatHistoryCapMax);

  static int? _persistedCap() {
    if (!Hive.isBoxOpen(HiveKeys.Settings.name)) return null;
    final value = Hive.box(
      HiveKeys.Settings.name,
    ).get(SettingsKeys.ChatHistoryCap.name);
    return value is int ? value : null;
  }

  int get length => this._global.length;

  /// Retain a message that left its buffer because of the cap. Hot path
  /// (runs per eviction): only O(1) work here.
  void record({
    required ChatHistoryPlatform platform,
    required String channelKey,
    required String authorKey,
    required Object message,
    ChatHistoryTombstone tombstone = const ChatHistoryTombstone(
      isDeleted: false,
    ),
  }) {
    final entry = ChatHistoryEntry(
      platform: platform,
      channelKey: channelKey,
      authorKey: authorKey,
      message: message,
      tombstone: tombstone,
    );
    this._global.addLast(entry);
    final key = (platform: platform, channel: channelKey, author: authorKey);
    this._byAuthor.putIfAbsent(key, Queue<ChatHistoryEntry>.new).addLast(entry);
    this._trimToCap();
  }

  /// Drops the oldest entries (global FIFO) until within [cap] — one
  /// pass after a `record`, a loop after the cap was lowered.
  void _trimToCap() {
    while (this._global.length > this._cap) {
      final evicted = this._global.removeFirst();
      final evictedKey = (
        platform: evicted.platform,
        channel: evicted.channelKey,
        author: evicted.authorKey,
      );
      final list = this._byAuthor[evictedKey]!;
      list.removeFirst();
      if (list.isEmpty) this._byAuthor.remove(evictedKey);
    }
  }

  /// Everything retained from [authorKey] in (platform, channelKey),
  /// oldest first.
  List<ChatHistoryEntry> historyFor({
    required ChatHistoryPlatform platform,
    required String channelKey,
    required String authorKey,
  }) {
    final list = this._byAuthor[(
      platform: platform,
      channel: channelKey,
      author: authorKey,
    )];
    return list == null ? const [] : list.toList(growable: false);
  }

  /// Retained count without materializing the rows (the card's "Show X
  /// older messages" button).
  int countFor({
    required ChatHistoryPlatform platform,
    required String channelKey,
    required String authorKey,
  }) =>
      this._byAuthor[(
            platform: platform,
            channel: channelKey,
            author: authorKey,
          )]?.length ??
      0;

  /// A channel leaving the user's list: retaining its rows would defeat
  /// the removal. (`/clear` is NOT an erase here - see the class doc.)
  void clearChannel(ChatHistoryPlatform platform, String channelKey) {
    this._byAuthor.removeWhere(
      (key, _) => key.platform == platform && key.channel == channelKey,
    );
    this._global.removeWhere(
      (entry) => entry.platform == platform && entry.channelKey == channelKey,
    );
  }

  /// Logout / invalid auth / session reset wipes the platform's buffers —
  /// the next login (maybe another account) opens no stale history.
  void clearPlatform(ChatHistoryPlatform platform) {
    this._byAuthor.removeWhere((key, _) => key.platform == platform);
    this._global.removeWhere((entry) => entry.platform == platform);
  }

  void clearAll() {
    this._global.clear();
    this._byAuthor.clear();
  }
}
