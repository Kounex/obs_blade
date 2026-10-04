import 'package:mobx/mobx.dart';

/// Row cap of a chat buffer: [base] normally, [held] while a reader is
/// scrolled up in it ([hold] / [release]). At the cap every new row drops
/// the oldest; under a scrolled-up reader that shifts what they read up
/// by the dropped row's height - in a busy chat several times a second.
/// Held, nothing is dropped until [held], and the rows stay in the store,
/// so deletes / bans / tombstones keep reaching them. Observable, so a
/// computed cut (the combined timeline) follows it.
class ChatBufferCap {
  final int base;
  final int held;

  final Observable<int> _holds = Observable(0);

  ChatBufferCap({required this.base, this.held = kChatHeldRows});

  bool get holding => this._holds.value > 0;

  int get value => this.holding ? this.held : this.base;

  void hold() => runInAction(() => this._holds.value++);

  /// True when the last hold went away - the buffer trims back to [base]
  /// (the reader is at the newest row, so the cut above isn't seen).
  bool release() {
    if (this._holds.value == 0) return false;
    runInAction(() => this._holds.value--);
    return this._holds.value == 0;
  }
}

/// Rows a buffer keeps at most while held ([ChatBufferCap.held]); the
/// scrolled-up view stops taking new rows a little before that.
const int kChatHeldRows = 2000;
