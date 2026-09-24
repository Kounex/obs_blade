import '../../../models/enums/chat_type.dart';
import '../twitch/twitch_channel_ref.dart';

/// Reserved id of the built-in "My chats" combo (the signed-in "You"
/// entries) — never persisted as a [CombinedCombo].
const String kMyChatsComboId = 'my';

/// A YouTube source of a saved combo: the entry label in
/// `SettingsKeys.YouTubeUsernames` plus its raw value, so a deleted entry
/// can be re-created when the combo is used again.
class CombinedYouTubeSource {
  final String label;
  final String value;

  const CombinedYouTubeSource({required this.label, required this.value});

  factory CombinedYouTubeSource.fromJson(Map<Object?, Object?> json) =>
      CombinedYouTubeSource(
        label: json['label'] as String,
        value: json['value'] as String,
      );

  Map<String, Object?> toJson() => {'label': this.label, 'value': this.value};

  @override
  bool operator ==(Object other) =>
      other is CombinedYouTubeSource &&
      other.label == this.label &&
      other.value == this.value;

  @override
  int get hashCode => Object.hash(this.label, this.value);
}

/// A user-built combined chat: at most one channel per platform, any
/// streamer (a mod's channels, a viewer's favourite, a co-stream). Stored
/// as settings JSON in `SettingsKeys.CombinedChatCombos`. A source equal
/// to the account's own channel is stored like any other channel.
class CombinedCombo {
  final String id;

  /// User-given name; null derives one from the sources ([displayName]).
  final String? name;

  final TwitchChannelRef? twitch;
  final CombinedYouTubeSource? youTube;
  final String? kickSlug;

  const CombinedCombo({
    required this.id,
    this.name,
    this.twitch,
    this.youTube,
    this.kickSlug,
  });

  /// Platforms with a source, in timeline order.
  List<ChatType> get platforms => [
    if (this.twitch != null) ChatType.Twitch,
    if (this.youTube != null) ChatType.YouTube,
    if (this.kickSlug != null) ChatType.Kick,
  ];

  int get sourceCount => this.platforms.length;

  /// The user's name, else the sources' names joined with " · ".
  String get displayName {
    final name = this.name?.trim();
    if (name != null && name.isNotEmpty) return name;
    return [
      ?this.twitch?.displayName,
      ?this.youTube?.label,
      ?this.kickSlug,
    ].join(' · ');
  }

  factory CombinedCombo.fromJson(Map<Object?, Object?> json) {
    final twitch = json['twitch'];
    final youTube = json['youtube'];
    return CombinedCombo(
      id: json['id'] as String,
      name: json['name'] as String?,
      twitch: twitch is Map
          ? TwitchChannelRef.fromJson(twitch.cast<String, Object?>())
          : null,
      youTube: youTube is Map ? CombinedYouTubeSource.fromJson(youTube) : null,
      kickSlug: json['kick'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
    'id': this.id,
    'name': ?this.name,
    'twitch': ?this.twitch?.toJson(),
    'youtube': ?this.youTube?.toJson(),
    'kick': ?this.kickSlug,
  };
}

/// Parse the persisted combo list; broken entries are skipped one by one.
List<CombinedCombo> parseCombinedCombos(Object? raw) {
  if (raw is! List) return const [];
  final combos = <CombinedCombo>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    try {
      final combo = CombinedCombo.fromJson(entry);
      if (combo.sourceCount > 0) combos.add(combo);
    } catch (_) {
      // skip a malformed entry, keep the rest
    }
  }
  return combos;
}
