import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/kick_auth.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/kick_native_channel_dropdown.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_kick_services.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

KickChannelInfo channelInfo(
  String slug, {
  int id = 101,
  int chatroomId = 42,
  bool isLive = true,
  int? viewerCount = 1234,
}) => KickChannelInfo(
  id: id,
  userId: id + 1000,
  slug: slug,
  chatroom: KickChatroom(id: chatroomId),
  livestream: KickLivestreamInfo(isLive: isLive, viewerCount: viewerCount),
);

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeKickChannelService channelService;
  late KickChatStore store;

  /// FakeAsync-zone Hive close dance (see native_chat_options_sheet_test).
  Future<void> closeHiveInZone(WidgetTester tester) async {
    var closed = false;
    unawaited(harness.close().then((_) => closed = true));
    for (var i = 0; i < 10 && !closed; i++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
    }
    await tester.pump();
    expect(closed, isTrue);
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'kick_channel_dropdown_test',
    );
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.openBox<KickAuth>(HiveKeys.KickAuth.name);
    channelService = FakeKickChannelService();

    /// [isProResolver] true, but no network fetch is exercised for the
    /// live preview here — the store's own poll (network + fake-async
    /// timers) is covered at the store level (kick_chat_store_test.dart).
    /// This widget test drives [KickChatStore.channelLivePreview]
    /// directly, since that's exactly what the dropdown reads. A fake
    /// [pusherFactory] is still required: [selectChannel] connects a
    /// socket, and the default factory opens a real one.
    store = KickChatStore(
      channelService: channelService,
      isProResolver: () => true,
      pusherFactory: ({required onEvent, required onStateChanged}) =>
          FakeKickPusherService(
            onEvent: onEvent,
            onStateChanged: onStateChanged,
          ),
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

  testWidgets(
    'LIVE + viewer chip shows for a live channel, only in the open menu',
    (tester) async {
      store.channels.addAll(['aaa', 'bbb']);
      store.channelLivePreview['aaa'] = channelInfo('aaa', viewerCount: 1200);
      store.channelLivePreview['bbb'] = channelInfo(
        'bbb',
        isLive: false,
        viewerCount: null,
      );

      await tester.pumpWidget(
        wrap(const Column(children: [KickNativeChannelDropdown()])),
      );
      await tester.pump();

      /// Closed control: name only — no status chip.
      expect(find.text('LIVE'), findsNothing);

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.byKey(const Key('kick-channel-dropdown-live-aaa')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('kick-channel-dropdown-live-bbb')),
        findsNothing,
      );
    },
  );

  testWidgets('no chip while the preview has not resolved yet', (tester) async {
    store.channels.add('aaa');
    // channelLivePreview deliberately left empty for 'aaa'.

    await tester.pumpWidget(
      wrap(const Column(children: [KickNativeChannelDropdown()])),
    );
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pump();

    expect(
      find.byKey(const Key('kick-channel-dropdown-live-aaa')),
      findsNothing,
    );
  });

  testWidgets('selecting a channel calls selectChannel', (tester) async {
    try {
      channelService.channels['aaa'] = channelInfo('aaa');
      store.channels.add('aaa');

      await tester.pumpWidget(
        wrap(const Column(children: [KickNativeChannelDropdown()])),
      );
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('aaa').last);
      await tester.pumpAndSettle();

      expect(store.selectedChannelSlug, 'aaa');
    } finally {
      await closeHiveInZone(tester);
    }
  });

  testWidgets('the own channel leads the list marked "You"', (tester) async {
    store.channels.addAll(['aaa']);
    store.ownChannelSlug = 'kicker';
    store.selectedChannelSlug = 'kicker';

    await tester.pumpWidget(
      wrap(const Column(children: [KickNativeChannelDropdown()])),
    );
    await tester.pump();

    /// Closed control: selected own channel carries the marker.
    expect(find.text('kicker'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final kicker = tester.getTopLeft(find.text('kicker').last);
    final added = tester.getTopLeft(find.text('aaa').last);
    expect(kicker.dy, lessThan(added.dy));
    expect(find.text('You'), findsWidgets);
  });
}
