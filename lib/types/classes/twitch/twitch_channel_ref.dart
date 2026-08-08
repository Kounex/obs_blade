/// One streamer channel the user added to the native multi-chat
/// ([SettingsKeys.NativeChatChannels]). Persisted as a plain json map in
/// the settings box — never chat content. The user's own channel is never
/// stored as a ref; it is derived from `TwitchAuth` ([selectedChannelId]
/// == null means own channel). Plain class, no freezed — four fields,
/// hand-rolled equality on the channel id (the rest is display metadata
/// that may go stale, e.g. a renamed display name).
class TwitchChannelRef {
  final String id;
  final String login;
  final String displayName;

  /// When the user added the channel (local clock, informational only).
  final DateTime addedAt;

  const TwitchChannelRef({
    required this.id,
    required this.login,
    required this.displayName,
    required this.addedAt,
  });

  factory TwitchChannelRef.fromJson(Map<String, Object?> json) =>
      TwitchChannelRef(
        id: json['id'] as String,
        login: json['login'] as String,
        displayName: json['displayName'] as String,
        addedAt: DateTime.parse(json['addedAt'] as String),
      );

  Map<String, Object?> toJson() => {
        'id': this.id,
        'login': this.login,
        'displayName': this.displayName,
        'addedAt': this.addedAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is TwitchChannelRef && other.id == this.id;

  @override
  int get hashCode => this.id.hashCode;
}
