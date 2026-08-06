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
    expect(store.emoteImageUrl('peepoHappy'),
        FakeThirdPartyEmoteService.peepo.imageUrl);
    expect(store.emoteImageUrl('monkaS'),
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

    expect(store.emoteImageUrl('peepoHappy'),
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

    expect(store.emoteImageUrl('monkaS'),
        FakeThirdPartyEmoteService.monkaSevenTv.imageUrl);
  });

  test('a failing endpoint keeps the other catalogs', () async {
    service.sevenTvGlobal = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };
    service.bttvChannelThrows = Exception('boom');

    await store.fetch(broadcasterId: 'user-1');

    expect(store.emoteImageUrl('peepoHappy'), isNotNull);
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

    expect(store.emoteImageUrl('peepoHappy'), isNotNull);
    expect(store.emoteImageUrl('monkaS'), isNull);

    /// The superseded fetch returned before applying — only the newer
    /// fetch bumped the version.
    expect(store.catalogVersion, 1);
  });

  test('clear drops the catalog and bumps the version', () async {
    service.sevenTvGlobal = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };
    await store.fetch(broadcasterId: 'user-1');
    expect(store.emotes, isNotEmpty);

    store.clear();

    expect(store.emotes, isEmpty);
    expect(store.catalogVersion, 2);
  });

  test('lookup is exact and case-sensitive', () async {
    service.sevenTvGlobal = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };
    await store.fetch(broadcasterId: 'user-1');

    expect(store.emoteImageUrl('PeepoHappy'), isNull);
    expect(store.emoteImageUrl('peepoHappyy'), isNull);
    expect(store.emoteImageUrl(''), isNull);
  });
}
