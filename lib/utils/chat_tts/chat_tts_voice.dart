/// A voice the system can read chat with, as the native TTS bridge lists
/// it (iOS `AVSpeechSynthesisVoice`, Android `TextToSpeech.getVoices()`
/// - installed ones only)
class ChatTtsVoice {
  final String id;
  final String name;

  /// BCP 47 tag, e.g. `en-US`
  final String language;

  /// The language's name in the phone's language, e.g. "English (United
  /// States)"
  final String languageName;

  /// Platform value - iOS: 1 default, 2 enhanced, 3 premium; Android:
  /// 100 (very low) … 500 (very high)
  final int quality;

  /// Android: needs a network connection to speak
  final bool network;

  const ChatTtsVoice({
    required this.id,
    required this.name,
    required this.language,
    required this.languageName,
    required this.quality,
    this.network = false,
  });

  factory ChatTtsVoice.fromMap(Map<Object?, Object?> map) => ChatTtsVoice(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? '',
    language: map['language'] as String? ?? '',
    languageName:
        map['languageName'] as String? ?? map['language'] as String? ?? '',
    quality: (map['quality'] as num?)?.toInt() ?? 0,
    network: map['network'] == true,
  );

  /// Quality on a shared 0 (lowest) … 2 (best) scale
  int get qualityRank => this.quality <= 3
      ? (this.quality - 1).clamp(0, 2)
      : this.quality >= 400
      ? 2
      : this.quality >= 300
      ? 1
      : 0;
}

/// One row per language: its best voice, how many voices it has
class ChatTtsLanguage {
  final String language;
  final String languageName;
  final ChatTtsVoice best;
  final int voiceCount;

  const ChatTtsLanguage({
    required this.language,
    required this.languageName,
    required this.best,
    required this.voiceCount,
  });
}

/// Groups [voices] by language, best voice first per language (offline
/// before network-only on ties), sorted by language name
List<ChatTtsLanguage> chatTtsLanguages(List<ChatTtsVoice> voices) {
  final byLanguage = <String, List<ChatTtsVoice>>{};
  for (final voice in voices) {
    (byLanguage[voice.language] ??= []).add(voice);
  }
  final languages = [
    for (final entry in byLanguage.entries)
      ChatTtsLanguage(
        language: entry.key,
        languageName: entry.value.first.languageName,
        best:
            (entry.value.toList()..sort((a, b) {
                  final rank = b.qualityRank.compareTo(a.qualityRank);
                  if (rank != 0) return rank;
                  return (a.network ? 1 : 0).compareTo(b.network ? 1 : 0);
                }))
                .first,
        voiceCount: entry.value.length,
      ),
  ];
  languages.sort(
    (a, b) =>
        a.languageName.toLowerCase().compareTo(b.languageName.toLowerCase()),
  );
  return languages;
}
