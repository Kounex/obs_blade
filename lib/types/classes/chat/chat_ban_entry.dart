/// One ban (or timeout) the native chat saw this session — issued from
/// the app or by another mod (the platform's ban echo). Kick and YouTube
/// have no "list banned users" API, so the channel mod sheets list these
/// instead. In-memory only, per channel.
class ChatBanEntry {
  /// Platform user id (Kick: numeric user id as a string; YouTube: the
  /// banned channel id).
  final String userId;

  /// Display name when known.
  final String? userName;

  /// Null = permanent ban; set = timeout until then.
  final DateTime? expiresAt;

  /// Acting moderator's name when the platform reports it.
  final String? bannedBy;

  final DateTime at;

  /// YouTube only: the ban resource id `liveChatBans.delete` needs. Only
  /// bans issued from this app carry one (the `userBannedEvent` echo
  /// doesn't), so only those can be lifted.
  final String? banId;

  const ChatBanEntry({
    required this.userId,
    required this.at,
    this.userName,
    this.expiresAt,
    this.bannedBy,
    this.banId,
  });

  bool get isTimeout => this.expiresAt != null;

  /// A timeout that already ran out.
  bool isExpired(DateTime now) =>
      this.expiresAt != null && !this.expiresAt!.isAfter(now);

  ChatBanEntry copyWith({String? userName, String? banId}) => ChatBanEntry(
    userId: this.userId,
    at: this.at,
    userName: userName ?? this.userName,
    expiresAt: this.expiresAt,
    bannedBy: this.bannedBy,
    banId: banId ?? this.banId,
  );
}
