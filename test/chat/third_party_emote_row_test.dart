import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// `Text.rich` wraps the passed span in an outer TextSpan carrying the
/// ambient style, so the row's spans sit one level down.
List<WidgetSpan> collectWidgetSpans(InlineSpan span) {
  final spans = <WidgetSpan>[];
  void visit(InlineSpan s) {
    if (s is WidgetSpan) spans.add(s);
    if (s is TextSpan) s.children?.forEach(visit);
  }

  visit(span);
  return spans;
}

ChatMessageEvent textEvent(String text) => ChatMessageEvent(
      broadcasterUserId: 'b1',
      chatterUserId: '1',
      chatterUserLogin: 'viewer',
      chatterUserName: 'Viewer',
      messageId: '1',
      message: ChatMessageText(
        text: text,
        fragments: [ChatMessageFragment(type: 'text', text: text)],
      ),
    );

void main() {
  late ThirdPartyEmoteStore emoteStore;
  late Directory tempDir;
  late HiveTestHarness harness;

  setUp(() async {
    tempDir = await Directory.systemTemp
        .createTemp('third_party_emote_row_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    emoteStore = ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService());
    GetIt.instance.registerSingleton<ThirdPartyEmoteStore>(emoteStore);
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<RichText> pumpRow(WidgetTester tester, String text) async {
    await tester.pumpWidget(
      wrap(TwitchChatMessageRow(
        event: textEvent(text),
        settingsBox: Hive.box(HiveKeys.Settings.name),
      )),
    );
    return tester.widget<RichText>(find.byType(RichText));
  }

  testWidgets('a known token becomes an inline image', (tester) async {
    emoteStore.emotes['peepoHappy'] = FakeThirdPartyEmoteService.peepo;

    final richText = await pumpRow(tester, 'hi peepoHappy');

    expect(richText.text.toPlainText(), 'Viewer: hi \u{FFFC}');
    final span = collectWidgetSpans(richText.text).single;
    final image = span.child as Image;
    expect((image.image as NetworkImage).url,
        FakeThirdPartyEmoteService.peepo.imageUrl);
  });

  testWidgets('multiple emote tokens in one message', (tester) async {
    emoteStore.emotes['peepoHappy'] = FakeThirdPartyEmoteService.peepo;
    emoteStore.emotes['monkaS'] = FakeThirdPartyEmoteService.monka;

    final richText = await pumpRow(tester, 'peepoHappy and monkaS');

    expect(richText.text.toPlainText(), 'Viewer: \u{FFFC} and \u{FFFC}');
    expect(collectWidgetSpans(richText.text), hasLength(2));
  });

  testWidgets('unknown tokens and wrong case stay text', (tester) async {
    emoteStore.emotes['peepoHappy'] = FakeThirdPartyEmoteService.peepo;

    final richText = await pumpRow(tester, 'PeepoHappy peepoHappyy');

    expect(richText.text.toPlainText(), 'Viewer: PeepoHappy peepoHappyy');
    expect(collectWidgetSpans(richText.text), isEmpty);
  });

  testWidgets('punctuation-glued tokens stay text', (tester) async {
    emoteStore.emotes['peepoHappy'] = FakeThirdPartyEmoteService.peepo;

    final richText = await pumpRow(tester, 'peepoHappy!');

    expect(richText.text.toPlainText(), 'Viewer: peepoHappy!');
    expect(collectWidgetSpans(richText.text), isEmpty);
  });

  testWidgets('spacing is preserved exactly', (tester) async {
    emoteStore.emotes['peepoHappy'] = FakeThirdPartyEmoteService.peepo;

    final richText = await pumpRow(tester, 'a  peepoHappy  b');

    expect(richText.text.toPlainText(), 'Viewer: a  \u{FFFC}  b');
  });

  testWidgets('toggle off keeps everything text', (tester) async {
    emoteStore.emotes['peepoHappy'] = FakeThirdPartyEmoteService.peepo;

    /// Real file I/O never completes inside the test body's FakeAsync
    /// zone — runAsync escapes it (same pattern as the badge tests).
    await tester.runAsync(() async {
      await Hive.box(HiveKeys.Settings.name)
          .put(SettingsKeys.TwitchChatThirdPartyEmotes.name, false);
    });

    final richText = await pumpRow(tester, 'hi peepoHappy');

    expect(richText.text.toPlainText(), 'Viewer: hi peepoHappy');
    expect(collectWidgetSpans(richText.text), isEmpty);
  });

  testWidgets('first-party emote fragments are untouched', (tester) async {
    emoteStore.emotes['peepoHappy'] = FakeThirdPartyEmoteService.peepo;
    final event = ChatMessageEvent(
      broadcasterUserId: 'b1',
      chatterUserId: '1',
      chatterUserLogin: 'viewer',
      chatterUserName: 'Viewer',
      messageId: '1',
      message: ChatMessageText(
        text: 'Kappa peepoHappy',
        fragments: [
          ChatMessageFragment(
            type: 'emote',
            text: 'Kappa',
            emote: ChatFragmentEmote(id: '25'),
          ),
          ChatMessageFragment(type: 'text', text: ' peepoHappy'),
        ],
      ),
    );

    await tester.pumpWidget(
      wrap(TwitchChatMessageRow(
        event: event,
        settingsBox: Hive.box(HiveKeys.Settings.name),
      )),
    );

    final richText = tester.widget<RichText>(find.byType(RichText));
    final spans = collectWidgetSpans(richText.text);
    expect(spans, hasLength(2));
    expect(
      ((spans[0].child as Image).image as NetworkImage).url,
      'https://static-cdn.jtvnw.net/emoticons/v2/25/default/dark/2.0',
    );
    expect(
      ((spans[1].child as Image).image as NetworkImage).url,
      FakeThirdPartyEmoteService.peepo.imageUrl,
    );
  });
}
