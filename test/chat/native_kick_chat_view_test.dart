import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/kick_chat_message_row.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_kick_chat_view.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_kick_services.dart';

KickChatMessage kickMessage(
  String id, {
  int senderId = 1,
  String? username,
  String? content,
  bool tombstoned = false,
}) => KickChatMessage(
  id: id,
  chatroomId: 42,
  content: content ?? 'text $id',
  createdAt: DateTime.utc(2026, 9, 22, 12),
  sender: KickChatSender(
    id: senderId,
    username: username ?? 'User $senderId',
    slug: 'user-$senderId',
    identity: const KickChatIdentity(color: '#FFAE76'),
  ),
  isTombstoned: tombstoned,
);

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late KickChatStore store;

  Widget wrap() =>
      const MaterialApp(home: Scaffold(body: NativeKickChatView()));

  String renderedRichText(WidgetTester tester) => tester
      .widgetList<RichText>(find.byType(RichText))
      .map((rich) => rich.text.toPlainText())
      .join('\n');

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kick_view_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    store = KickChatStore(
      channelService: FakeKickChannelService(),
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

  testWidgets('connecting with an empty buffer shows the spinner copy', (
    tester,
  ) async {
    store.chatConnection = KickChatConnectionState.connecting;
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('Connecting to Kick chat…'), findsOneWidget);
  });

  testWidgets('offline with an empty buffer explains the missing channel', (
    tester,
  ) async {
    store.chatConnection = KickChatConnectionState.offline;
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(
      find.text(
        'No chat for this channel — the slug may be wrong or the channel is unavailable.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('error with an empty buffer shows the error and a retry', (
    tester,
  ) async {
    store.chatConnection = KickChatConnectionState.error;
    store.chatError = 'Could not resolve the Kick channel';
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('Could not resolve the Kick channel'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('connected timeline renders buffered messages', (tester) async {
    store.chatConnection = KickChatConnectionState.connected;
    store.messages.addAll([kickMessage('m1'), kickMessage('m2')]);
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(renderedRichText(tester), contains('User 1'));
    expect(renderedRichText(tester), contains('text m1'));
    expect(renderedRichText(tester), contains('text m2'));
  });

  testWidgets('tombstoned rows render the dimmed marker', (tester) async {
    store.chatConnection = KickChatConnectionState.connected;
    store.messages.add(kickMessage('m1', tombstoned: true));
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(renderedRichText(tester), contains(' —Deleted'));
  });

  testWidgets('the /clear system row renders its notice', (tester) async {
    store.chatConnection = KickChatConnectionState.connected;
    store.messages.add(
      KickChatMessage(
        id: 'system-clear-1',
        type: KickChatMessageType.system,
        createdAt: DateTime.utc(2026, 9, 22, 12),
      ),
    );
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('Chat was cleared by a moderator'), findsOneWidget);
  });

  testWidgets('emote tokens fall back to their bracketed name when the '
      'image cannot load', (tester) async {
    store.chatConnection = KickChatConnectionState.connected;
    store.messages.add(kickMessage('m1', content: 'hi [emote:37253:UWU]'));
    await tester.pumpWidget(wrap());
    await tester.pump();

    /// flutter_test's HTTP override 400s every image — the row's
    /// errorBuilder keeps the emote name visible.
    expect(renderedRichText(tester), contains('[UWU]'));
    expect(find.byType(KickChatMessageRow), findsOneWidget);
  });
}
