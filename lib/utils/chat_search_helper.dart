/// Chat search — shared by all three native engines' search sheet
/// (`chat_search_sheet.dart`). Matches against the buffered author name
/// and/or message content; case-insensitive substring, same rule as the
/// highlight/mute matchers and for the same reason (chat text doesn't
/// reliably delimit words).
bool chatSearchMatches({
  required String query,
  required String author,
  required String content,
}) {
  final trimmed = query.trim().toLowerCase();
  if (trimmed.isEmpty) return false;
  return author.toLowerCase().contains(trimmed) ||
      content.toLowerCase().contains(trimmed);
}
