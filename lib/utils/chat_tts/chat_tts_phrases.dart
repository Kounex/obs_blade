/// The few words text-to-speech adds itself when it shortens spam ("KEKW 5
/// times", "Viewer and 14 others"), in the language the voice reads in -
/// an English filler read by a German voice sounds broken. Fixed at build
/// time on purpose: four phrases don't need a translation service (offline,
/// instant, deterministic). Unknown languages fall back to English.
class ChatTtsPhrases {
  /// "{n} times" - `{n}` is replaced, n >= 2
  final String _times;

  /// Joins the last name ("A and B")
  final String and;

  /// "and one other" - exactly one more person
  final String oneOther;

  /// "{n} others" - `{n}` is replaced, n >= 2
  final String _others;

  const ChatTtsPhrases._(this._times, this.and, this.oneOther, this._others);

  String times(int n) => _times.replaceAll('{n}', '$n');

  String others(int n) => n == 1 ? oneOther : _others.replaceAll('{n}', '$n');

  static const ChatTtsPhrases english = ChatTtsPhrases._(
    '{n} times',
    'and',
    'one other',
    '{n} others',
  );

  /// Base language code (`de`, `pt`, …) → phrases
  static const Map<String, ChatTtsPhrases> _byLanguage = {
    'en': english,
    'de': ChatTtsPhrases._(
      '{n} mal',
      'und',
      'eine weitere Person',
      '{n} weitere',
    ),
    'es': ChatTtsPhrases._('{n} veces', 'y', 'otra persona', '{n} más'),
    'fr': ChatTtsPhrases._(
      '{n} fois',
      'et',
      'une autre personne',
      '{n} autres',
    ),
    'pt': ChatTtsPhrases._('{n} vezes', 'e', 'outra pessoa', 'mais {n}'),
    'it': ChatTtsPhrases._('{n} volte', 'e', "un'altra persona", 'altri {n}'),
    'nl': ChatTtsPhrases._('{n} keer', 'en', 'één ander', '{n} anderen'),
    'pl': ChatTtsPhrases._('{n} razy', 'i', 'jedna osoba', '{n} innych'),
    'tr': ChatTtsPhrases._('{n} kez', 've', 'bir kişi daha', '{n} kişi daha'),
    'ru': ChatTtsPhrases._('{n} раз', 'и', 'ещё один', 'ещё {n}'),
    'ja': ChatTtsPhrases._('{n}回', 'と', '他1人', '他{n}人'),
    'ko': ChatTtsPhrases._('{n}번', '와', '외 1명', '외 {n}명'),
    'zh': ChatTtsPhrases._('{n}次', '和', '另外1人', '另外{n}人'),
  };

  /// Phrases for a BCP 47 tag (`de-DE`, `pt-BR`, `zh-Hans`) - English when
  /// the language isn't covered
  static ChatTtsPhrases of(String? languageTag) {
    final base = (languageTag ?? '').split(RegExp('[-_]')).first.toLowerCase();
    return _byLanguage[base] ?? english;
  }

  /// "A", "A and B", "A, B and C", "A and 13 others"
  String names(List<String> names, int others) {
    final parts = [...names, if (others > 0) this.others(others)];
    if (parts.length == 1) return parts.single;
    return '${parts.sublist(0, parts.length - 1).join(', ')} ${this.and} '
        '${parts.last}';
  }
}
