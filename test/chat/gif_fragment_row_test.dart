import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';
import 'third_party_emote_row_test.dart' show collectWidgetSpans;

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

const _gif = ChatFragmentGif(
  gifId: '3o7TKsO8DGFD5T7ZmA',
  url: 'https://media.giphy.com/media/3o7TKsO8DGFD5T7ZmA/giphy.gif',
);

ChatMessageEvent _gifEvent() => const ChatMessageEvent(
      broadcasterUserId: 'b1',
      chatterUserId: '1',
      chatterUserLogin: 'viewer',
      chatterUserName: 'Viewer',
      messageId: '1',
      message: ChatMessageText(
        text: 'dance',
        fragments: [
          ChatMessageFragment(type: 'text', text: 'check '),
          ChatMessageFragment(type: 'gif', text: 'dance', gif: _gif),
        ],
      ),
    );

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('gif_fragment_row_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    GetIt.instance.registerSingleton<ThirdPartyEmoteStore>(
      ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService()),
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('a gif fragment becomes an inline image', (tester) async {
    await tester.pumpWidget(
      _wrap(TwitchChatMessageRow(
        event: _gifEvent(),
        settingsBox: Hive.box(HiveKeys.Settings.name),
      )),
    );

    final richText = tester.widget<RichText>(find.byType(RichText));
    expect(richText.text.toPlainText(), 'Viewer: check \u{FFFC}');
    final span = collectWidgetSpans(richText.text).single;
    final image = span.child as Image;
    expect((image.image as NetworkImage).url, _gif.url);
  });

  testWidgets('a gif fragment without the gif object stays text',
      (tester) async {
    const event = ChatMessageEvent(
      broadcasterUserId: 'b1',
      chatterUserId: '1',
      chatterUserLogin: 'viewer',
      chatterUserName: 'Viewer',
      messageId: '1',
      message: ChatMessageText(
        text: 'dance',
        fragments: [ChatMessageFragment(type: 'gif', text: 'dance')],
      ),
    );

    await tester.pumpWidget(
      _wrap(TwitchChatMessageRow(
        event: event,
        settingsBox: Hive.box(HiveKeys.Settings.name),
      )),
    );

    final richText = tester.widget<RichText>(find.byType(RichText));
    expect(richText.text.toPlainText(), 'Viewer: dance');
    expect(collectWidgetSpans(richText.text), isEmpty);
  });
}
