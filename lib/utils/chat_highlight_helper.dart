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

/// `/pattern/` entries in a keyword / mute-word list are regular
/// expressions (Chatterino's regex highlight option), matched
/// case-insensitively; everything else is a plain substring. An invalid
/// pattern never matches (and never throws).
RegExp? chatKeywordRegex(String keyword) {
  if (keyword.length < 3 ||
      !keyword.startsWith('/') ||
      !keyword.endsWith('/')) {
    return null;
  }
  return _regexCache.putIfAbsent(keyword, () {
    try {
      return RegExp(
        keyword.substring(1, keyword.length - 1),
        caseSensitive: false,
      );
    } on FormatException {
      return _kNeverMatches;
    }
  });
}

final RegExp _kNeverMatches = RegExp(r'(?!)');
final Map<String, RegExp> _regexCache = <String, RegExp>{};

/// Whether [keyword] matches [content] — regex for `/…/` entries,
/// case-insensitive substring otherwise ([lowerContent] is
/// `content.toLowerCase()`, hoisted by callers checking many keywords).
bool chatKeywordMatches(String keyword, String content, String lowerContent) {
  final regex = chatKeywordRegex(keyword);
  if (regex != null) return regex.hasMatch(content);
  return lowerContent.contains(keyword.toLowerCase());
}

/// Normalized user-list entry: trimmed, lowercase, leading `@` dropped —
/// highlight / ignore lists match chat logins and display names alike.
String normalizeChatUserName(String name) {
  final trimmed = name.trim().toLowerCase();
  return trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
}

/// Parsed [SettingsKeys.ChatHighlightUsers] / [SettingsKeys.ChatIgnoredUsers]
/// (same newline/comma grammar as keywords), normalized for lookup.
Set<String> parseChatUserList(String raw) => {
  for (final name in parseChatHighlightKeywords(raw))
    if (normalizeChatUserName(name).isNotEmpty) normalizeChatUserName(name),
};

/// Whether any of an author's [names] (login, display name — nulls
/// ignored) is in [users] (a [parseChatUserList] set).
bool chatAuthorInList(Set<String> users, List<String?> names) {
  if (users.isEmpty) return false;
  for (final name in names) {
    if (name != null && users.contains(normalizeChatUserName(name))) {
      return true;
    }
  }
  return false;
}

/// Add or remove [name] in the raw user-list text [raw] (the settings
/// value), keeping the user's other entries and their order. Returns the
/// new raw text.
String toggleChatUserListEntry(String raw, String name) {
  final target = normalizeChatUserName(name);
  final entries = parseChatHighlightKeywords(raw);
  final kept = [
    for (final entry in entries)
      if (normalizeChatUserName(entry) != target) entry,
  ];
  if (kept.length == entries.length) kept.add(name.trim());
  return kept.join('\n');
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
    if (chatKeywordMatches(keyword, content, lower)) return true;
  }
  return false;
}
