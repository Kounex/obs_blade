import 'dart:async';

import '../../models/enums/chat_type.dart';
import '../../types/classes/twitch/twitch_channel_search_result.dart';
import '../kick/kick_channel_service.dart';
import '../kick_channel_slug.dart';
import '../youtube/youtube_entry_name.dart';

/// A same-name channel found on another platform — offered as a tappable
/// suggestion in the combined chat builder, never added on its own (the
/// app can't prove two channels belong to the same streamer).
class CombinedMatch {
  final ChatType platform;

  /// What the builder stores for the platform: Twitch channel id, YouTube
  /// `@handle`, Kick slug.
  final String value;

  /// What the chip shows.
  final String label;

  /// Twitch only — the login + display name for the channel ref.
  final String? twitchLogin;

  const CombinedMatch({
    required this.platform,
    required this.value,
    required this.label,
    this.twitchLogin,
  });
}

/// Lowercased name variants worth trying on other platforms: the name as
/// is, with `_` ↔ `-` swapped, and without separators (`ice_poseidon` →
/// `ice_poseidon`, `ice-poseidon`, `iceposeidon`). A leading `@` is
/// dropped. Order = likelihood.
List<String> combinedMatchCandidates(String name) {
  var base = name.trim().toLowerCase();
  if (base.startsWith('@')) base = base.substring(1);
  if (base.isEmpty) return const [];
  return {
    base,
    base.replaceAll('_', '-'),
    base.replaceAll('-', '_'),
    base.replaceAll(RegExp(r'[-_]'), ''),
  }.toList();
}

/// Looks up [name] on the other platforms (all quota-free): Kick slug
/// resolve, YouTube `@handle` page, Twitch search (exact login match,
/// only when signed in). Every lookup is best-effort and time-boxed —
/// a failure just means no suggestion for that platform.
class CombinedMatchFinder {
  static const Duration kTimeout = Duration(seconds: 5);

  final KickChannelService _kick;
  final YouTubeEntryNamer _youTube;

  /// Twitch channel search with the signed-in token; null = not signed in
  /// (no Twitch suggestions).
  final Future<List<TwitchChannelSearchResult>> Function(String query)?
  _twitchSearch;

  CombinedMatchFinder({
    KickChannelService? kickService,
    YouTubeEntryNamer? youTubeNamer,
    Future<List<TwitchChannelSearchResult>> Function(String query)?
    twitchSearch,
  }) : _kick = kickService ?? KickChannelService(),
       _youTube = youTubeNamer ?? YouTubeEntryNamer(),
       _twitchSearch = twitchSearch;

  /// First match per platform in [platforms] for [name].
  Future<List<CombinedMatch>> find(
    String name, {
    required Set<ChatType> platforms,
  }) async {
    final candidates = combinedMatchCandidates(name);
    if (candidates.isEmpty) return const [];
    final lookups = <Future<CombinedMatch?>>[
      if (platforms.contains(ChatType.Twitch)) this._findTwitch(candidates),
      if (platforms.contains(ChatType.YouTube)) this._findYouTube(candidates),
      if (platforms.contains(ChatType.Kick)) this._findKick(candidates),
    ];
    final results = await Future.wait(
      lookups.map(
        (lookup) => lookup
            .timeout(kTimeout, onTimeout: () => null)
            .catchError((Object _) => null),
      ),
    );
    return [for (final match in results) ?match];
  }

  Future<CombinedMatch?> _findKick(List<String> candidates) async {
    for (final candidate in candidates) {
      final slug = extractKickChannelSlug(candidate);
      if (slug == null) continue;
      try {
        final info = await this._kick.resolveChannel(slug);
        if (info != null) {
          return CombinedMatch(
            platform: ChatType.Kick,
            value: info.slug,
            label: info.username ?? info.slug,
          );
        }
      } catch (_) {
        // try the next variant
      }
    }
    return null;
  }

  Future<CombinedMatch?> _findYouTube(List<String> candidates) async {
    for (final candidate in candidates) {
      final handle = '@$candidate';
      final title = await this._youTube.channelPageTitle(handle);
      if (title != null) {
        return CombinedMatch(
          platform: ChatType.YouTube,
          value: handle,
          label: title,
        );
      }
    }
    return null;
  }

  Future<CombinedMatch?> _findTwitch(List<String> candidates) async {
    final search = this._twitchSearch;
    if (search == null) return null;
    for (final candidate in candidates) {
      final results = await search(candidate);
      for (final result in results) {
        if (result.login.toLowerCase() == candidate) {
          return CombinedMatch(
            platform: ChatType.Twitch,
            value: result.id,
            label: result.displayName,
            twitchLogin: result.login,
          );
        }
      }
    }
    return null;
  }
}
