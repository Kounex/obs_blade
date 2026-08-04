import 'package:hive_ce/hive.dart';

import 'type_ids.dart';

part 'twitch_auth.g.dart';

@HiveType(typeId: TypeIDs.TwitchAuth)
class TwitchAuth extends HiveObject {
  @HiveField(0)
  String accessToken;

  @HiveField(1)
  String refreshToken;

  /// Milliseconds since epoch when [accessToken] expires
  @HiveField(2)
  int expiresAtMs;

  @HiveField(3)
  List<String> scopes;

  @HiveField(4)
  String? userId;

  @HiveField(5)
  String? userLogin;

  @HiveField(6)
  String? userDisplayName;

  TwitchAuth({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAtMs,
    required this.scopes,
    this.userId,
    this.userLogin,
    this.userDisplayName,
  });

  /// Key of the single record inside the TwitchAuth box
  static const String kBoxKey = 'current';

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch >= this.expiresAtMs;

  /// True when the token expires within [window] (or already expired)
  bool expiresWithin(Duration window) =>
      DateTime.now().millisecondsSinceEpoch >=
      this.expiresAtMs - window.inMilliseconds;
}
