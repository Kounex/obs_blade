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
    expect(
      store.emoteImageUrl('peepoHappy', broadcasterId: 'user-1'),
      FakeThirdPartyEmoteService.peepo.imageUrl,
    );
    expect(
      store.emoteImageUrl('monkaS', broadcasterId: 'user-1'),
      FakeThirdPartyEmoteService.monka.imageUrl,
    );
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

    expect(
      store.emoteImageUrl('peepoHappy', broadcasterId: 'user-1'),
      FakeThirdPartyEmoteService.peepoChannelOverride.imageUrl,
    );
  });

  test('isKick queries the kick 7TV platform, skips BTTV channel '
      'entirely', () async {
    service.sevenTvKickChannel = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };

    await store.fetch(broadcasterId: '676', isKick: true);

    expect(service.lastKickUserId, '676');
    expect(service.sevenTvKickChannelCalls, 1);
    expect(service.sevenTvChannelCalls, 0);
    expect(service.bttvChannelCalls, 0);
    expect(
      store.emoteImageUrl('peepoHappy', broadcasterId: '676'),
      FakeThirdPartyEmoteService.peepo.imageUrl,
    );
  });

  test(
    'isKick still fetches both global catalogs (platform-agnostic)',
    () async {
      service.sevenTvGlobal = {
        FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
      };
      service.bttvGlobal = {
        FakeThirdPartyEmoteService.monka.name: FakeThirdPartyEmoteService.monka,
      };

      await store.fetch(broadcasterId: '676', isKick: true);

      expect(
        store.emoteImageUrl('peepoHappy', broadcasterId: '676'),
        isNotNull,
      );
      expect(store.emoteImageUrl('monkaS', broadcasterId: '676'), isNotNull);
    },
  );

  test('7TV wins over BTTV within the same scope', () async {
    service.bttvGlobal = {
      FakeThirdPartyEmoteService.monka.name: FakeThirdPartyEmoteService.monka,
    };
    service.sevenTvGlobal = {
      FakeThirdPartyEmoteService.monkaSevenTv.name:
          FakeThirdPartyEmoteService.monkaSevenTv,
    };

    await store.fetch(broadcasterId: 'user-1');

    expect(
      store.emoteImageUrl('monkaS', broadcasterId: 'user-1'),
      FakeThirdPartyEmoteService.monkaSevenTv.imageUrl,
    );
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
    expect(
      store.emoteImageUrl('peepoHappy', broadcasterId: 'chan-1'),
      isNotNull,
    );
    expect(store.emoteImageUrl('peepoHappy', broadcasterId: 'chan-2'), isNull);
    expect(store.emoteImageUrl('monkaS', broadcasterId: 'chan-2'), isNotNull);
    expect(store.emoteImageUrl('monkaS', broadcasterId: 'chan-1'), isNull);
  });

  test('an unfetched broadcaster falls back to the global catalogs', () async {
    service.sevenTvGlobal = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };
    await store.fetch(broadcasterId: 'chan-1');

    expect(
      store.emoteImageUrl('peepoHappy', broadcasterId: 'chan-unseen'),
      FakeThirdPartyEmoteService.peepo.imageUrl,
    );
  });

  test('a failing endpoint keeps the other catalogs', () async {
    service.sevenTvGlobal = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };
    service.bttvChannelThrows = Exception('boom');

    await store.fetch(broadcasterId: 'user-1');

    expect(
      store.emoteImageUrl('peepoHappy', broadcasterId: 'user-1'),
      isNotNull,
    );
    expect(store.catalogVersion, 1);
  });

  test('a superseded fetch of the same channel cannot overwrite the newer '
      'catalog', () async {
    final gate = Completer<Map<String, ThirdPartyEmote>>();
    service.sevenTvChannelGate = gate;
    final first = store.fetch(broadcasterId: 'user-1');

    service.sevenTvChannelGate = null;
    service.sevenTvChannel = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };
    await store.fetch(broadcasterId: 'user-1');

    gate.complete({
      FakeThirdPartyEmoteService.monka.name: FakeThirdPartyEmoteService.monka,
    });
    await first;

    expect(
      store.emoteImageUrl('peepoHappy', broadcasterId: 'user-1'),
      isNotNull,
    );
    expect(store.emoteImageUrl('monkaS', broadcasterId: 'user-1'), isNull);
  });

  /// User report: in a combined chat ohnePixel's 7TV / BTTV emotes showed
  /// as text - Twitch's and Kick's connect fetches threw each other's
  /// channel catalogs away
  test('fetches of two channels at once both land (combined chat)', () async {
    final gate = Completer<Map<String, ThirdPartyEmote>>();
    service.sevenTvChannelGate = gate;
    final twitch = store.fetch(broadcasterId: 'twitch-1');

    service.sevenTvKickChannel = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };
    await store.fetch(broadcasterId: 'kick-1', isKick: true);

    gate.complete({
      FakeThirdPartyEmoteService.monka.name: FakeThirdPartyEmoteService.monka,
    });
    await twitch;

    expect(store.emoteImageUrl('monkaS', broadcasterId: 'twitch-1'), isNotNull);
    expect(
      store.emoteImageUrl('peepoHappy', broadcasterId: 'kick-1'),
      isNotNull,
    );
  });

  test(
    'a source that fails on a refetch keeps its last good catalog',
    () async {
      service.sevenTvChannel = {
        FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
      };
      await store.fetch(broadcasterId: 'user-1');
      expect(
        store.emoteImageUrl('peepoHappy', broadcasterId: 'user-1'),
        isNotNull,
      );

      service.sevenTvChannelThrows = Exception('Bad file descriptor');
      await store.fetch(broadcasterId: 'user-1');
      expect(
        store.emoteImageUrl('peepoHappy', broadcasterId: 'user-1'),
        isNotNull,
      );
    },
  );

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

  test(
    'FFZ ranks below BTTV and 7TV on name ties; Kick skips FFZ channel',
    () async {
      service.ffzGlobal = {
        'monkaS': const ThirdPartyEmote(
          name: 'monkaS',
          imageUrl: 'https://cdn.frankerfacez.com/emote/monka/2',
        ),
        'OnlyFfz': const ThirdPartyEmote(
          name: 'OnlyFfz',
          imageUrl: 'https://cdn.frankerfacez.com/emote/only/2',
        ),
      };
      service.bttvGlobal = {
        FakeThirdPartyEmoteService.monka.name: FakeThirdPartyEmoteService.monka,
      };

      await store.fetch(broadcasterId: 'user-1');
      expect(
        store.emoteImageUrl('monkaS', broadcasterId: 'user-1'),
        FakeThirdPartyEmoteService.monka.imageUrl,
      );
      expect(
        store.emoteImageUrl('OnlyFfz', broadcasterId: 'user-1'),
        'https://cdn.frankerfacez.com/emote/only/2',
      );
      expect(service.ffzChannelCalls, 1);

      await store.fetch(broadcasterId: '676', isKick: true);
      expect(service.ffzChannelCalls, 1);
    },
  );
}
