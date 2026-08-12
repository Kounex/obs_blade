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

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

ChatMessageEvent _event({String? sourceId, String? sourceName}) =>
    ChatMessageEvent(
      broadcasterUserId: 'b1',
      chatterUserId: '1',
      chatterUserLogin: 'viewer',
      chatterUserName: 'Viewer',
      messageId: '1',
      sourceBroadcasterUserId: sourceId,
      sourceBroadcasterUserLogin: sourceId == null ? null : 'partner',
      sourceBroadcasterUserName: sourceName,
      message: const ChatMessageText(
        text: 'hi',
        fragments: [ChatMessageFragment(type: 'text', text: 'hi')],
      ),
    );

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('shared_chat_row_test');
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

  Future<void> pumpRow(WidgetTester tester, ChatMessageEvent event) =>
      tester.pumpWidget(
        _wrap(TwitchChatMessageRow(
          event: event,
          settingsBox: Hive.box(HiveKeys.Settings.name),
        )),
      );

  testWidgets('a partner-channel message shows a source chip',
      (tester) async {
    await pumpRow(tester, _event(sourceId: 'b2', sourceName: 'Partner'));

    expect(find.text('#Partner'), findsOneWidget);
    expect(
      tester
          .widgetList<RichText>(find.byType(RichText))
          .map((rich) => rich.text.toPlainText()),
      contains(contains('Viewer: hi')),
    );
  });

  testWidgets('a same-channel message shows no chip', (tester) async {
    await pumpRow(tester, _event());

    expect(find.textContaining('#'), findsNothing);
  });

  testWidgets('a source id matching the viewed channel shows no chip',
      (tester) async {
    await pumpRow(tester, _event(sourceId: 'b1', sourceName: 'Viewer'));

    expect(find.textContaining('#'), findsNothing);
  });

  testWidgets('the chip does not change the row height', (tester) async {
    await pumpRow(tester, _event());
    final withoutChip = tester.getSize(find.byType(TwitchChatMessageRow));

    await pumpRow(tester, _event(sourceId: 'b2', sourceName: 'Partner'));
    final withChip = tester.getSize(find.byType(TwitchChatMessageRow));

    expect(withChip.height, withoutChip.height);
  });
}
