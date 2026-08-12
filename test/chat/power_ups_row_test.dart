import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_appearance.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';
import 'third_party_emote_row_test.dart' show collectWidgetSpans;

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

ChatMessageEvent _emoteEvent(String messageType) => ChatMessageEvent(
      broadcasterUserId: 'b1',
      chatterUserId: '1',
      chatterUserLogin: 'viewer',
      chatterUserName: 'Viewer',
      messageId: '1',
      messageType: messageType,
      message: const ChatMessageText(
        text: 'Kappa',
        fragments: [
          ChatMessageFragment(
            type: 'emote',
            text: 'Kappa',
            emote: ChatFragmentEmote(id: '25'),
          ),
        ],
      ),
    );

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('power_ups_row_test');
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

  Future<Image> pumpEmoteImage(WidgetTester tester, String messageType) async {
    await tester.pumpWidget(
      _wrap(TwitchChatMessageRow(
        event: _emoteEvent(messageType),
        settingsBox: Hive.box(HiveKeys.Settings.name),
      )),
    );
    final richText = tester.widget<RichText>(find.byType(RichText));
    final span = collectWidgetSpans(richText.text).single;
    return span.child as Image;
  }

  testWidgets('a plain emote renders at the configured emote size',
      (tester) async {
    final image = await pumpEmoteImage(tester, 'text');

    expect(image.height, NativeChatAppearance.emoteSizeDefault);
  });

  testWidgets('a gigantified power-up emote renders 3x', (tester) async {
    final image = await pumpEmoteImage(tester, 'power_ups_gigantified_emote');

    expect(image.height, NativeChatAppearance.emoteSizeDefault * 3.0);
    expect((image.image as NetworkImage).url,
        'https://static-cdn.jtvnw.net/emoticons/v2/25/default/dark/2.0');
  });

  testWidgets('a message-effect power-up renders as a normal message',
      (tester) async {
    final image = await pumpEmoteImage(tester, 'power_ups_message_effect');

    expect(image.height, NativeChatAppearance.emoteSizeDefault);
  });
}
