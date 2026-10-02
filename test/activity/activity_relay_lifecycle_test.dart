import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/kick_auth.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/views/activity.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/kick_emotes.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/activity/activity_persistence.dart';
import 'package:obs_blade/utils/kick/kick_auth_service.dart';
import 'package:obs_blade/utils/kick/kick_events_relay_client.dart';

import '../chat/support/fake_kick_services.dart';
import '../chat/support/fake_twitch_services.dart'
    show FakeThirdPartyEmoteService;
import '../persistence/support/hive_test_harness.dart';

/// Records what the store asks of the relay; never touches the network.
class _RecordingRelay extends KickEventsRelayClient {
  final List<String> unregistered = [];
  final List<String> started = [];
  int registers = 0;

  @override
  Future<KickRelaySession> register(String kickAccessToken) async {
    this.registers++;
    return const KickRelaySession(
      token: 'fresh',
      broadcasterUserId: '9001',
      username: 'kicker',
      subscribed: true,
    );
  }

  @override
  Future<void> unregister(String sessionToken) async =>
      this.unregistered.add(sessionToken);

  @override
  void start({
    required String sessionToken,
    required int Function() cursor,
    required void Function(Map<String, Object?> frame) onEvent,
    required void Function(KickRelayState state) onState,
    required void Function() onUnknownSession,
  }) {
    this.started.add('$sessionToken@${cursor()}');
    onState(KickRelayState.synced);
  }

  @override
  Future<void> stop() async {}
}

Future<void> _until(bool Function() condition) async {
  for (var i = 0; i < 2000 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late MemoryActivityPersistence persistence;
  late _RecordingRelay relay;
  late ActivityStore activity;
  late FakeKickChannelService channelService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('activity_relay');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.openBox<KickAuth>(HiveKeys.KickAuth.name);
    await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
    persistence = MemoryActivityPersistence();
    relay = _RecordingRelay();
    channelService = FakeKickChannelService();
    channelService.channels['kicker'] = KickChannelInfo(
      id: 77,
      userId: 9001,
      slug: 'kicker',
      username: 'kicker',
      chatroom: const KickChatroom(id: 42),
    );

    /// A relay session from the previous run, 12 events in
    await persistence.putMeta('state', {
      'startedAt': DateTime.now().toUtc().toIso8601String(),
      'seq': 0,
      'relay': {'token': 'kept', 'userId': '9001', 'cursor': 12},
    });
  });

  tearDown(() async {
    await activity.dispose();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  void registerKick() {
    GetIt.instance.registerLazySingleton<KickChatStore>(
      () => KickChatStore(
        channelService: channelService,
        authService: FakeKickAuthService(),
        apiService: FakeKickApiService(),
        pusherFactory: ({required onEvent, required onStateChanged}) =>
            FakeKickPusherService(
              onEvent: onEvent,
              onStateChanged: onStateChanged,
            ),
        isProResolver: () => true,
        emoteStoreResolver: () =>
            ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService()),
        kickEmoteStoreResolver: () =>
            KickEmoteStore(service: FakeKickEmoteService()),
      )..init(),
      onCreated: (_) => activity.chatStoreCreated(),
    );
  }

  ActivityStore build() => ActivityStore(
    persistence: persistence,
    isProResolver: () => true,
    relayClient: relay,
    relayEnabledResolver: () => true,
  );

  test(
    'launch while signed in keeps the relay session and its backlog',
    () async {
      await Hive.box<KickAuth>(HiveKeys.KickAuth.name).put(
        KickAuth.kBoxKey,
        KickAuth(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
          scopes: kKickChatScopes,
          userId: 9001,
          username: 'kicker',
        ),
      );
      registerKick();
      activity = build();
      await activity.init();
      await _until(() => relay.started.isNotEmpty);

      expect(relay.unregistered, isEmpty);
      expect(relay.registers, 0);
      expect(relay.started, ['kept@12']);
    },
  );

  test('signed out of Kick: the relay forgets the channel', () async {
    registerKick();
    activity = build();
    await activity.init();
    await _until(() => relay.unregistered.isNotEmpty);
    expect(relay.unregistered, ['kept']);
    expect(relay.started, isEmpty);
  });
}
