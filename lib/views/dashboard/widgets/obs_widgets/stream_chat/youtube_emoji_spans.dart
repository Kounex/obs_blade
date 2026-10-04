import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../../stores/views/youtube_chat.dart';
import '../../../../../stores/views/youtube_emojis.dart';
import '../../../../../utils/youtube/youtube_emoji.dart';
import 'chat_link.dart';
import 'twitch_chat_message_row.dart' show chatImageFadeIn;

/// The broadcaster of the YouTube chat on screen (its member emojis
/// resolve there) - read off the YouTube chat only when it already runs
String? youTubeEmojiChannelId() {
  final getIt = GetIt.instance;
  if (!getIt.isRegistered<YouTubeChatStore>() ||
      !getIt.checkLazySingletonInstanceExists<YouTubeChatStore>()) {
    return null;
  }
  return getIt<YouTubeChatStore>().selectedLiveChannelId;
}

YouTubeEmojiStore? youTubeEmojiStoreOrNull() =>
    GetIt.instance.isRegistered<YouTubeEmojiStore>()
    ? GetIt.instance<YouTubeEmojiStore>()
    : null;

/// Whether [text] may hold a YouTube emoji code - rows only watch the
/// emoji catalog (an Observer) when it does.
bool mayHaveYouTubeEmoji(String text) =>
    text.contains(':') && kYouTubeEmojiCodePattern.hasMatch(text);

/// YouTube chat text with `:code:` emojis (the standard set and channels'
/// member emojis) drawn as images; links stay tappable. Codes the catalog
/// doesn't know (yet) stay text. Lookups are reactive: inside an Observer
/// a code learned later swaps in its image.
List<InlineSpan> youTubeEmojiTextSpans(
  BuildContext context,
  String text, {
  required double emojiSize,
  YouTubeEmojiStore? store,

  /// Broadcaster of the chat (member emojis); the open chat's when null
  String? channelId,
}) {
  final catalog = store ?? youTubeEmojiStoreOrNull();
  if (catalog == null || !mayHaveYouTubeEmoji(text)) {
    return chatLinkTextSpans(context, text);
  }
  final pixels = (emojiSize * MediaQuery.devicePixelRatioOf(context)).ceil();
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final match in kYouTubeEmojiCodePattern.allMatches(text)) {
    final code = match.group(0)!;
    final emoji = catalog.lookup(
      code,
      channelId: channelId ?? youTubeEmojiChannelId(),
    );
    if (emoji == null) continue;
    if (match.start > cursor) {
      spans.addAll(
        chatLinkTextSpans(context, text.substring(cursor, match.start)),
      );
    }
    spans.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Semantics(
          label: code,
          child: Image.network(
            emoji.imageUrl(pixels),
            width: emojiSize,
            height: emojiSize,
            fit: BoxFit.contain,
            frameBuilder: chatImageFadeIn,
            errorBuilder: (_, _, _) => Text(code),
          ),
        ),
      ),
    );
    cursor = match.end;
  }
  if (cursor < text.length) {
    spans.addAll(chatLinkTextSpans(context, text.substring(cursor)));
  }
  return spans;
}
