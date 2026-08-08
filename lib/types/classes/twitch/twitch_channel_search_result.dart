/// One row of the Helix `search/channels` result (add-chat picker
/// typeahead). Only the fields the picker renders are kept — the rest of
/// the payload is dropped (plain class, no freezed, same convention as
/// [ThirdPartyEmote]).
class TwitchChannelSearchResult {
  final String id;
  final String login;
  final String displayName;
  final int followerCount;
  final bool isLive;

  const TwitchChannelSearchResult({
    required this.id,
    required this.login,
    required this.displayName,
    required this.followerCount,
    required this.isLive,
  });

  factory TwitchChannelSearchResult.fromJson(Map<String, Object?> json) =>
      TwitchChannelSearchResult(
        id: json['id'] as String,
        login: json['broadcaster_login'] as String,
        displayName: json['display_name'] as String,
        followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
        isLive: json['is_live'] as bool? ?? false,
      );
}
