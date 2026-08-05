import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/types/classes/twitch/twitch_chat_badges.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';

import 'support/fake_twitch_services.dart';

void main() {
  late FakeTwitchBadgeService service;
  late TwitchBadgeStore store;

  setUp(() {
    service = FakeTwitchBadgeService();
    store = TwitchBadgeStore(service: service);
  });

  test('fetch applies global and channel catalogs', () async {
    service.globalSets = [FakeTwitchBadgeService.moderatorSet];
    service.channelSets = [FakeTwitchBadgeService.subscriberSet];

    await store.fetch(accessToken: 'token-1', broadcasterId: 'user-1');

    expect(service.lastAccessToken, 'token-1');
    expect(service.lastBroadcasterId, 'user-1');
    expect(store.badgeVersion('moderator', '1')?.imageUrl2x,
        'https://badges.example/mod/2x.png');
    expect(store.badgeVersion('subscriber', '12')?.imageUrl2x,
        'https://badges.example/sub/2x.png');
    expect(store.isLoading, isFalse);
  });

  test('channel catalog wins over global for the same set id', () async {
    service.globalSets = [FakeTwitchBadgeService.moderatorSet];
    service.channelSets = [FakeTwitchBadgeService.moderatorChannelOverrideSet];

    await store.fetch(accessToken: 'token-1', broadcasterId: 'user-1');

    expect(store.badgeVersion('moderator', '1')?.imageUrl2x,
        'https://badges.example/mod-override/2x.png');
  });

  test('unknown badges resolve to null', () async {
    await store.fetch(accessToken: 'token-1', broadcasterId: 'user-1');

    expect(store.badgeVersion('vip', '1'), isNull);
    expect(store.badgeVersion('moderator', '99'), isNull);
  });

  test('a failing channel fetch keeps the global catalog', () async {
    service.globalSets = [FakeTwitchBadgeService.moderatorSet];
    service.channelThrows =
        const TwitchAuthException('denied', statusCode: 401);

    await store.fetch(accessToken: 'token-1', broadcasterId: 'user-1');

    expect(store.badgeVersion('moderator', '1'), isNotNull);
    expect(store.isLoading, isFalse);
  });

  test('a superseded fetch cannot overwrite the newer catalog', () async {
    final gate = Completer<List<TwitchBadgeSet>>();
    service.globalGate = gate;
    final first = store.fetch(accessToken: 'token-1', broadcasterId: 'user-1');

    service.globalGate = null;
    service.globalSets = [FakeTwitchBadgeService.moderatorSet];
    await store.fetch(accessToken: 'token-2', broadcasterId: 'user-1');

    gate.complete([FakeTwitchBadgeService.subscriberSet]);
    await first;

    expect(store.badgeVersion('moderator', '1'), isNotNull);
    expect(store.badgeVersion('subscriber', '12'), isNull);
    expect(store.isLoading, isFalse);
  });

  test('clear drops both catalogs', () async {
    service.globalSets = [FakeTwitchBadgeService.moderatorSet];
    service.channelSets = [FakeTwitchBadgeService.subscriberSet];
    await store.fetch(accessToken: 'token-1', broadcasterId: 'user-1');
    expect(store.globalBadges, isNotEmpty);

    store.clear();

    expect(store.globalBadges, isEmpty);
    expect(store.channelBadges, isEmpty);
  });
}
