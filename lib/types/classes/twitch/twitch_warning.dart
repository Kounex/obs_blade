/// Helix Get Warnings entry (`GET /helix/moderation/warnings`) — a warning
/// issued to a user in a channel the token user broadcasts or moderates.
/// OBS Blade fetches these per-user (user card) rather than channel-wide.
class TwitchWarning {
  final String userId;
  final String userLogin;
  final String userName;
  final String moderatorId;
  final String moderatorLogin;
  final String moderatorName;
  final String reason;
  final DateTime? warnedAt;

  const TwitchWarning({
    required this.userId,
    required this.userLogin,
    required this.userName,
    this.moderatorId = '',
    this.moderatorLogin = '',
    this.moderatorName = '',
    this.reason = '',
    this.warnedAt,
  });

  factory TwitchWarning.fromHelixJson(Map<String, Object?> json) =>
      TwitchWarning(
        userId: json['user_id'] as String? ?? '',
        userLogin: json['user_login'] as String? ?? '',
        userName: json['user_name'] as String? ?? '',
        moderatorId: json['moderator_id'] as String? ?? '',
        moderatorLogin: json['moderator_login'] as String? ?? '',
        moderatorName: json['moderator_name'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
        warnedAt: DateTime.tryParse(json['warned_at'] as String? ?? ''),
      );
}
