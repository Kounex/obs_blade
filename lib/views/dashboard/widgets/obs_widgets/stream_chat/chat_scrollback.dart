import 'package:flutter/foundation.dart';

import '../../../../../../stores/shared/chat_buffer_cap.dart';

/// Reading back in a busy chat (every native chat view). While the reader
/// is away from the newest row the store keeps every row ([hold] →
/// [ChatBufferCap]), so nothing above them is dropped - each dropped row
/// used to shift what they read up by its height - and new rows keep
/// landing below. Just before the held cap the view stops taking rows:
/// [rows] keeps returning the same list (the "N new messages" pill still
/// counts the live ones) until the reader is back at the bottom.
class ChatScrollback {
  final VoidCallback _hold;
  final VoidCallback _release;

  bool _holding = false;
  Object? _frozen;

  /// The view stops taking rows here; the store drops past
  /// [kChatHeldRows], and the margin covers a burst between two frames.
  static const int freezeAt = kChatHeldRows - 100;

  ChatScrollback({
    required VoidCallback hold,
    required VoidCallback release,
  }) : _hold = hold,
       _release = release;

  bool get frozen => this._frozen != null;

  /// Call whenever the view's "pinned to the newest row" flips - not
  /// from a build (it changes store state).
  void update({required bool scrolledUp}) {
    if (scrolledUp == this._holding) return;
    this._holding = scrolledUp;
    if (scrolledUp) {
      this._hold();
    } else {
      this._frozen = null;
      this._release();
    }
  }

  /// What the view renders for the store's [items]; [buffered] is how
  /// many rows the store holds (what its cap counts).
  List<T> rows<T>(List<T> items, {required int buffered}) {
    if (!this._holding) return items;
    if (this._frozen case final List<T> frozen) return frozen;
    if (buffered >= freezeAt) this._frozen = items;
    return items;
  }

  /// A view that goes away while scrolled up must not leave the store
  /// holding 2000 rows.
  void dispose() => this.update(scrolledUp: false);
}
