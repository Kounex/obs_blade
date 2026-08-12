/// Helix Get Banned Users entry (`GET /helix/moderation/banned`) — a ban
/// or timeout in the broadcaster's own channel (the endpoint only serves
/// the token user's own channel, not channels they moderate).
class TwitchBannedUser {
  final String userId;
  final String userLogin;
  final String userName;
  final DateTime? createdAt;

  /// Timeout expiry — null means a permanent ban (Helix sends an empty
  /// string for perma-bans, not null).
  final DateTime? expiresAt;
  final String reason;
  final String moderatorId;
  final String moderatorLogin;
  final String moderatorName;

  const TwitchBannedUser({
    required this.userId,
    required this.userLogin,
    required this.userName,
    this.createdAt,
    this.expiresAt,
    this.reason = '',
    this.moderatorId = '',
    this.moderatorLogin = '',
    this.moderatorName = '',
  });

  /// Timeout vs permanent ban — timeouts carry an expiry.
  bool get isTimeout => this.expiresAt != null;

  factory TwitchBannedUser.fromHelixJson(Map<String, Object?> json) =>
      TwitchBannedUser(
        userId: json['user_id'] as String? ?? '',
        userLogin: json['user_login'] as String? ?? '',
        userName: json['user_name'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
        expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
        reason: json['reason'] as String? ?? '',
        moderatorId: json['moderator_id'] as String? ?? '',
        moderatorLogin: json['moderator_login'] as String? ?? '',
        moderatorName: json['moderator_name'] as String? ?? '',
      );
}

/// Helix Get Unban Requests entry (`GET /helix/moderation/unban_requests`)
/// — OBS Blade only fetches `status=pending`; the resolved fields stay
/// null there and are parsed only for completeness.
class TwitchUnbanRequest {
  final String id;
  final String userId;
  final String userLogin;
  final String userName;
  final String text;
  final String status;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final String? resolutionText;
  final String? moderatorId;
  final String? moderatorLogin;
  final String? moderatorName;

  const TwitchUnbanRequest({
    required this.id,
    required this.userId,
    required this.userLogin,
    required this.userName,
    this.text = '',
    this.status = 'pending',
    this.createdAt,
    this.resolvedAt,
    this.resolutionText,
    this.moderatorId,
    this.moderatorLogin,
    this.moderatorName,
  });

  factory TwitchUnbanRequest.fromHelixJson(Map<String, Object?> json) =>
      TwitchUnbanRequest(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        userLogin: json['user_login'] as String? ?? '',
        userName: json['user_name'] as String? ?? '',
        text: json['text'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
        resolvedAt: DateTime.tryParse(json['resolved_at'] as String? ?? ''),
        resolutionText: json['resolution_text'] as String?,
        moderatorId: json['moderator_id'] as String?,
        moderatorLogin: json['moderator_login'] as String?,
        moderatorName: json['moderator_name'] as String?,
      );
}
