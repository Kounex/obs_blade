/// One channel the Kick "Add chat" picker offers — from the website's
/// channel search (`kick.com/api/search`) or the official live listing
/// (`api.kick.com/public/v1/livestreams`). [slug] is the identity the
/// chat stores keep.
class KickChannelSuggestion {
  final String slug;

  /// The username in its own casing (`xQc`); falls back to [slug].
  final String displayName;
  final bool isLive;

  /// Live listing only — the search answer carries no viewer count.
  final int? viewerCount;

  /// Search only.
  final int? followersCount;

  /// Kick's verified partner seal (search only).
  final bool verified;

  /// Live listing only — the stream's category ("Just Chatting").
  final String? categoryName;

  const KickChannelSuggestion({
    required this.slug,
    required this.displayName,
    this.isLive = false,
    this.viewerCount,
    this.followersCount,
    this.verified = false,
    this.categoryName,
  });

  /// A `channels[]` entry of `kick.com/api/search?searched_word=` (shape
  /// captured 2026-10-03): `slug`, `isLive`, `followers_count`, `verified`
  /// (an object or null), `user.username`. Null without a slug.
  static KickChannelSuggestion? fromSearchJson(Object? json) {
    if (json is! Map) return null;
    final slug = json['slug'];
    if (slug is! String || slug.isEmpty) return null;
    final user = json['user'];
    final username = user is Map ? user['username'] : null;
    final followers = json['followers_count'] ?? json['followersCount'];
    return KickChannelSuggestion(
      slug: slug,
      displayName: username is String && username.isNotEmpty ? username : slug,
      isLive: json['isLive'] == true,
      followersCount: followers is int ? followers : null,
      verified: json['verified'] != null && json['verified'] != false,
    );
  }

  /// A `data[]` entry of `GET /public/v1/livestreams` (Kick's OpenAPI
  /// `LivestreamWithCategory`): `slug`, `viewer_count`, `category.name`.
  /// No display-cased username there — the slug stands in.
  static KickChannelSuggestion? fromLivestreamJson(Object? json) {
    if (json is! Map) return null;
    final slug = json['slug'];
    if (slug is! String || slug.isEmpty) return null;
    final viewers = json['viewer_count'];
    final category = json['category'];
    final categoryName = category is Map ? category['name'] : null;
    return KickChannelSuggestion(
      slug: slug,
      displayName: slug,
      isLive: true,
      viewerCount: viewers is int ? viewers : null,
      categoryName: categoryName is String && categoryName.isNotEmpty
          ? categoryName
          : null,
    );
  }
}
