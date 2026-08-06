import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/stores/views/twitch_emotes.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user_emote.dart';

import 'support/fake_twitch_services.dart';

void main() {
  late FakeTwitchEmoteService service;
  late TwitchEmoteStore store;

  setUp(() {
    service = FakeTwitchEmoteService();
    store = TwitchEmoteStore(service: service);
  });

  test('fetch splits channel vs global by owner, alpha-sorted', () async {
    service.emotes = [
      FakeTwitchEmoteService.channelEmote,
      FakeTwitchEmoteService.globalEmote,
      FakeTwitchEmoteService.anotherChannelEmote,
    ];

    await store.fetch(accessToken: 'token-1', userId: 'user-1');

    expect(service.lastAccessToken, 'token-1');
    expect(service.lastUserId, 'user-1');
    expect(service.lastBroadcasterId, 'user-1');
    expect(store.channelEmotes.map((e) => e.name), ['BabyRage', 'Kappa']);
    expect(store.globalEmotes.map((e) => e.name), ['PogChamp']);
    expect(store.catalogVersion, 1);
    expect(store.isLoading, isFalse);
  });

  test('isLoading is true while the fetch is parked', () async {
    service.fetchGate = Completer<List<TwitchUserEmote>>();
    final pending = store.fetch(accessToken: 'token-1', userId: 'user-1');

    expect(store.isLoading, isTrue);

    service.fetchGate!.complete(const []);
    await pending;
    expect(store.isLoading, isFalse);
  });

  test('a failing fetch degrades to empty and still bumps the version',
      () async {
    service.fetchThrows = Exception('boom');

    await store.fetch(accessToken: 'token-1', userId: 'user-1');

    expect(store.channelEmotes, isEmpty);
    expect(store.globalEmotes, isEmpty);
    expect(store.catalogVersion, 1);
    expect(store.isLoading, isFalse);
  });

  test('a superseded fetch cannot overwrite the newer catalog', () async {
    final gate = Completer<List<TwitchUserEmote>>();
    service.fetchGate = gate;
    final first = store.fetch(accessToken: 'token-1', userId: 'user-1');

    service.fetchGate = null;

    /// The newer fetch belongs to a different account (user-2) — its emote
    /// must be owned by user-2 to land in the channel section (grouping
    /// rule: ownerId == fetch userId). Deviation from the brief: it reused
    /// [FakeTwitchEmoteService.channelEmote] (ownerId user-1) here, which
    /// the owner rule sorts into the global section — contradicting this
    /// test's own expectations and the spec's grouping rule.
    service.emotes = const [
      TwitchUserEmote(id: '25', name: 'Kappa', ownerId: 'user-2'),
    ];
    await store.fetch(accessToken: 'token-2', userId: 'user-2');

    gate.complete([FakeTwitchEmoteService.globalEmote]);
    await first;

    expect(store.channelEmotes.map((e) => e.name), ['Kappa']);
    expect(store.globalEmotes, isEmpty);

    /// The superseded fetch returned before applying — only the newer
    /// fetch bumped the version.
    expect(store.catalogVersion, 1);
  });

  test('clear drops the catalog and bumps the version', () async {
    service.emotes = [FakeTwitchEmoteService.channelEmote];
    await store.fetch(accessToken: 'token-1', userId: 'user-1');
    expect(store.channelEmotes, isNotEmpty);

    store.clear();

    expect(store.channelEmotes, isEmpty);
    expect(store.globalEmotes, isEmpty);
    expect(store.catalogVersion, 2);
  });
}
