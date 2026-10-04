import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_scrollback.dart';

/// A row as Kick / YouTube keep it: a delete swaps in a new object
class _Row {
  final String id;
  final bool deleted;

  const _Row(this.id, {this.deleted = false});
}

void main() {
  var holds = 0;
  ChatScrollback scrollback() =>
      ChatScrollback(hold: () => holds++, release: () => holds--);

  List<_Row> rows(int from, int to) => [
    for (var i = from; i < to; i++) _Row('r$i'),
  ];

  test('pinned: the live rows; scrolled up: holds, back: releases', () {
    final back = scrollback();
    final live = rows(0, 3);
    expect(back.rows(live, buffered: 3, keyOf: (r) => r.id), same(live));
    back.update(scrolledUp: true);
    expect(holds, 1);
    back.update(scrolledUp: true);
    expect(holds, 1);
    back.update(scrolledUp: false);
    expect(holds, 0);
  });

  test('past the freeze point the rows stop changing, but each shows the '
      "store's latest copy (a delete still lands)", () {
    final back = scrollback()..update(scrolledUp: true);
    final atFreeze = rows(0, ChatScrollback.freezeAt);
    back.rows(atFreeze, buffered: atFreeze.length, keyOf: (r) => r.id);
    expect(back.frozen, isTrue);

    /// Later: r0 dropped from the store, r1 deleted, new rows arrived
    final later = [
      const _Row('r1', deleted: true),
      ...rows(2, ChatScrollback.freezeAt + 50),
    ];
    final shown = back.rows(
      later,
      buffered: later.length,
      keyOf: (r) => r.id,
    );
    expect(shown, hasLength(ChatScrollback.freezeAt));
    expect(shown.first.id, 'r0');
    expect(shown[1].deleted, isTrue);
    expect(shown.last.id, 'r${ChatScrollback.freezeAt - 1}');

    /// A cleared chat (Kick /clear) shows nothing of it
    expect(back.rows(<_Row>[], buffered: 0, keyOf: (r) => r.id), isEmpty);

    back.dispose();
    expect(back.frozen, isFalse);
    expect(holds, 0);
  });
}
