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

  /// The voice the native bridge actually reads this language with
  final bool preferred;

  /// The voice the bridge reads the default language with (the setting,
  /// else the phone's - Android: the speech engine's own default) - one
  /// per list at most
  final bool isDefault;

  const ChatTtsVoice({
    required this.id,
    required this.name,
    required this.language,
    required this.languageName,
    required this.quality,
    this.network = false,
    this.preferred = false,
    this.isDefault = false,
  });

  factory ChatTtsVoice.fromMap(Map<Object?, Object?> map) => ChatTtsVoice(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? '',
    language: map['language'] as String? ?? '',
    languageName:
        map['languageName'] as String? ?? map['language'] as String? ?? '',
    quality: (map['quality'] as num?)?.toInt() ?? 0,
    network: map['network'] == true,
    preferred: map['preferred'] == true,
    isDefault: map['default'] == true,
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

/// One row per language: the voice TTS uses for it, all its voices
class ChatTtsLanguage {
  final String language;
  final String languageName;
  final ChatTtsVoice best;
  final List<ChatTtsVoice> voices;

  const ChatTtsLanguage({
    required this.language,
    required this.languageName,
    required this.best,
    required this.voices,
  });

  int get voiceCount => this.voices.length;
}

/// A voice's name for pickers. iOS: the name plus what sets it apart
/// (Siri, Enhanced / Premium, robotic Eloquence). Android names are ids
/// (`de-de-x-deb-local`) - shown as "Voice DEB" with quality and whether
/// it needs internet.
String chatTtsVoiceLabel(ChatTtsVoice voice, {required bool ios}) {
  if (ios) {
    final id = voice.id.toLowerCase();
    return [
      voice.name,
      if (voice.qualityRank == 2) 'Premium',
      if (voice.qualityRank == 1) 'Enhanced',
      if (id.contains('siri')) 'Siri',
      if (id.contains('eloquence')) 'robotic',
    ].join(' · ');
  }
  final variant = voice.name.contains('-x-')
      ? voice.name
            .split('-x-')
            .last
            .replaceAll(RegExp(r'-(local|network)$'), '')
            .toUpperCase()
      : null;
  return [
    variant != null ? 'Voice $variant' : voice.name,
    const ['low quality', 'normal quality', 'high quality'][voice.qualityRank],
    if (voice.network) 'needs internet',
  ].join(' · ');
}

/// Groups [voices] by language - shown voice: the one the bridge marks as
/// [ChatTtsVoice.preferred], else the best quality (offline first) -
/// sorted by language name
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
            entry.value.where((voice) => voice.preferred).firstOrNull ??
            (entry.value.toList()..sort((a, b) {
                  final rank = b.qualityRank.compareTo(a.qualityRank);
                  if (rank != 0) return rank;
                  return (a.network ? 1 : 0).compareTo(b.network ? 1 : 0);
                }))
                .first,
        voices: List.unmodifiable(entry.value),
      ),
  ];
  languages.sort(
    (a, b) =>
        a.languageName.toLowerCase().compareTo(b.languageName.toLowerCase()),
  );
  return languages;
}
