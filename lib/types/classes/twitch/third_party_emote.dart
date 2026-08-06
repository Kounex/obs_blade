/// One third-party chat emote (7TV / BTTV): the token chatters type and
/// the image to render in its place. Shared shape — each provider's
/// payload is parsed into this by [ThirdPartyEmoteService] and the rest
/// of the payload is dropped (plain class, no freezed: two fields, two
/// very different source shapes).
class ThirdPartyEmote {
  /// Emote code as typed in chat (matching is exact + case-sensitive).
  final String name;

  /// Mid-size image URL (animated where the provider has one).
  final String imageUrl;

  const ThirdPartyEmote({required this.name, required this.imageUrl});
}
