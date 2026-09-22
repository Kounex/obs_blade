import 'package:hive_ce/hive.dart';

import 'type_ids.dart';

part 'kick_auth.g.dart';

@HiveType(typeId: TypeIDs.KickAuth)
class KickAuth extends HiveObject {
  @HiveField(0)
  String accessToken;

  @HiveField(1)
  String refreshToken;

  /// Milliseconds since epoch when [accessToken] expires
  @HiveField(2)
  int expiresAtMs;

  @HiveField(3)
  List<String> scopes;

  /// Kick user id of the account the token belongs to — the echo-dedup
  /// key: own messages come back over Pusher with `sender.id == userId`.
  @HiveField(4)
  int? userId;

  /// Kick username of the token's account (display only)
  @HiveField(5)
  String? username;

  /// Profile picture URL of the token's account (display only)
  @HiveField(6)
  String? profilePicture;

  KickAuth({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAtMs,
    required this.scopes,
    this.userId,
    this.username,
    this.profilePicture,
  });

  /// Key of the single record inside the KickAuth box
  static const String kBoxKey = 'current';

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch >= this.expiresAtMs;

  /// True when the token expires within [window] (or already expired)
  bool expiresWithin(Duration window) =>
      DateTime.now().millisecondsSinceEpoch >=
      this.expiresAtMs - window.inMilliseconds;
}
