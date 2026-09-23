/// Chatterino-style completion for the native chat input, adapted to
/// touch: instead of Tab-cycling, the word under the cursor drives a
/// suggestion strip (`chat_autocomplete_strip.dart`). Pure functions — the
/// engines feed candidates, nothing here knows about Twitch/YouTube/Kick.
library;

enum ChatCompletionKind { mention, emote }

/// The word being completed: `text[start, end)` is replaced on accept.
class ChatCompletionQuery {
  final ChatCompletionKind kind;
  final int start;
  final int end;

  /// What the user typed, without the `@` / `:` trigger.
  final String prefix;

  /// Typed with a trigger (`@` / `:`) — the user asked for completion, so
  /// substring matches are welcome. Bare words only get prefix matches.
  final bool explicit;

  const ChatCompletionQuery({
    required this.kind,
    required this.start,
    required this.end,
    required this.prefix,
    this.explicit = true,
  });
}

class ChatCompletionCandidate {
  /// Shown on the chip.
  final String label;

  /// Inserted in place of the query (a trailing space is added).
  final String insertText;

  /// Emote artwork, when the candidate is an emote.
  final String? imageUrl;

  const ChatCompletionCandidate({
    required this.label,
    required this.insertText,
    this.imageUrl,
  });
}

/// Bare words shorter than this don't trigger emote suggestions — every
/// "hi" / "ok" would otherwise flash the strip. `:` lowers it to 2.
const int kChatEmoteCompletionMinChars = 3;

/// Max chips in the strip.
const int kChatCompletionLimit = 8;

final RegExp _kWordChar = RegExp(r'[\w@:]');

/// The completion query at [cursor] in [text], or null when the cursor
/// isn't at the end of a completable word.
///
/// - `@ab` → mention query `ab` (empty prefix allowed right after `@`,
///   so the strip offers recent chatters immediately)
/// - `:kap` → emote query `kap` (≥ 2 chars)
/// - `Kapp` → emote query `Kapp` (≥ [kChatEmoteCompletionMinChars])
ChatCompletionQuery? chatCompletionQueryAt(String text, int cursor) {
  if (cursor < 0 || cursor > text.length) return null;

  /// Only complete at a word end — mid-word edits keep the strip away.
  if (cursor < text.length && _kWordChar.hasMatch(text[cursor])) return null;

  var start = cursor;
  while (start > 0 && _kWordChar.hasMatch(text[start - 1])) {
    start--;
  }
  final word = text.substring(start, cursor);
  if (word.isEmpty) return null;

  if (word.startsWith('@')) {
    final prefix = word.substring(1);
    if (prefix.contains('@') || prefix.contains(':')) return null;
    return ChatCompletionQuery(
      kind: ChatCompletionKind.mention,
      start: start,
      end: cursor,
      prefix: prefix,
    );
  }
  if (word.startsWith(':')) {
    final prefix = word.substring(1);
    if (prefix.length < 2 || prefix.contains(':') || prefix.contains('@')) {
      return null;
    }
    return ChatCompletionQuery(
      kind: ChatCompletionKind.emote,
      start: start,
      end: cursor,
      prefix: prefix,
    );
  }
  if (word.contains('@') || word.contains(':')) return null;
  if (word.length < kChatEmoteCompletionMinChars) return null;
  return ChatCompletionQuery(
    kind: ChatCompletionKind.emote,
    start: start,
    end: cursor,
    prefix: word,
    explicit: false,
  );
}

/// Filter + rank [candidates] for [prefix] (by [ChatCompletionCandidate
/// .label]): exact-case prefix matches, then case-insensitive prefix, then
/// case-insensitive substring (only for prefixes ≥ 2 chars and when
/// [allowSubstring] — bare-word queries pass false); input order
/// (callers pass recency / catalog order) breaks ties. Deduplicated by
/// label, capped at [limit]. An exact match that's the only hit is
/// dropped — nothing left to complete.
List<ChatCompletionCandidate> rankChatCompletions(
  String prefix,
  Iterable<ChatCompletionCandidate> candidates, {
  int limit = kChatCompletionLimit,
  bool allowSubstring = true,
}) {
  final lower = prefix.toLowerCase();
  final exact = <ChatCompletionCandidate>[];
  final prefixed = <ChatCompletionCandidate>[];
  final contained = <ChatCompletionCandidate>[];
  final seen = <String>{};
  for (final candidate in candidates) {
    if (!seen.add(candidate.label)) continue;
    final label = candidate.label;
    if (prefix.isEmpty || label.startsWith(prefix)) {
      exact.add(candidate);
    } else if (label.toLowerCase().startsWith(lower)) {
      prefixed.add(candidate);
    } else if (allowSubstring &&
        lower.length >= 2 &&
        label.toLowerCase().contains(lower)) {
      contained.add(candidate);
    }
  }
  final ranked = [...exact, ...prefixed, ...contained];
  if (ranked.length == 1 && ranked.single.insertText == prefix) {
    return const <ChatCompletionCandidate>[];
  }
  return ranked.length > limit ? ranked.sublist(0, limit) : ranked;
}

/// [text] with [query] replaced by [candidate] + a trailing space, and the
/// cursor offset right after it. A space already following the query is
/// reused instead of doubled.
({String text, int cursor}) applyChatCompletion(
  String text,
  ChatCompletionQuery query,
  ChatCompletionCandidate candidate,
) {
  final followedBySpace = query.end < text.length && text[query.end] == ' ';
  final insert = followedBySpace
      ? candidate.insertText
      : '${candidate.insertText} ';
  final next = text.replaceRange(query.start, query.end, insert);
  return (
    text: next,
    cursor: query.start + insert.length + (followedBySpace ? 1 : 0),
  );
}

/// Mention candidates from chat authors, most recent first. [authors] is
/// in timeline order (oldest first) as `(login, displayName)`; the chip
/// shows the display name, the insert uses it when it only differs from
/// the login by case (Twitch CJK display names fall back to the login).
List<ChatCompletionCandidate> chatMentionCandidates(
  Iterable<(String login, String displayName)> authors, {
  String? selfLogin,
}) {
  final out = <ChatCompletionCandidate>[];
  final seen = <String>{};
  final list = authors.toList();
  for (var i = list.length - 1; i >= 0; i--) {
    final (login, displayName) = list[i];
    if (login.isEmpty) continue;
    final key = login.toLowerCase();
    if (key == selfLogin?.toLowerCase()) continue;
    if (!seen.add(key)) continue;
    final name = displayName.toLowerCase() == key ? displayName : login;

    /// YouTube display names are already `@handle`s.
    final handle = name.startsWith('@') ? name : '@$name';
    out.add(
      ChatCompletionCandidate(
        label: name.startsWith('@') ? name.substring(1) : name,
        insertText: handle,
      ),
    );
  }
  return out;
}
