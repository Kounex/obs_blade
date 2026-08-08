import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/types/classes/twitch/third_party_emote.dart';

import 'support/fake_twitch_services.dart';

void main() {
  late FakeThirdPartyEmoteService service;
  late ThirdPartyEmoteStore store;

  setUp(() {
    service = FakeThirdPartyEmoteService();
    store = ThirdPartyEmoteStore(service: service);
  });

  test('fetch applies all four catalogs and bumps the version', () async {
    service.sevenTvGlobal = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };
    service.bttvGlobal = {
      FakeThirdPartyEmoteService.monka.name: FakeThirdPartyEmoteService.monka,
    };

    await store.fetch(broadcasterId: 'user-1');

    expect(service.lastBroadcasterId, 'user-1');
    expect(store.emoteImageUrl('peepoHappy', broadcasterId: 'user-1'),
        FakeThirdPartyEmoteService.peepo.imageUrl);
    expect(store.emoteImageUrl('monkaS', broadcasterId: 'user-1'),
        FakeThirdPartyEmoteService.monka.imageUrl);
    expect(store.catalogVersion, 1);
  });

  test('channel catalog wins over global for the same name', () async {
    service.sevenTvGlobal = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };
    service.sevenTvChannel = {
      FakeThirdPartyEmoteService.peepoChannelOverride.name:
          FakeThirdPartyEmoteService.peepoChannelOverride,
    };

    await store.fetch(broadcasterId: 'user-1');

    expect(store.emoteImageUrl('peepoHappy', broadcasterId: 'user-1'),
        FakeThirdPartyEmoteService.peepoChannelOverride.imageUrl);
  });

  test('7TV wins over BTTV within the same scope', () async {
    service.bttvGlobal = {
      FakeThirdPartyEmoteService.monka.name: FakeThirdPartyEmoteService.monka,
    };
    service.sevenTvGlobal = {
      FakeThirdPartyEmoteService.monkaSevenTv.name:
          FakeThirdPartyEmoteService.monkaSevenTv,
    };

    await store.fetch(broadcasterId: 'user-1');

    expect(store.emoteImageUrl('monkaS', broadcasterId: 'user-1'),
        FakeThirdPartyEmoteService.monkaSevenTv.imageUrl);
  });

  test('two broadcasters keep separate channel catalogs', () async {
    service.sevenTvChannel = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };
    await store.fetch(broadcasterId: 'chan-1');

    service.sevenTvChannel = {
      FakeThirdPartyEmoteService.monka.name: FakeThirdPartyEmoteService.monka,
    };
    await store.fetch(broadcasterId: 'chan-2');

    /// chan-1's slot survived chan-2's fetch untouched.
    expect(store.emoteImageUrl('peepoHappy', broadcasterId: 'chan-1'),
        isNotNull);
    expect(store.emoteImageUrl('peepoHappy', broadcasterId: 'chan-2'), isNull);
    expect(store.emoteImageUrl('monkaS', broadcasterId: 'chan-2'), isNotNull);
    expect(store.emoteImageUrl('monkaS', broadcasterId: 'chan-1'), isNull);
  });

  test('an unfetched broadcaster falls back to the global catalogs', () async {
    service.sevenTvGlobal = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };
    await store.fetch(broadcasterId: 'chan-1');

    expect(store.emoteImageUrl('peepoHappy', broadcasterId: 'chan-unseen'),
        FakeThirdPartyEmoteService.peepo.imageUrl);
  });

  test('a failing endpoint keeps the other catalogs', () async {
    service.sevenTvGlobal = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };
    service.bttvChannelThrows = Exception('boom');

    await store.fetch(broadcasterId: 'user-1');

    expect(
        store.emoteImageUrl('peepoHappy', broadcasterId: 'user-1'), isNotNull);
    expect(store.catalogVersion, 1);
  });

  test('a superseded fetch cannot overwrite the newer catalog', () async {
    final gate = Completer<Map<String, ThirdPartyEmote>>();
    service.sevenTvGlobalGate = gate;
    final first = store.fetch(broadcasterId: 'user-1');

    service.sevenTvGlobalGate = null;
    service.sevenTvGlobal = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };
    await store.fetch(broadcasterId: 'user-2');

    gate.complete({
      FakeThirdPartyEmoteService.monka.name: FakeThirdPartyEmoteService.monka,
    });
    await first;

    expect(
        store.emoteImageUrl('peepoHappy', broadcasterId: 'user-2'), isNotNull);
    expect(store.emoteImageUrl('monkaS', broadcasterId: 'user-2'), isNull);

    /// The superseded fetch returned before applying — only the newer
    /// fetch bumped the version.
    expect(store.catalogVersion, 1);
  });

  test('clear drops the catalogs and bumps the version', () async {
    service.sevenTvGlobal = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };
    await store.fetch(broadcasterId: 'user-1');
    expect(store.globalEmotes, isNotEmpty);

    store.clear();

    expect(store.globalEmotes, isEmpty);
    expect(store.channelEmotes, isEmpty);
    expect(store.catalogVersion, 2);
  });

  test('lookup is exact and case-sensitive', () async {
    service.sevenTvGlobal = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };
    await store.fetch(broadcasterId: 'user-1');

    expect(store.emoteImageUrl('PeepoHappy', broadcasterId: 'user-1'), isNull);
    expect(store.emoteImageUrl('peepoHappyy', broadcasterId: 'user-1'), isNull);
    expect(store.emoteImageUrl('', broadcasterId: 'user-1'), isNull);
  });
}
