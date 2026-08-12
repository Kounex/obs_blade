import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_message_display.dart';

void main() {
  ChatMessageEvent message({
    ChatMessageReply? reply,
    required List<ChatMessageFragment> fragments,
  }) =>
      ChatMessageEvent(
        broadcasterUserId: 'b1',
        chatterUserId: 'c1',
        chatterUserLogin: 'alice',
        chatterUserName: 'Alice',
        messageId: 'm1',
        message: ChatMessageText(
          text: fragments.map((f) => f.text).join(),
          fragments: fragments,
        ),
        reply: reply,
      );

  final reply = ChatMessageReply(
    parentMessageId: 'p1',
    parentMessageBody: 'hi',
    parentUserId: 'bob-id',
    parentUserName: 'Bob',
    parentUserLogin: 'bob',
    threadMessageId: 'p1',
    threadUserId: 'bob-id',
    threadUserName: 'Bob',
    threadUserLogin: 'bob',
  );

  test('reply drops the parent @mention and a leading space', () {
    final event = message(
      reply: reply,
      fragments: const [
        ChatMessageFragment(
          type: 'mention',
          text: '@Bob',
          mention: ChatFragmentMention(
            userId: 'bob-id',
            userLogin: 'bob',
            userName: 'Bob',
          ),
        ),
        ChatMessageFragment(type: 'text', text: ' thanks!'),
      ],
    );
    final shown = fragmentsForChatDisplay(event);
    expect(shown.map((f) => f.text).toList(), ['thanks!']);
  });

  test('non-reply keeps @mentions; reply keeps other @mentions', () {
    final tagOnly = message(
      fragments: const [
        ChatMessageFragment(
          type: 'mention',
          text: '@Bob',
          mention: ChatFragmentMention(
            userId: 'bob-id',
            userLogin: 'bob',
            userName: 'Bob',
          ),
        ),
        ChatMessageFragment(type: 'text', text: ' hey'),
      ],
    );
    expect(fragmentsForChatDisplay(tagOnly), hasLength(2));

    final replyPlusTag = message(
      reply: reply,
      fragments: const [
        ChatMessageFragment(
          type: 'mention',
          text: '@Bob',
          mention: ChatFragmentMention(
            userId: 'bob-id',
            userLogin: 'bob',
            userName: 'Bob',
          ),
        ),
        ChatMessageFragment(type: 'text', text: ' also '),
        ChatMessageFragment(
          type: 'mention',
          text: '@Carol',
          mention: ChatFragmentMention(
            userId: 'carol-id',
            userLogin: 'carol',
            userName: 'Carol',
          ),
        ),
      ],
    );
    final shown = fragmentsForChatDisplay(replyPlusTag);
    expect(shown.map((f) => f.text).toList(), ['also ', '@Carol']);
  });

  test('broadcaster mention uses Twitch streamer red', () {
    expect(
      mentionColorForFragment(
        mentionUserId: 'b1',
        broadcasterUserId: 'b1',
        chatterHex: '#00FF00',
      ),
      kChatBroadcasterMentionColor,
    );
    expect(
      mentionColorForFragment(
        mentionUserId: 'c2',
        broadcasterUserId: 'b1',
        chatterHex: '#00FF00',
      ),
      const Color(0xFF00FF00),
    );
    expect(
      mentionColorForFragment(
        mentionUserId: 'c2',
        broadcasterUserId: 'b1',
        chatterHex: null,
      ),
      isNull,
    );
  });

  test('source channel color is stable, opaque, and varies by channel', () {
    expect(sourceChannelColor('partner-a'), sourceChannelColor('partner-a'));

    /// These keys hash to different palette slots — partners sharing one
    /// chat session must not collapse onto one hue.
    expect(
      sourceChannelColor('partner-a'),
      isNot(sourceChannelColor('partner-b')),
    );

    for (final key in const ['partner-a', 'partner-b', 'debug-partner']) {
      expect(sourceChannelColor(key).a, 1.0);
    }
  });
}
