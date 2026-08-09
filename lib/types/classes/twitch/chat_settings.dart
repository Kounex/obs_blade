/// Live chat mode flags from Helix Get/Update Chat Settings.
class TwitchChatSettings {
  final bool emoteMode;
  final bool followerMode;
  final int? followerModeDurationMinutes;
  final bool subscriberMode;
  final bool slowMode;
  final int? slowModeWaitTimeSeconds;
  final bool uniqueChatMode;

  const TwitchChatSettings({
    required this.emoteMode,
    required this.followerMode,
    required this.followerModeDurationMinutes,
    required this.subscriberMode,
    required this.slowMode,
    required this.slowModeWaitTimeSeconds,
    required this.uniqueChatMode,
  });

  factory TwitchChatSettings.fromHelixJson(Map<String, Object?> json) =>
      TwitchChatSettings(
        emoteMode: json['emote_mode'] as bool? ?? false,
        followerMode: json['follower_mode'] as bool? ?? false,
        followerModeDurationMinutes: json['follower_mode_duration'] as int?,
        subscriberMode: json['subscriber_mode'] as bool? ?? false,
        slowMode: json['slow_mode'] as bool? ?? false,
        slowModeWaitTimeSeconds: json['slow_mode_wait_time'] as int?,
        uniqueChatMode: json['unique_chat_mode'] as bool? ?? false,
      );

  TwitchChatSettings copyWithWithUpdates({
    bool? emoteMode,
    bool? followerMode,
    int? followerModeDurationMinutes,
    bool? subscriberMode,
    bool? slowMode,
    int? slowModeWaitTimeSeconds,
    bool? uniqueChatMode,
  }) =>
      TwitchChatSettings(
        emoteMode: emoteMode ?? this.emoteMode,
        followerMode: followerMode ?? this.followerMode,
        followerModeDurationMinutes:
            followerModeDurationMinutes ?? this.followerModeDurationMinutes,
        subscriberMode: subscriberMode ?? this.subscriberMode,
        slowMode: slowMode ?? this.slowMode,
        slowModeWaitTimeSeconds:
            slowModeWaitTimeSeconds ?? this.slowModeWaitTimeSeconds,
        uniqueChatMode: uniqueChatMode ?? this.uniqueChatMode,
      );
}
