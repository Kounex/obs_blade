library;

import 'dart:collection';

/// Session chat history beyond the live buffers' 500-row cap: messages
/// evicted from the Twitch / YouTube / Kick buffers because of the cap
/// (and only then - not on /clear, not on logout wipes) land here as
/// full-fidelity models, so the user card can answer "what has this
/// chatter said" further back than the ~500 rows the timeline keeps.
///
/// In-memory only, never persisted (chat content never touches Hive);
/// session-scoped by design. One global FIFO cap summed across all
/// platforms ([kChatHistoryCap]) — a quiet session next to a busy one
/// lends it its room. Consumed only by the user-card sheets; chat search
/// and the timeline deliberately don't read it.
///
/// Erase semantics mirror the buffer wipes exactly: the platform stores
/// call [clearChannel] on /clear and when a channel leaves the user's
/// list, [clearPlatform] on logout / invalid auth / session reset (Kick
/// signs out without wiping its buffers - anonymous reads - so it wipes
/// no history either), never on channel switch / stream rollover /
/// backgrounding.
///
/// Messages retained across all platforms combined (~1.0-1.4 KB each per
/// the capacity spike in `test/chat/chat_history_capacity_test.dart` —
/// ~250 MB worst case, bounded and session-scoped).
const int kChatHistoryCap = 200000;

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
/// instead of a 200k-row scan. Global eviction pops the queue front —
/// always the front of its author queue too (per-author order is global
/// order filtered), so both sides stay O(1).
class ChatHistoryStore {
  final Queue<ChatHistoryEntry> _global = Queue<ChatHistoryEntry>();
  final Map<_AuthorKey, Queue<ChatHistoryEntry>> _byAuthor =
      <_AuthorKey, Queue<ChatHistoryEntry>>{};

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
    if (this._global.length > kChatHistoryCap) {
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

  /// `/clear` or a channel leaving the user's list: keeping the content
  /// would defeat the moderation action / the removal.
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
