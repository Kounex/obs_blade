import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/kick_emotes.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart'
    show kickEmoteUrl;
import 'package:obs_blade/types/classes/kick/kick_emote.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/kick_emote_picker.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_kick_services.dart';
import 'support/fake_twitch_services.dart' show FakeThirdPartyEmoteService;

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Network images never resolve in tests — the cells are still `Image`
/// widgets whose urls we can read.
List<String> cellUrls(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .map((image) => (image.image as NetworkImage).url)
    .toList();

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late KickEmoteStore emoteStore;
  late ThirdPartyEmoteStore thirdPartyStore;
  late KickChatStore chatStore;
  late TextEditingController controller;

  const channelEmote = KickEmote(id: 1, name: 'xqcL');
  const globalEmote = KickEmote(id: 100, name: 'PogChamp');
  final channelUrl = kickEmoteUrl(channelEmote.id);
  final globalUrl = kickEmoteUrl(globalEmote.id);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kick_emote_picker_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    emoteStore = KickEmoteStore(service: FakeKickEmoteService());
    thirdPartyStore = ThirdPartyEmoteStore(
      service: FakeThirdPartyEmoteService(),
    );
    GetIt.instance.registerSingleton<KickEmoteStore>(emoteStore);
    GetIt.instance.registerSingleton<ThirdPartyEmoteStore>(thirdPartyStore);

    chatStore = KickChatStore(
      channelService: FakeKickChannelService(),
      apiService: FakeKickApiService(),
      pusherFactory: ({required onEvent, required onStateChanged}) =>
          FakeKickPusherService(
            onEvent: onEvent,
            onStateChanged: onStateChanged,
          ),
      isProResolver: () => true,
    );
    chatStore.channelInfo = const KickChannelInfo(
      id: 5,
      userId: 1101,
      slug: 'streamer',
      chatroom: KickChatroom(id: 42),
    );
    GetIt.instance.registerSingleton<KickChatStore>(chatStore);
    controller = TextEditingController();
  });

  tearDown(() async {
    controller.dispose();
    await chatStore.dispose();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  KickEmotePickerSheet buildSheet() =>
      KickEmotePickerSheet(controller: controller, accentColor: Colors.purple);

  void seedCatalogs() {
    emoteStore.sections
      ..add(const KickEmoteSection(label: 'Channel', emotes: [channelEmote]))
      ..add(const KickEmoteSection(label: 'Global', emotes: [globalEmote]));
    thirdPartyStore.channelEmotes['1101'] = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };
  }

  testWidgets('sections render in order with headers and cells', (
    tester,
  ) async {
    seedCatalogs();
    await tester.pumpWidget(wrap(buildSheet()));

    expect(find.text('CHANNEL'), findsOneWidget);
    expect(find.text('GLOBAL'), findsOneWidget);
    expect(find.text('THIRD-PARTY (7TV)'), findsOneWidget);
    expect(
      cellUrls(tester),
      unorderedEquals([
        channelUrl,
        globalUrl,
        FakeThirdPartyEmoteService.peepo.imageUrl,
      ]),
    );
  });

  testWidgets('search filters across sections, case-insensitive', (
    tester,
  ) async {
    seedCatalogs();
    await tester.pumpWidget(wrap(buildSheet()));

    await tester.enterText(find.byType(TextField).first, 'xqc');
    await tester.pump();

    expect(cellUrls(tester), [channelUrl]);
    expect(find.text('CHANNEL'), findsOneWidget);
    expect(find.text('GLOBAL'), findsNothing);
    expect(find.text('THIRD-PARTY (7TV)'), findsNothing);
  });

  testWidgets(
    'tapping cells appends into the draft; Done writes back to the dock',
    (tester) async {
      seedCatalogs();
      controller.text = 'hi ';
      await tester.pumpWidget(wrap(buildSheet()));

      final draft = find.byKey(const Key('kick-emote-draft-field'));
      expect(tester.widget<TextField>(draft).controller!.text, 'hi ');

      await tester.tap(find.byType(Image).first);
      await tester.pump();
      await tester.tap(find.byType(Image).at(1));
      await tester.pump();

      /// Dock stays unchanged until Done.
      expect(controller.text, 'hi ');
      expect(
        tester.widget<TextField>(draft).controller!.text,
        'hi xqcL PogChamp ',
      );

      await tester.tap(find.byKey(const Key('kick-emote-done-button')));
      await tester.pumpAndSettle();

      expect(controller.text, 'hi xqcL PogChamp ');
      expect(find.text('Emotes'), findsNothing);
    },
  );

  testWidgets('third-party section hides when the toggle is off', (
    tester,
  ) async {
    seedCatalogs();

    /// Real file I/O never completes inside the test body's FakeAsync
    /// zone — runAsync escapes it (same pattern as the Twitch picker
    /// test).
    await tester.runAsync(() async {
      await Hive.box(
        HiveKeys.Settings.name,
      ).put(SettingsKeys.KickChatThirdPartyEmotes.name, false);
    });

    await tester.pumpWidget(wrap(buildSheet()));

    expect(find.text('THIRD-PARTY (7TV)'), findsNothing);
    expect(find.text('CHANNEL'), findsOneWidget);
  });

  testWidgets('catalog landing pops the grid in (catalogVersion)', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(buildSheet()));
    expect(find.text('No emotes available'), findsOneWidget);

    emoteStore.sections.add(
      const KickEmoteSection(label: 'Channel', emotes: [channelEmote]),
    );
    emoteStore.catalogVersion++;
    await tester.pump();

    expect(find.text('No emotes available'), findsNothing);
    expect(cellUrls(tester), [channelUrl]);
  });

  testWidgets('empty catalog with a fetch in flight shows a spinner', (
    tester,
  ) async {
    emoteStore.isLoading = true;
    await tester.pumpWidget(wrap(buildSheet()));

    /// Tests run on the android default platform → material spinner.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No emotes available'), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('button opens the sheet and refocuses after Done', (
    tester,
  ) async {
    seedCatalogs();

    /// The focus node must be attached to the tree — requestFocus on a
    /// detached node only defers (hasFocus stays false). Real usage hands
    /// the dock's attached node; here a Focus wrapper attaches it.
    final focusNode = FocusNode();
    await tester.pumpWidget(
      wrap(
        Focus(
          focusNode: focusNode,
          child: KickEmotePickerButton(
            controller: controller,
            focusNode: focusNode,
            accentColor: Colors.purple,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(KickEmotePickerButton));
    await tester.pumpAndSettle();
    expect(find.text('Emotes'), findsOneWidget);

    await tester.tap(find.byType(Image).first);
    await tester.pump();
    expect(controller.text, isEmpty);

    await tester.tap(find.byKey(const Key('kick-emote-done-button')));
    await tester.pumpAndSettle();
    expect(controller.text, 'xqcL ');
    expect(focusNode.hasFocus, isTrue);
  });
}
