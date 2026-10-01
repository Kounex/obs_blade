import 'dart:async';
import 'dart:collection';

/// The speech engine behind [ChatTtsQueue] - the platform channel in the
/// app, a fake in tests. [speak] completes once the utterance finished (or
/// was stopped).
abstract class ChatTtsSpeaker {
  /// [detectionText]: the part language detection should look at (the
  /// message without the username) - null = [text]
  Future<void> speak(String text, {String? detectionText});

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

  /// Who sent it and whether they're worth naming in a combined line
  /// (highlighted user, mod, streamer)
  final String? author;
  final bool notable;

  const ChatTtsQueueItem({
    required this.text,
    required this.receivedAt,
    this.detectionText,
    this.combineKey,
    this.author,
    this.notable = false,
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

  ChatTtsQueue(
    this._speaker, {
    DateTime Function()? now,
    this.onChanged,
    Duration Function(String text)? utteranceTimeout,
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
    String? author,
    bool notable = false,
  }) {
    _pending.add(
      ChatTtsQueueItem(
        text: text,
        receivedAt: receivedAt ?? _now(),
        detectionText: detectionText,
        combineKey: combineKey,
        author: author,
        notable: notable,
      ),
    );
    this.onChanged?.call();
    if (!_speaking) _next();
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

  bool _stale(ChatTtsQueueItem item) {
    final staleAfter = this.skipStaleAfter;
    return staleAfter != null &&
        _now().difference(item.receivedAt) > staleAfter;
  }

  /// [next]'s text, or one line for it plus every waiting message with the
  /// same combine key (those leave the queue)
  String _textFor(ChatTtsQueueItem next) {
    final combine = this.combine;
    final key = next.combineKey;
    if (combine == null || key == null) return next.text;
    final group = [
      next,
      for (final item in _pending)
        if (item.combineKey == key && !_stale(item)) item,
    ];
    if (group.length == 1) return next.text;
    _pending.removeWhere((item) => item.combineKey == key);
    return combine(group);
  }

  Future<void> _next() async {
    final generation = _generation;
    while (_pending.isNotEmpty) {
      final next = _pending.removeFirst();
      if (_stale(next)) continue;
      final text = _textFor(next);
      _speaking = true;
      this.onChanged?.call();
      try {
        await _speaker
            .speak(text, detectionText: next.detectionText)
            .timeout(
              this.utteranceTimeout(text),
              onTimeout: () => _speaker.stop(),
            );
      } catch (_) {
        /// A failing engine must not end the loop for good
      }
      if (generation != _generation) return;
    }
    _speaking = false;
    this.onChanged?.call();
  }
}
