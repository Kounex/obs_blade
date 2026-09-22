import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/kick_chat_mode_strip.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_kick_services.dart';

KickChannelInfo channelInfo({
  bool slowMode = false,
  bool followersMode = false,
  bool subscribersMode = false,
  bool emotesMode = false,
}) => KickChannelInfo(
  id: 1,
  slug: 'streamer',
  chatroom: KickChatroom(
    id: 42,
    slowMode: slowMode,
    followersMode: followersMode,
    subscribersMode: subscribersMode,
    emotesMode: emotesMode,
  ),
);

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late KickChatStore store;

  Widget wrap() => const MaterialApp(
    home: Scaffold(body: KickChatModeStrip(accentColor: Colors.purple)),
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kick_mode_strip_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    store = KickChatStore(
      channelService: FakeKickChannelService(),
      apiService: FakeKickApiService(),
      pusherFactory: ({required onEvent, required onStateChanged}) =>
          FakeKickPusherService(
            onEvent: onEvent,
            onStateChanged: onStateChanged,
          ),
      isProResolver: () => true,
    );
    GetIt.instance.registerSingleton<KickChatStore>(store);
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await store.dispose();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('renders nothing when channel info has not resolved yet', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.byType(KickChatModeStrip), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('renders nothing when no mode is active', (tester) async {
    store.channelInfo = channelInfo();
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('shows a single active mode', (tester) async {
    store.channelInfo = channelInfo(slowMode: true);
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('Slow mode'), findsOneWidget);
  });

  testWidgets('joins multiple active modes with a separator', (tester) async {
    store.channelInfo = channelInfo(followersMode: true, emotesMode: true);
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('Followers-only · Emote-only'), findsOneWidget);
  });

  testWidgets('reacts when the store applies a ChatroomUpdatedEvent-style '
      'change', (tester) async {
    store.channelInfo = channelInfo();
    await tester.pumpWidget(wrap());
    await tester.pump();
    expect(find.byType(Icon), findsNothing);

    store.channelInfo = channelInfo(subscribersMode: true);
    await tester.pump();

    expect(find.text('Subscribers-only'), findsOneWidget);
  });
}
