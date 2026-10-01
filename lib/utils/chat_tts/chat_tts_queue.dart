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

class _Pending {
  final String text;
  final String? detectionText;
  final DateTime receivedAt;

  const _Pending(this.text, this.detectionText, this.receivedAt);
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

  final Queue<_Pending> _pending = Queue();
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

  void add(String text, {DateTime? receivedAt, String? detectionText}) {
    _pending.add(_Pending(text, detectionText, receivedAt ?? _now()));
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

  Future<void> _next() async {
    final generation = _generation;
    while (_pending.isNotEmpty) {
      final next = _pending.removeFirst();
      final staleAfter = this.skipStaleAfter;
      if (staleAfter != null &&
          _now().difference(next.receivedAt) > staleAfter) {
        continue;
      }
      _speaking = true;
      this.onChanged?.call();
      try {
        await _speaker
            .speak(next.text, detectionText: next.detectionText)
            .timeout(
              this.utteranceTimeout(next.text),
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
