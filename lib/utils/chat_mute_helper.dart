/// Mute-word row filtering — shared by all three native chat engines
/// (Twitch, Kick, YouTube). Unlike self-mention/keyword highlighting
/// ([chatContentIsHighlighted], which washes a row), a mute-word match
/// drops the row from the timeline entirely, filtered at the message-list
/// level in each `native_*_chat_view.dart` (not per-row — there's nothing
/// to render). Word list parsing is shared with the highlight feature via
/// [parseChatHighlightKeywords] (same newline/comma grammar); this file
/// only adds the match predicate.
library;

/// Case-insensitive substring match against [content] — same rule as
/// [chatContentIsHighlighted] for the same reason (chat text doesn't
/// reliably delimit words: emotes, no-space concatenation).
bool chatContentIsMuted(String content, List<String> muteWords) {
  if (content.isEmpty || muteWords.isEmpty) return false;
  final lower = content.toLowerCase();
  for (final word in muteWords) {
    if (lower.contains(word.toLowerCase())) return true;
  }
  return false;
}
