import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/stores/views/kick_emotes.dart';
import 'package:obs_blade/types/classes/kick/kick_emote.dart';

import 'support/fake_kick_services.dart';

void main() {
  late FakeKickEmoteService service;
  late KickEmoteStore store;

  const channelSection = KickEmoteSection(
    label: 'Channel',
    emotes: [KickEmote(id: 1, name: 'xqcL')],
  );
  const globalSection = KickEmoteSection(
    label: 'Global',
    emotes: [KickEmote(id: 100, name: 'PogChamp')],
  );

  setUp(() {
    service = FakeKickEmoteService();
    store = KickEmoteStore(service: service);
  });

  test('fetch applies the sections in order and bumps the version', () async {
    service.sections['xqc'] = [channelSection, globalSection];

    await store.fetch('xqc');

    expect(service.fetchCalls, ['xqc']);
    expect(store.sections.map((s) => s.label), ['Channel', 'Global']);
    expect(store.catalogVersion, 1);
    expect(store.isLoading, isFalse);
  });

  test('isLoading is true while the fetch is parked', () async {
    service.fetchGate = Completer<List<KickEmoteSection>>();
    final pending = store.fetch('xqc');

    expect(store.isLoading, isTrue);

    service.fetchGate!.complete([channelSection]);
    await pending;
    expect(store.isLoading, isFalse);
  });

  test(
    'a failing fetch degrades to empty and still bumps the version',
    () async {
      service.fetchThrows = Exception('boom');

      await store.fetch('xqc');

      expect(store.sections, isEmpty);
      expect(store.catalogVersion, 1);
      expect(store.isLoading, isFalse);
    },
  );

  test('a superseded fetch cannot overwrite the newer catalog', () async {
    final gate = Completer<List<KickEmoteSection>>();
    service.fetchGate = gate;
    final first = store.fetch('aaa');

    service.fetchGate = null;
    await store.fetch('bbb');

    gate.complete([channelSection]);
    await first;

    /// The newer ('bbb') fetch's empty result stands — the stale 'aaa'
    /// fetch's late-arriving sections must not overwrite it.
    expect(store.sections, isEmpty);
    expect(store.catalogVersion, 1);
  });

  test('clear drops the catalog and bumps the version', () async {
    service.sections['xqc'] = [channelSection];
    await store.fetch('xqc');
    expect(store.sections, isNotEmpty);

    store.clear();

    expect(store.sections, isEmpty);
    expect(store.catalogVersion, 2);
  });
}
