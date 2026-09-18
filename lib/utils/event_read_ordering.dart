/// Ordering journal for OBS state: a value event always beats a read that
/// was sent before the event arrived ("events beat stale reads").
///
/// Integrate at two seams: [capture] immediately before a read request is
/// sent, and [shouldApplyRead] when its response is applied. Value events
/// call [noteEvent] when applied. [newEpoch] invalidates everything in
/// flight (reconnect, scene-collection change, renames).
///
/// Pure and synchronous on purpose — no Flutter / MobX / app imports.
class EventOrdering<K> {
  int _seq = 0;
  int _epoch = 0;

  /// Key -> sequence of the latest event seen for it
  final Map<K, int> _latestEventSeq = {};

  /// Tag captured immediately before a read request is sent
  ({int epoch, int seq}) capture() => (epoch: _epoch, seq: _seq);

  /// A value event for [key] arrived (call when the event is applied)
  void noteEvent(K key) => _latestEventSeq[key] = ++_seq;

  /// At read-apply time: true when [tag] belongs to the current epoch and
  /// no event for [key] arrived after [tag] was captured. False = an event
  /// beat this read; keep the event value already in state.
  bool shouldApplyRead(K key, ({int epoch, int seq}) tag) =>
      tag.epoch == _epoch && (_latestEventSeq[key] ?? 0) <= tag.seq;

  /// Invalidate every in-flight tag and all journaled events
  void newEpoch() {
    _epoch++;
    _latestEventSeq.clear();
  }
}
