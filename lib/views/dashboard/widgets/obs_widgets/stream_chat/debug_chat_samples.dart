import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';

/// Crafted chat events for the debug injector (`kDebugMode` only) — the
/// rendering paths they exercise are impractical to reproduce on demand
/// against real Twitch traffic (GIF picker messages, power-ups, shared
/// chat sessions). Mirrors `test/chat/fixtures/twitch/` payloads.
///
/// The store stamps the selected channel + arrival time on injection, so
/// the `broadcasterUserId` here is just a placeholder; `messageId` must
/// still be unique per injection to keep tombstone/dedup maps sane.
List<({String label, String description, ChatMessageEvent event})>
    debugChatSamples() {
  final stamp = DateTime.now().microsecondsSinceEpoch;
  ChatMessageEvent base({
    required String id,
    required ChatMessageText message,
    String messageType = 'text',
    String? sourceName,
  }) =>
      ChatMessageEvent(
        broadcasterUserId: 'debug',
        chatterUserId: 'debug-chatter',
        chatterUserLogin: 'sampleviewer',
        chatterUserName: 'SampleViewer',
        messageId: 'debug-$id-$stamp',
        color: '#00FF7F',
        messageType: messageType,
        sourceBroadcasterUserId: sourceName == null ? null : 'debug-partner',
        sourceBroadcasterUserLogin:
            sourceName == null ? null : sourceName.toLowerCase(),
        sourceBroadcasterUserName: sourceName,
        message: message,
      );

  return [
    (
      label: 'GIF message',
      description: 'Inline animated GIF fragment (gif_id + url)',
      event: base(
        id: 'gif',
        message: const ChatMessageText(
          text: 'check this dance',
          fragments: [
            ChatMessageFragment(type: 'text', text: 'check this '),
            ChatMessageFragment(
              type: 'gif',
              text: 'dance',
              gif: ChatFragmentGif(
                gifId: '3o7TKsO8DGFD5T7ZmA',
                url:
                    'https://media.giphy.com/media/3o7TKsO8DGFD5T7ZmA/giphy.gif',
              ),
            ),
          ],
        ),
      ),
    ),
    (
      label: 'Gigantified emote',
      description: 'Power-up message — emote renders at 3x',
      event: base(
        id: 'gigantified',
        messageType: 'power_ups_gigantified_emote',
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
      ),
    ),
    (
      label: 'Shared chat message',
      description: 'Origin chip from a partner channel',
      event: base(
        id: 'shared',
        sourceName: 'PartnerStreamer',
        message: const ChatMessageText(
          text: 'hello from the partner channel!',
          fragments: [
            ChatMessageFragment(
              type: 'text',
              text: 'hello from the partner channel!',
            ),
          ],
        ),
      ),
    ),
  ];
}
