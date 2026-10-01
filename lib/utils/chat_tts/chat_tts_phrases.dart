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
    // Every other language iOS ships voices for (crawled off a phone,
    // 2026-10) - English fallback stays for anything beyond
    'ar': ChatTtsPhrases._('{n} مرات', 'و', 'شخص آخر', '{n} آخرين'),
    'bg': ChatTtsPhrases._('{n} пъти', 'и', 'още един', 'още {n}'),
    'bn': ChatTtsPhrases._('{n} বার', 'এবং', 'আরও একজন', 'আরও {n} জন'),
    'ca': ChatTtsPhrases._('{n} vegades', 'i', 'una altra persona', '{n} més'),
    'cs': ChatTtsPhrases._('{n}krát', 'a', 'jeden další', '{n} dalších'),
    'da': ChatTtsPhrases._('{n} gange', 'og', 'én anden', '{n} andre'),
    'el': ChatTtsPhrases._('{n} φορές', 'και', 'ένας ακόμη', '{n} ακόμη'),
    'fi': ChatTtsPhrases._('{n} kertaa', 'ja', 'yksi muu', '{n} muuta'),
    'he': ChatTtsPhrases._('{n} פעמים', 'וגם', 'עוד אחד', 'עוד {n}'),
    'hi': ChatTtsPhrases._('{n} बार', 'और', 'एक और', '{n} और'),
    'hr': ChatTtsPhrases._('{n} puta', 'i', 'još jedna osoba', 'još {n}'),
    'hu': ChatTtsPhrases._(
      '{n} alkalommal',
      'és',
      'még egy személy',
      'még {n}',
    ),
    'id': ChatTtsPhrases._('{n} kali', 'dan', 'satu orang lagi', '{n} lainnya'),
    'kn': ChatTtsPhrases._('{n} ಬಾರಿ', 'ಮತ್ತು', 'ಇನ್ನೊಬ್ಬರು', 'ಇನ್ನೂ {n} ಜನ'),
    'ms': ChatTtsPhrases._('{n} kali', 'dan', 'seorang lagi', '{n} yang lain'),
    'nb': ChatTtsPhrases._('{n} ganger', 'og', 'én til', '{n} andre'),
    'ro': ChatTtsPhrases._('de {n} ori', 'și', 'încă o persoană', 'încă {n}'),
    'sk': ChatTtsPhrases._('{n}-krát', 'a', 'jeden ďalší', '{n} ďalších'),
    'sl': ChatTtsPhrases._('{n}-krat', 'in', 'še eden', 'še {n}'),
    'sv': ChatTtsPhrases._('{n} gånger', 'och', 'en till', '{n} andra'),
    'ta': ChatTtsPhrases._(
      '{n} முறை',
      'மற்றும்',
      'இன்னொருவர்',
      'மேலும் {n} பேர்',
    ),
    'te': ChatTtsPhrases._('{n} సార్లు', 'మరియు', 'మరొకరు', 'మరో {n} మంది'),
    'th': ChatTtsPhrases._('{n} ครั้ง', 'และ', 'อีก 1 คน', 'อีก {n} คน'),
    'uk': ChatTtsPhrases._('{n} разів', 'і', 'ще один', 'ще {n}'),
    'vi': ChatTtsPhrases._('{n} lần', 'và', 'một người khác', '{n} người khác'),
    'yue': ChatTtsPhrases._('{n}次', '同', '另外1個人', '另外{n}個人'),
  };

  /// Old / alternative codes some Android engines still report
  static const Map<String, String> _aliases = {
    'no': 'nb',
    'iw': 'he',
    'in': 'id',
  };

  /// Phrases for a BCP 47 tag (`de-DE`, `pt-BR`, `zh-Hans`) - English when
  /// the language isn't covered
  static ChatTtsPhrases of(String? languageTag) {
    final base = (languageTag ?? '').split(RegExp('[-_]')).first.toLowerCase();
    return _byLanguage[_aliases[base] ?? base] ?? english;
  }

  /// Base language codes the table covers (tests / diagnostics)
  static Iterable<String> get languages => _byLanguage.keys;

  /// What a voice preview says, per base language
  static const Map<String, String> _samples = {
    'en': 'Hi chat, this is how I sound.',
    'de': 'Hallo Chat, so klinge ich.',
    'es': 'Hola chat, así sueno yo.',
    'fr': 'Salut le chat, voici ma voix.',
    'pt': 'Olá chat, esta é a minha voz.',
    'it': 'Ciao chat, questa è la mia voce.',
    'nl': 'Hallo chat, zo klink ik.',
    'pl': 'Cześć czacie, tak brzmię.',
    'tr': 'Merhaba sohbet, sesim böyle.',
    'ru': 'Привет, чат, вот как я звучу.',
    'ja': 'こんにちは、チャットの皆さん。これが私の声です。',
    'ko': '안녕하세요 채팅 여러분, 제 목소리예요.',
    'zh': '大家好，这是我的声音。',
    'ar': 'مرحبًا بالدردشة، هذا هو صوتي.',
    'bg': 'Здравей, чат, така звучи гласът ми.',
    'bn': 'হ্যালো চ্যাট, এটা আমার কণ্ঠ।',
    'ca': 'Hola xat, així sona la meva veu.',
    'cs': 'Ahoj chate, takhle zním.',
    'da': 'Hej chat, sådan lyder jeg.',
    'el': 'Γεια σου chat, έτσι ακούγομαι.',
    'fi': 'Hei chat, tältä kuulostan.',
    'he': 'שלום צ׳אט, ככה אני נשמע.',
    'hi': 'नमस्ते चैट, मेरी आवाज़ ऐसी है।',
    'hr': 'Bok chate, ovako zvučim.',
    'hu': 'Szia chat, így szólok.',
    'id': 'Halo chat, beginilah suaraku.',
    'kn': 'ಹಲೋ ಚಾಟ್, ನನ್ನ ಧ್ವನಿ ಹೀಗಿದೆ.',
    'ms': 'Hai chat, beginilah suara saya.',
    'nb': 'Hei chat, sånn høres jeg ut.',
    'ro': 'Salut chat, așa sună vocea mea.',
    'sk': 'Ahoj chat, takto znie môj hlas.',
    'sl': 'Živjo klepet, tako zvenim.',
    'sv': 'Hej chatten, så här låter jag.',
    'ta': 'வணக்கம் சாட், என் குரல் இப்படித்தான்.',
    'te': 'హలో చాట్, నా గొంతు ఇలా ఉంటుంది.',
    'th': 'สวัสดีแชท นี่คือเสียงของฉัน',
    'uk': 'Привіт, чате, ось так я звучу.',
    'vi': 'Xin chào chat, đây là giọng của tôi.',
    'yue': '大家好，呢個係我嘅聲音。',
  };

  /// The preview sentence for a BCP 47 tag - English when not covered
  static String sample(String? languageTag) {
    final base = (languageTag ?? '').split(RegExp('[-_]')).first.toLowerCase();
    return _samples[_aliases[base] ?? base] ?? _samples['en']!;
  }

  /// "A", "A and B", "A, B and C", "A and 13 others"
  String names(List<String> names, int others) {
    final parts = [...names, if (others > 0) this.others(others)];
    if (parts.length == 1) return parts.single;
    return '${parts.sublist(0, parts.length - 1).join(', ')} ${this.and} '
        '${parts.last}';
  }
}
