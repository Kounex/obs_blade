/// Self-mention / keyword row highlighting — shared by all three native
/// chat engines (Twitch, Kick, YouTube). A message "matches" when its
/// content contains the user's own display name(s) (when enabled) or any
/// of their configured highlight keywords, case-insensitively. Plain
/// substring matching, not word-boundary: chat text doesn't reliably
/// delimit words (emotes, no-space concatenation), and a bare `contains`
/// is the same bar every mainstream chat client (Twitch, Discord) clears
/// for this exact feature.
library;

/// Parses the raw newline/comma-separated keywords text from
/// [SettingsKeys.ChatHighlightKeywords] into a clean list: trimmed,
/// case-insensitively deduped, blanks dropped. Order-preserving (first
/// occurrence wins) so the settings field's own order is stable to edit.
List<String> parseChatHighlightKeywords(String raw) {
  final seen = <String>{};
  final result = <String>[];
  for (final piece in raw.split(RegExp(r'[\n,]'))) {
    final trimmed = piece.trim();
    if (trimmed.isEmpty) continue;
    if (seen.add(trimmed.toLowerCase())) result.add(trimmed);
  }
  return result;
}

/// Whether [content] should render with the mention/keyword highlight
/// wash. [selfNames] is the signed-in-ish identity's display name(s) (a
/// login and a display name, say) — null/blank entries are ignored, so
/// callers can pass straight through without pre-filtering.
bool chatContentIsHighlighted(
  String content, {
  required bool selfMentionEnabled,
  required List<String?> selfNames,
  required List<String> keywords,
}) {
  if (content.isEmpty) return false;
  final lower = content.toLowerCase();
  if (selfMentionEnabled) {
    for (final name in selfNames) {
      final trimmed = name?.trim();
      if (trimmed != null &&
          trimmed.isNotEmpty &&
          lower.contains(trimmed.toLowerCase())) {
        return true;
      }
    }
  }
  for (final keyword in keywords) {
    if (lower.contains(keyword.toLowerCase())) return true;
  }
  return false;
}
