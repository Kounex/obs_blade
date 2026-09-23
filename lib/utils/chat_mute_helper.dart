/// Mute-word row filtering — shared by all three native chat engines
/// (Twitch, Kick, YouTube). Unlike self-mention/keyword highlighting
/// ([chatContentIsHighlighted], which washes a row), a mute-word match
/// drops the row from the timeline entirely, filtered at the message-list
/// level in each `native_*_chat_view.dart` (not per-row — there's nothing
/// to render). Word list parsing is shared with the highlight feature via
/// [parseChatHighlightKeywords] (same newline/comma grammar); this file
/// only adds the match predicate.
library;

import 'chat_highlight_helper.dart';

/// Case-insensitive substring match against [content] — same rule as
/// [chatContentIsHighlighted] for the same reason (chat text doesn't
/// reliably delimit words: emotes, no-space concatenation).
bool chatContentIsMuted(String content, List<String> muteWords) {
  if (content.isEmpty || muteWords.isEmpty) return false;
  final lower = content.toLowerCase();
  for (final word in muteWords) {
    if (chatKeywordMatches(word, content, lower)) return true;
  }
  return false;
}

/// Chatterino's "replace" ignore mode: [content] with every mute-word
/// match (substring, case-insensitive; `/regex/` entries too) replaced by
/// `***`. Unchanged when nothing matches.
String censorChatContent(String content, List<String> muteWords) {
  if (content.isEmpty || muteWords.isEmpty) return content;
  var result = content;
  for (final word in muteWords) {
    final pattern =
        chatKeywordRegex(word) ??
        RegExp(RegExp.escape(word), caseSensitive: false);
    result = result.replaceAll(pattern, '***');
  }
  return result;
}
