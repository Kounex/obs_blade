import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/youtube_auth.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/youtube_target.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/youtube_native_channel_dropdown.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_youtube_services.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late YouTubeChatStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'youtube_channel_dropdown_test',
    );
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.openBox<YouTubeAuth>(HiveKeys.YouTubeAuth.name);

    /// The dropdown only reads store state — observables are driven
    /// directly (no selectChannel, so no poll loop / Hive writes inside
    /// the fake-async zone).
    store = YouTubeChatStore(
      authService: FakeYouTubeAuthService(),
      chatService: FakeYouTubeLiveChatService(),
      liveResolver: FakeYouTubeLiveResolver(),
      isProResolver: () => true,
    );
    GetIt.instance.registerSingleton<YouTubeChatStore>(store);
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await store.dispose();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('the own channel leads the list by title, marked "You"', (
    tester,
  ) async {
    store.channels.add(
      const YouTubeChatChannel(
        label: 'Friend',
        target: YouTubeChannelTarget('@friend'),
      ),
    );
    store.ownChannel = const YouTubeChatChannel(
      label: kYouTubeOwnChannelLabel,
      target: YouTubeChannelTarget('channel/UCownchannel000000000000'),
      isOwn: true,
      title: 'My Channel',
    );
    store.selectedChannelLabel = kYouTubeOwnChannelLabel;

    await tester.pumpWidget(
      wrap(const Column(children: [YouTubeNativeChannelDropdown()])),
    );
    await tester.pump();

    /// Closed control: the title, never the reserved label.
    expect(find.text('My Channel'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text(kYouTubeOwnChannelLabel), findsNothing);

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final own = tester.getTopLeft(find.text('My Channel').last);
    final added = tester.getTopLeft(find.text('Friend').last);
    expect(own.dy, lessThan(added.dy));
  });

  testWidgets('signed out: only the added entries, no "You"', (tester) async {
    store.channels.add(
      const YouTubeChatChannel(
        label: 'Friend',
        target: YouTubeChannelTarget('@friend'),
      ),
    );
    store.selectedChannelLabel = 'Friend';

    await tester.pumpWidget(
      wrap(const Column(children: [YouTubeNativeChannelDropdown()])),
    );
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('You'), findsNothing);
    expect(find.text('Friend'), findsWidgets);
  });
}
