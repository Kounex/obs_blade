import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/stores/views/twitch_emotes.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_emote_picker.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';

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
  late FakeTwitchEmoteService userEmoteService;
  late TwitchEmoteStore emoteStore;
  late ThirdPartyEmoteStore thirdPartyStore;
  late TextEditingController controller;

  String kappaUrl = twitchEmoteUrl(FakeTwitchEmoteService.channelEmote.id);
  String pogUrl = twitchEmoteUrl(FakeTwitchEmoteService.globalEmote.id);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chat_emote_picker_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    userEmoteService = FakeTwitchEmoteService();
    emoteStore = TwitchEmoteStore(service: userEmoteService);
    thirdPartyStore =
        ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService());
    GetIt.instance.registerSingleton<TwitchEmoteStore>(emoteStore);
    GetIt.instance.registerSingleton<ThirdPartyEmoteStore>(thirdPartyStore);

    /// The picker reads the viewed channel's id off the chat store — a
    /// logged-out store falls back to the global catalog (which is what
    /// these tests seed).
    GetIt.instance.registerSingleton<TwitchChatStore>(TwitchChatStore());
    controller = TextEditingController();
  });

  tearDown(() async {
    controller.dispose();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  ChatEmotePickerSheet buildSheet({
    bool canReadEmotes = true,
    VoidCallback? onRelogin,
  }) =>
      ChatEmotePickerSheet(
        controller: controller,
        canReadEmotes: canReadEmotes,
        accentColor: Colors.purple,
        onRelogin: onRelogin ?? () {},
      );

  void seedCatalogs() {
    emoteStore.channelEmotes.add(FakeTwitchEmoteService.channelEmote);
    emoteStore.globalEmotes.add(FakeTwitchEmoteService.globalEmote);
    thirdPartyStore.globalEmotes[FakeThirdPartyEmoteService.peepo.name] =
        FakeThirdPartyEmoteService.peepo;
  }

  testWidgets('sections render in order with headers and cells',
      (tester) async {
    seedCatalogs();
    await tester.pumpWidget(wrap(buildSheet()));

    expect(find.text('Channel'), findsOneWidget);
    expect(find.text('Global'), findsOneWidget);
    expect(find.text('Third-party (7TV/BTTV)'), findsOneWidget);
    expect(
      cellUrls(tester),
      unorderedEquals([
        kappaUrl,
        pogUrl,
        FakeThirdPartyEmoteService.peepo.imageUrl,
      ]),
    );
  });

  testWidgets('search filters across sections, case-insensitive',
      (tester) async {
    seedCatalogs();
    await tester.pumpWidget(wrap(buildSheet()));

    await tester.enterText(
        find.byType(TextField).first, 'kappa');
    await tester.pump();

    expect(cellUrls(tester), [kappaUrl]);
    expect(find.text('Channel'), findsOneWidget);
    expect(find.text('Global'), findsNothing);
    expect(find.text('Third-party (7TV/BTTV)'), findsNothing);
  });

  testWidgets('tapping a cell inserts code + space at the cursor',
      (tester) async {
    seedCatalogs();
    controller
      ..text = 'hi there'
      ..selection = const TextSelection.collapsed(offset: 2);
    await tester.pumpWidget(wrap(buildSheet()));

    await tester.tap(find.byType(Image).first);
    await tester.pump();

    expect(controller.text, 'hiKappa  there');
    expect(controller.selection.baseOffset, 8);
  });

  testWidgets('appends at the end when the controller has no selection',
      (tester) async {
    seedCatalogs();
    controller.text = 'hi';
    await tester.pumpWidget(wrap(buildSheet()));

    await tester.tap(find.byType(Image).first);
    await tester.pump();

    expect(controller.text, 'hiKappa ');
  });

  testWidgets(
      'pre-upgrade token shows the re-login CTA; third-party stays visible',
      (tester) async {
    var relogin = false;
    seedCatalogs();
    await tester.pumpWidget(
      wrap(buildSheet(canReadEmotes: false, onRelogin: () => relogin = true)),
    );

    expect(
      find.text('Log in again to load your Twitch emotes'),
      findsOneWidget,
    );
    expect(find.text('Channel'), findsNothing);
    expect(find.text('Global'), findsNothing);
    expect(find.text('Third-party (7TV/BTTV)'), findsOneWidget);

    await tester.tap(find.text('Re-login'));
    await tester.pump();
    expect(relogin, isTrue);
  });

  testWidgets('third-party section hides when the toggle is off',
      (tester) async {
    seedCatalogs();

    /// Real file I/O never completes inside the test body's FakeAsync
    /// zone — runAsync escapes it (same pattern as the badge tests).
    await tester.runAsync(() async {
      await Hive.box(HiveKeys.Settings.name)
          .put(SettingsKeys.TwitchChatThirdPartyEmotes.name, false);
    });

    await tester.pumpWidget(wrap(buildSheet()));

    expect(find.text('Third-party (7TV/BTTV)'), findsNothing);
    expect(find.text('Channel'), findsOneWidget);
  });

  testWidgets('catalog landing pops the grid in (catalogVersion)',
      (tester) async {
    await tester.pumpWidget(wrap(buildSheet()));
    expect(find.text('No emotes available'), findsOneWidget);

    emoteStore.channelEmotes.add(FakeTwitchEmoteService.channelEmote);
    emoteStore.catalogVersion++;
    await tester.pump();

    expect(find.text('No emotes available'), findsNothing);
    expect(cellUrls(tester), [kappaUrl]);
  });

  testWidgets('empty catalog with a fetch in flight shows a spinner',
      (tester) async {
    emoteStore.isLoading = true;
    await tester.pumpWidget(wrap(buildSheet()));

    /// Tests run on the android default platform → material spinner.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No emotes available'), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('button opens the sheet and refocuses after an insert',
      (tester) async {
    seedCatalogs();

    /// The focus node must be attached to the tree — requestFocus on a
    /// detached node only defers (hasFocus stays false). Real usage hands
    /// the dock's attached node; here a Focus wrapper attaches it.
    final focusNode = FocusNode();
    await tester.pumpWidget(
      wrap(Focus(
        focusNode: focusNode,
        child: ChatEmotePickerButton(
          controller: controller,
          focusNode: focusNode,
          canReadEmotes: true,
          accentColor: Colors.purple,
          onRelogin: () {},
        ),
      )),
    );

    await tester.tap(find.byType(ChatEmotePickerButton));
    await tester.pumpAndSettle();
    expect(find.text('Emotes'), findsOneWidget);

    await tester.tap(find.byType(Image).first);
    await tester.pumpAndSettle();
    expect(controller.text, 'Kappa ');
    expect(focusNode.hasFocus, isTrue);
  });
}
