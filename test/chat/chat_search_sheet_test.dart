import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_search_sheet.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';

ChatMessageEvent twitchMessage(String id, String author, String text) =>
    ChatMessageEvent(
      broadcasterUserId: 'b1',
      chatterUserId: id,
      chatterUserLogin: author.toLowerCase(),
      chatterUserName: author,
      messageId: id,
      message: ChatMessageText(
        text: text,
        fragments: [ChatMessageFragment(type: 'text', text: text)],
      ),
    );

KickChatMessage kickMessage(
  String id, {
  String author = 'Chatter',
  String? content,
  KickChatMessageType type = KickChatMessageType.message,
}) => KickChatMessage(
  id: id,
  content: content ?? 'text $id',
  type: type,
  sender: KickChatSender(id: 1, username: author),
);

YouTubeChatMessage ytMessage(String id, String author, String text) =>
    YouTubeChatMessage(
      id: id,
      snippet: YouTubeChatMessageSnippet(
        type: YouTubeChatMessageType.textMessage,
        publishedAt: DateTime.utc(2026, 9, 3),
        authorChannelId: 'chan-$id',
        displayMessage: text,
        textMessageDetails: YouTubeTextMessageDetails(messageText: text),
      ),
      authorDetails: YouTubeChatAuthorDetails(
        channelId: 'chan-$id',
        displayName: author,
      ),
    );

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Plain-text of every rendered RichText — the rows build their content
/// as Text.rich, which `find.text` doesn't see for the plain-TextSpan
/// author name (same idiom as the row test files' `renderedRichText`).
String renderedRichText(WidgetTester tester) => tester
    .widgetList<RichText>(find.byType(RichText))
    .map((rich) => rich.text.toPlainText())
    .join('\n');

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chat_search_sheet_test');
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

  testWidgets('typing nothing shows the empty prompt, not results', (
    tester,
  ) async {
    final store = TwitchChatStore();
    store.messages.add(twitchMessage('1', 'Viewer', 'hello world'));
    GetIt.instance.registerSingleton<TwitchChatStore>(store);

    await tester.pumpWidget(
      wrap(const ChatSearchSheet(chatType: ChatType.Twitch)),
    );
    await tester.pump();

    expect(
      find.text('Type to search the buffered chat history'),
      findsOneWidget,
    );
    expect(renderedRichText(tester), isNot(contains('Viewer')));
  });

  testWidgets('Twitch: matches content and author, case-insensitively', (
    tester,
  ) async {
    final store = TwitchChatStore();
    store.messages.addAll([
      twitchMessage('1', 'Viewer', 'check out my GIVEAWAY'),
      twitchMessage('2', 'Other', 'just saying hi'),
    ]);
    GetIt.instance.registerSingleton<TwitchChatStore>(store);

    await tester.pumpWidget(
      wrap(const ChatSearchSheet(chatType: ChatType.Twitch)),
    );
    await tester.enterText(
      find.byKey(const Key('chat-search-field')),
      'giveaway',
    );
    await tester.pump();

    final rendered = renderedRichText(tester);
    expect(rendered, contains('Viewer'));
    expect(rendered, isNot(contains('Other')));
  });

  testWidgets('no matches shows the empty state', (tester) async {
    final store = TwitchChatStore();
    store.messages.add(twitchMessage('1', 'Viewer', 'hello world'));
    GetIt.instance.registerSingleton<TwitchChatStore>(store);

    await tester.pumpWidget(
      wrap(const ChatSearchSheet(chatType: ChatType.Twitch)),
    );
    await tester.enterText(
      find.byKey(const Key('chat-search-field')),
      'nonexistent',
    );
    await tester.pump();

    expect(find.text('No matches'), findsOneWidget);
  });

  testWidgets('Kick: matches content, excludes system rows', (tester) async {
    final store = KickChatStore();
    store.messages.addAll([
      kickMessage('1', author: 'Viewer', content: 'my giveaway is live'),
      KickChatMessage(
        id: 'system-1',
        type: KickChatMessageType.system,
        content: 'giveaway notice',
      ),
    ]);
    GetIt.instance.registerSingleton<KickChatStore>(store);

    await tester.pumpWidget(
      wrap(const ChatSearchSheet(chatType: ChatType.Kick)),
    );
    await tester.enterText(
      find.byKey(const Key('chat-search-field')),
      'giveaway',
    );
    await tester.pump();

    final rendered = renderedRichText(tester);
    expect(rendered, contains('Viewer'));
    expect(rendered, isNot(contains('notice')));
  });

  testWidgets('YouTube: matches content and author', (tester) async {
    final store = YouTubeChatStore();
    store.messages.addAll([
      ytMessage('1', 'Spammer', 'check my giveaway'),
      ytMessage('2', 'Regular', 'hello there'),
    ]);
    GetIt.instance.registerSingleton<YouTubeChatStore>(store);

    await tester.pumpWidget(
      wrap(const ChatSearchSheet(chatType: ChatType.YouTube)),
    );
    await tester.enterText(
      find.byKey(const Key('chat-search-field')),
      'giveaway',
    );
    await tester.pump();

    final rendered = renderedRichText(tester);
    expect(rendered, contains('Spammer'));
    expect(rendered, isNot(contains('Regular')));
  });
}
