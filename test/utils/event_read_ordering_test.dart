import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/event_read_ordering.dart';

void main() {
  late EventOrdering<String> ordering;

  setUp(() => ordering = EventOrdering<String>());

  test('read applies when no event arrived for the key', () {
    final tag = ordering.capture();
    expect(ordering.shouldApplyRead('program', tag), isTrue);
  });

  test('event captured after send beats the read (per key)', () {
    final tag = ordering.capture();
    ordering.noteEvent('program');
    expect(ordering.shouldApplyRead('program', tag), isFalse);
    // a different key is unaffected (per-key independence)
    expect(ordering.shouldApplyRead('preview', tag), isTrue);
  });

  test('a read sent AFTER the event supersedes it', () {
    ordering.noteEvent('program');
    final tag = ordering.capture();
    expect(ordering.shouldApplyRead('program', tag), isTrue);
  });

  test('two events: only sequences after capture block', () {
    ordering.noteEvent('program'); // seq 1
    final tag = ordering.capture(); // captures 1
    expect(ordering.shouldApplyRead('program', tag), isTrue);
    ordering.noteEvent('program'); // seq 2
    expect(ordering.shouldApplyRead('program', tag), isFalse);
  });

  test('newEpoch invalidates in-flight tags and clears journals', () {
    final tag = ordering.capture();
    ordering.newEpoch();
    expect(ordering.shouldApplyRead('program', tag), isFalse);
    // a fresh capture in the new epoch applies again
    final tag2 = ordering.capture();
    expect(ordering.shouldApplyRead('program', tag2), isTrue);
  });

  test('tags from an old epoch stay invalid even after new events', () {
    final tag = ordering.capture();
    ordering.newEpoch();
    ordering.noteEvent('program');
    expect(ordering.shouldApplyRead('program', tag), isFalse);
  });
}
