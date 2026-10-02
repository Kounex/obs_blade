import 'dart:async';
import 'dart:collection';

/// The speech engine behind [ChatTtsQueue] - the platform channel in the
/// app, a fake in tests. [speak] completes once the utterance finished (or
/// was stopped).
abstract class ChatTtsSpeaker {
  /// [detectionText]: the part language detection should look at (the
  /// message without the username) - null = [text]. False: the audio is
  /// taken (phone call, another app holding audio focus) and the message
  /// wasn't read (or was cut off) - the queue tries it again later.
  Future<bool> speak(String text, {String? detectionText});

  /// Reads [text] once with [voiceId] (else [language]'s voice), cutting
  /// off whatever is being read - the voice picker's preview. Completes
  /// once the sample finished or was stopped
  Future<void> preview({
    String? voiceId,
    String? language,
    required String text,
  });

  Future<void> stop();
}

/// One message waiting to be read
class ChatTtsQueueItem {
  final String text;
  final String? detectionText;
  final DateTime receivedAt;

  /// Identical short messages share this key and may be read once together
  /// - null = never combined
  final String? combineKey;

  /// What a combined line reads for it and how often it counts - a
  /// message that is one word repeated combines as that word ("KEKW", 3)
  final String? combineText;
  final int repeats;

  /// Who sent it and whether they're worth naming in a combined line
  /// (highlighted user, mod, streamer)
  final String? author;
  final bool notable;

  /// Whether it still belongs to the chat on screen - false (the user
  /// switched platform, channel or engine) skips it when its turn comes
  final bool Function()? isCurrent;

  const ChatTtsQueueItem({
    required this.text,
    required this.receivedAt,
    this.detectionText,
    this.combineKey,
    this.combineText,
    this.repeats = 1,
    this.author,
    this.notable = false,
    this.isCurrent,
  });
}

/// Reads utterances one after another. Nothing is dropped on its own:
/// a busy chat grows [waiting] (shown in the UI) until the user jumps to
/// the latest message - unless [skipStaleAfter] is set (opt-in), then
/// messages older than that when their turn comes are skipped.
class ChatTtsQueue {
  final ChatTtsSpeaker _speaker;
  final DateTime Function() _now;

  /// Called whenever [waiting] or [speaking] changes
  final void Function()? onChanged;

  /// Longest a message may take before the queue gives up on it and
  /// moves on - a platform that never reports "finished" (e.g. an audio
  /// interruption) must not stall reading for good
  final Duration Function(String text) utteranceTimeout;

  /// How long to wait before trying again while the audio is taken
  /// (phone call, another app's audio focus)
  final Duration busyRetry;

  ChatTtsQueue(
    this._speaker, {
    DateTime Function()? now,
    this.onChanged,
    Duration Function(String text)? utteranceTimeout,
    this.busyRetry = const Duration(seconds: 2),
  }) : _now = now ?? DateTime.now,
       utteranceTimeout = utteranceTimeout ?? defaultUtteranceTimeout;

  /// Generous even at half speed: 10s + 150ms per character
  static Duration defaultUtteranceTimeout(String text) =>
      Duration(milliseconds: 10000 + 150 * text.length);

  final Queue<ChatTtsQueueItem> _pending = Queue();

  /// Builds the line for a group of identical messages (first one first) -
  /// null = never combine. Only messages already waiting are combined, so
  /// a quiet chat reads exactly as before; nothing is held back to collect
  String Function(List<ChatTtsQueueItem> group)? combine;
  bool _speaking = false;

  /// Bumped by [clear] - a [speak] that returns afterwards must not start
  /// the next pending one of the old run
  int _generation = 0;

  /// Bumped per [hold] - only the latest one resumes reading
  int _holdGeneration = 0;
  bool _held = false;

  /// Skip messages older than this when their turn comes - null = read
  /// everything (default)
  Duration? skipStaleAfter;

  /// Messages waiting behind the one being read
  int get waiting => _pending.length;

  bool get speaking => _speaking;

  void add(
    String text, {
    DateTime? receivedAt,
    String? detectionText,
    String? combineKey,
    String? combineText,
    int repeats = 1,
    String? author,
    bool notable = false,
    bool Function()? isCurrent,
  }) {
    _pending.add(
      ChatTtsQueueItem(
        text: text,
        receivedAt: receivedAt ?? _now(),
        detectionText: detectionText,
        combineKey: combineKey,
        combineText: combineText,
        repeats: repeats,
        author: author,
        notable: notable,
        isCurrent: isCurrent,
      ),
    );
    this.onChanged?.call();
    if (!_speaking && !_held) _next();
  }

  /// Drops what's waiting, stops the current message and runs [action]
  /// (the voice preview) with reading paused - new messages wait behind it
  /// instead of cutting it off, and are read once it completes
  Future<void> hold(Future<void> Function() action) async {
    final hold = ++_holdGeneration;
    _held = true;
    await clear();
    try {
      await action();
    } finally {
      if (hold == _holdGeneration) {
        _held = false;
        if (!_speaking && _pending.isNotEmpty) _next();
      }
    }
  }

  /// Drops everything waiting and stops the current message - the next
  /// one read is the next new message
  Future<void> clear() async {
    _generation++;
    _pending.clear();
    _speaking = false;
    this.onChanged?.call();
    await _speaker.stop();
  }

  /// Too old (opt-in) or no longer the chat on screen
  bool _skip(ChatTtsQueueItem item) {
    if (item.isCurrent?.call() == false) return true;
    final staleAfter = this.skipStaleAfter;
    return staleAfter != null &&
        _now().difference(item.receivedAt) > staleAfter;
  }

  /// [next] alone, or with every waiting message of the same combine key
  /// (those leave the queue)
  List<ChatTtsQueueItem> _groupFor(ChatTtsQueueItem next) {
    final key = next.combineKey;
    if (this.combine == null || key == null) return [next];
    final group = [
      next,
      for (final item in _pending)
        if (item.combineKey == key && !_skip(item)) item,
    ];
    if (group.length > 1) {
      _pending.removeWhere((item) => item.combineKey == key);
    }
    return group;
  }

  Future<void> _next() async {
    final generation = _generation;
    while (_pending.isNotEmpty) {
      final next = _pending.removeFirst();
      if (_skip(next)) {
        this.onChanged?.call();
        continue;
      }
      final group = _groupFor(next);
      final combine = this.combine;
      final text = group.length > 1 && combine != null
          ? combine(group)
          : next.text;
      _speaking = true;
      this.onChanged?.call();
      var spoken = true;
      try {
        spoken = await _speaker
            .speak(text, detectionText: next.detectionText)
            .timeout(
              this.utteranceTimeout(text),
              onTimeout: () async {
                await _speaker.stop();
                return true;
              },
            );
      } catch (_) {
        /// A failing engine must not end the loop for good
      }
      if (generation != _generation) return;
      if (!spoken) {
        /// The audio is taken (phone call) - the message keeps its place
        /// and is tried again, nothing is dropped meanwhile
        for (final item in group.reversed) {
          _pending.addFirst(item);
        }
        this.onChanged?.call();
        await Future<void>.delayed(this.busyRetry);
        if (generation != _generation) return;
      }
    }
    _speaking = false;
    this.onChanged?.call();
  }
}
