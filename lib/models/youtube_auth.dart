import 'package:hive_ce/hive.dart';

import 'type_ids.dart';

part 'youtube_auth.g.dart';

@HiveType(typeId: TypeIDs.YouTubeAuth)
class YouTubeAuth extends HiveObject {
  @HiveField(0)
  String accessToken;

  @HiveField(1)
  String refreshToken;

  /// Milliseconds since epoch when [accessToken] expires
  @HiveField(2)
  int expiresAtMs;

  @HiveField(3)
  List<String> scopes;

  /// Title of the YouTube channel the token belongs to (display only)
  @HiveField(4)
  String? channelTitle;

  YouTubeAuth({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAtMs,
    required this.scopes,
    this.channelTitle,
  });

  /// Key of the single record inside the YouTubeAuth box
  static const String kBoxKey = 'current';

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch >= this.expiresAtMs;

  /// True when the token expires within [window] (or already expired)
  bool expiresWithin(Duration window) =>
      DateTime.now().millisecondsSinceEpoch >=
      this.expiresAtMs - window.inMilliseconds;
}
