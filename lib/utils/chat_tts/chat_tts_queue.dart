import 'dart:async';
import 'dart:collection';

/// The speech engine behind [ChatTtsQueue] - `flutter_tts` in the app, a
/// fake in tests. [speak] completes once the utterance finished (or was
/// stopped).
abstract class ChatTtsSpeaker {
  Future<void> speak(String text);

  Future<void> stop();
}

class _Pending {
  final String text;
  final DateTime receivedAt;

  const _Pending(this.text, this.receivedAt);
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

  ChatTtsQueue(this._speaker, {DateTime Function()? now, this.onChanged})
    : _now = now ?? DateTime.now;

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

  void add(String text, {DateTime? receivedAt}) {
    _pending.add(_Pending(text, receivedAt ?? _now()));
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
        await _speaker.speak(next.text);
      } catch (_) {
        /// A failing engine must not end the loop for good
      }
      if (generation != _generation) return;
    }
    _speaking = false;
    this.onChanged?.call();
  }
}
