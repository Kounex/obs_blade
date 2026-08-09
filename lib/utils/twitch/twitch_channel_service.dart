import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/twitch/twitch_channel_ref.dart';
import 'package:obs_blade/types/classes/twitch/twitch_channel_search_result.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';

/// Sort key for the add-chat picker: live → mod → everyone else.
/// Stable within a tier (keeps Helix / original order).
int channelPickerSortRank(
  String id, {
  required Set<String> liveIds,
  required Set<String> modIds,
}) {
  if (liveIds.contains(id)) return 0;
  if (modIds.contains(id)) return 1;
  return 2;
}

/// Stable sort of [refs] by [channelPickerSortRank].
List<TwitchChannelRef> sortChannelPickerRefs(
  List<TwitchChannelRef> refs, {
  required Set<String> liveIds,
  required Set<String> modIds,
}) {
  final indexed = refs.asMap().entries.toList();
  indexed.sort((a, b) {
    final cmp = channelPickerSortRank(
      a.value.id,
      liveIds: liveIds,
      modIds: modIds,
    ).compareTo(channelPickerSortRank(
      b.value.id,
      liveIds: liveIds,
      modIds: modIds,
    ));
    if (cmp != 0) return cmp;
    return a.key.compareTo(b.key);
  });
  return [for (final entry in indexed) entry.value];
}

/// Stable sort of search results — live first, then mod, then the rest.
List<TwitchChannelSearchResult> sortChannelSearchResults(
  List<TwitchChannelSearchResult> results, {
  required Set<String> modIds,
}) {
  int rank(TwitchChannelSearchResult result) => channelPickerSortRank(
        result.id,
        liveIds: result.isLive ? {result.id} : const {},
        modIds: modIds,
      );
  final indexed = results.asMap().entries.toList();
  indexed.sort((a, b) {
    final cmp = rank(a.value).compareTo(rank(b.value));
    if (cmp != 0) return cmp;
    return a.key.compareTo(b.key);
  });
  return [for (final entry in indexed) entry.value];
}

/// Helix channel discovery for the multi-chat add-chat picker — Search
/// Channels typeahead plus the "channels you moderate" / "channels you
/// follow" quick-pick sections. Requires a user access token with the
/// matching scopes (`user:read:follows`,
/// `user:read:moderated_channels`; see `kTwitchChatScopes`).
///
/// [client] is injectable for tests — no real HTTP in unit tests.
class TwitchChannelService {
  final http.Client _client;

  TwitchChannelService({http.Client? client})
      : _client = client ?? http.Client();

  Future<List<TwitchChannelSearchResult>> searchChannels({
    required String accessToken,
    required String query,
  }) async {
    final response = await this._client.get(
      Uri.parse('$kTwitchHelixBase/search/channels')
          .replace(queryParameters: {'query': query, 'first': '20'}),
      headers: TwitchAuthService.helixHeaders(accessToken),
    );
    if (response.statusCode != 200) {
      throw TwitchAuthException(
        'Searching Twitch channels failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    final data = (json.decode(response.body) as Map<String, dynamic>)['data'];
    if (data is! List) return const [];
    return [
      for (final entry in data)
        TwitchChannelSearchResult.fromJson(entry as Map<String, Object?>),
    ];
  }

  /// Ids of [broadcasterIds] that are currently live (`GET /streams`).
  /// Batches in chunks of 100 (Helix cap). Empty input → empty set; no
  /// request. Used to live-first sort the moderated/followed picker
  /// sections — the streams call is optional at the call site (best-effort).
  Future<Set<String>> getLiveBroadcasterIds({
    required String accessToken,
    required Iterable<String> broadcasterIds,
  }) async {
    final ids = broadcasterIds.toList();
    if (ids.isEmpty) return <String>{};

    final live = <String>{};
    for (var i = 0; i < ids.length; i += 100) {
      final chunk = ids.sublist(i, i + 100 > ids.length ? ids.length : i + 100);
      final response = await this._client.get(
        Uri.parse('$kTwitchHelixBase/streams').replace(
          /// Iterable value → repeated `user_id=` (Helix batch form).
          queryParameters: {'user_id': chunk},
        ),
        headers: TwitchAuthService.helixHeaders(accessToken),
      );
      if (response.statusCode != 200) {
        throw TwitchAuthException(
          'Fetching live streams failed (${response.statusCode})',
          cause: response.body,
          statusCode: response.statusCode,
        );
      }
      final data =
          (json.decode(response.body) as Map<String, dynamic>)['data'];
      if (data is! List) continue;
      for (final entry in data) {
        final userId = (entry as Map<String, dynamic>)['user_id'] as String?;
        if (userId != null) live.add(userId);
      }
    }
    return live;
  }

  /// Channels the user moderates (`moderation/channels`). Follows at most
  /// one `pagination.cursor` — a single extra page covers realistic mod
  /// lists without an unbounded fetch on chat connect.
  Future<List<TwitchChannelRef>> getModeratedChannels({
    required String accessToken,
    required String userId,
  }) async {
    return this._pagedRefs(
      accessToken,
      Uri.parse('$kTwitchHelixBase/moderation/channels')
          .replace(queryParameters: {'user_id': userId, 'first': '100'}),
      'Fetching moderated channels failed',
    );
  }

  /// Channels the user follows (`channels/followed`) — same single extra
  /// page rule as [getModeratedChannels].
  Future<List<TwitchChannelRef>> getFollowedChannels({
    required String accessToken,
    required String userId,
  }) async {
    return this._pagedRefs(
      accessToken,
      Uri.parse('$kTwitchHelixBase/channels/followed')
          .replace(queryParameters: {'user_id': userId, 'first': '100'}),
      'Fetching followed channels failed',
    );
  }

  /// Fetches the first page plus at most one cursor page (the plan's
  /// single-extra-page rule — enough for realistic mod/follow lists
  /// without an unbounded fetch on chat connect).
  Future<List<TwitchChannelRef>> _pagedRefs(
    String accessToken,
    Uri firstPage,
    String errorLabel,
  ) async {
    final refs = <TwitchChannelRef>[];
    String? cursor;
    for (var page = 0; page < 2; page++) {
      final uri = cursor == null
          ? firstPage
          : firstPage.replace(queryParameters: {
              ...firstPage.queryParameters,
              'after': cursor,
            });
      final response = await this._client.get(
        uri,
        headers: TwitchAuthService.helixHeaders(accessToken),
      );
      if (response.statusCode != 200) {
        throw TwitchAuthException(
          '$errorLabel (${response.statusCode})',
          cause: response.body,
          statusCode: response.statusCode,
        );
      }
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final data = decoded['data'];
      if (data is List) {
        refs.addAll(data.map(
          (entry) => _refFromJson(entry as Map<String, Object?>),
        ));
      }
      cursor = (decoded['pagination'] as Map<String, dynamic>?)?['cursor']
          as String?;
      if (cursor == null || data is! List || data.isEmpty) break;
    }
    return refs;
  }

  static TwitchChannelRef _refFromJson(Map<String, Object?> json) =>
      TwitchChannelRef(
        id: json['broadcaster_id'] as String,
        login: json['broadcaster_login'] as String,
        displayName: json['broadcaster_name'] as String,
        addedAt: DateTime.now(),
      );
}
