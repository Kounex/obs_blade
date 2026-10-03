import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/utils/youtube/youtube_live_chat_service.dart';
import 'package:obs_blade/utils/youtube_target.dart';

const String _kApiBase = 'https://www.googleapis.com/youtube/v3';

/// One channel the YouTube "Add chat" picker offers — a channel search
/// hit or one of the signed-in account's subscriptions.
class YouTubeChannelSuggestion {
  /// `UC…` — what the picker stores (a handle can change, the id can't).
  final String channelId;
  final String title;

  /// `@handle` from `channels.list` (`snippet.customUrl`), when the
  /// best-effort lookup answered.
  final String? handle;

  /// Null when hidden by the channel or not looked up.
  final int? subscriberCount;

  /// Search hits only: `snippet.liveBroadcastContent == 'live'` (Google
  /// documents it for channel results too). Subscriptions carry no live
  /// state.
  final bool isLive;

  const YouTubeChannelSuggestion({
    required this.channelId,
    required this.title,
    this.handle,
    this.subscriberCount,
    this.isLive = false,
  });

  YouTubeChannelSuggestion _withDetails(_ChannelDetails? details) =>
      details == null
      ? this
      : YouTubeChannelSuggestion(
          channelId: this.channelId,
          title: this.title,
          handle: details.handle ?? this.handle,
          subscriberCount: details.subscriberCount ?? this.subscriberCount,
          isLive: this.isLive,
        );
}

class _ChannelDetails {
  final String? handle;
  final int? subscriberCount;

  const _ChannelDetails({this.handle, this.subscriberCount});
}

/// The Data API reads behind the YouTube "Add chat" picker ([client] is
/// injectable, no real HTTP in tests):
///
/// - [searchChannels]: `search.list?type=channel` with the user's API key.
///   Google bills it from its own bucket of **100 calls a day per
///   project** (quota table, updated 2026-09-15), separate from the
///   10,000 units chat polling uses, so searching never costs chat time.
///   Answers are cached per query for the app session.
/// - [listSubscriptions]: `subscriptions.list?mine=true` with the session
///   token (scope `youtube` covers it), 1 unit per 50.
///
/// Both enrich their hits with one `channels.list` call (1 unit per 50
/// ids) for the `@handle` and subscriber count; that lookup is
/// best-effort and never fails the list.
class YouTubeChannelSearchService {
  /// Shared so the per-query cache outlives one sheet.
  static final YouTubeChannelSearchService shared =
      YouTubeChannelSearchService();

  /// Shorter queries don't search — every call spends one of the day's
  /// 100.
  static const int kSearchMinLength = 3;
  static const int kSearchResults = 15;

  /// Subscriptions are paged 50 at a time; 4 pages cover nearly everyone
  /// for at most 8 units.
  static const int kSubscriptionPages = 4;
  static const int _kCacheSize = 50;

  /// Long enough to save most repeat searches, short enough that LIVE
  /// chips don't go stale over a streaming session.
  static const Duration kCacheTtl = Duration(minutes: 10);

  final http.Client _client;
  final DateTime Function() _now;
  final Map<String, ({DateTime at, List<YouTubeChannelSuggestion> results})>
  _cache = {};

  YouTubeChannelSearchService({http.Client? client, DateTime Function()? now})
    : _client = client ?? http.Client(),
      _now = now ?? DateTime.now;

  Uri _uri(String path, Map<String, String> query, {String? apiKey}) =>
      Uri.parse('$_kApiBase/$path').replace(
        queryParameters: {
          ...query,
          if (apiKey != null && apiKey.isNotEmpty) 'key': apiKey,
        },
      );

  /// Cached answer for [query] without a request, if any.
  List<YouTubeChannelSuggestion>? cached(String query) {
    final key = query.trim().toLowerCase();
    final hit = this._cache[key];
    if (hit == null) return null;
    if (this._now().difference(hit.at) > kCacheTtl) {
      this._cache.remove(key);
      return null;
    }
    return hit.results;
  }

  Future<List<YouTubeChannelSuggestion>> searchChannels(
    String query, {
    required String apiKey,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < kSearchMinLength) return const [];
    final cacheKey = trimmed.toLowerCase();
    if (this.cached(cacheKey) case final hit?) return hit;

    final response = await this._client.get(
      this._uri('search', {
        'part': 'snippet',
        'type': 'channel',
        'maxResults': '$kSearchResults',
        'q': trimmed,
      }, apiKey: apiKey),
    );
    if (response.statusCode != 200) {
      throw YouTubeLiveChatService.errorFor(response, 'Searching channels');
    }
    final items = (json.decode(response.body) as Map)['items'];
    final hits = <YouTubeChannelSuggestion>[];
    if (items is List) {
      for (final item in items) {
        if (item is! Map) continue;
        final snippet = item['snippet'];
        final id = item['id'];
        final channelId = id is Map ? id['channelId'] : null;
        if (channelId is! String || snippet is! Map) continue;
        if (hits.any((hit) => hit.channelId == channelId)) continue;
        final title = snippet['title'] ?? snippet['channelTitle'];
        hits.add(
          YouTubeChannelSuggestion(
            channelId: channelId,
            title: title is String && title.isNotEmpty ? title : channelId,
            isLive: snippet['liveBroadcastContent'] == 'live',
          ),
        );
      }
    }
    final result = await this._enrich(hits, apiKey: apiKey);
    if (this._cache.length >= _kCacheSize) {
      this._cache.remove(this._cache.keys.first);
    }
    this._cache[cacheKey] = (at: this._now(), results: result);
    return result;
  }

  /// The other stored form of a pasted channel (see
  /// `youTubeEntryLabelFor`): an `@handle`'s `UC…` id via
  /// `channels.list?forHandle=` (the `@` is accepted), or a `UC…` id's
  /// `@handle` via `customUrl` - 1 unit, best-effort (empty on any
  /// failure, legacy `c/` / `user/` paths aren't looked up).
  Future<Set<String>> aliasKeysFor(
    YouTubeChannelTarget target, {
    required String apiKey,
  }) async {
    final path = target.path;
    final Map<String, String> query;
    if (path.startsWith('@')) {
      query = {'part': 'snippet', 'forHandle': path};
    } else if (path.startsWith('channel/')) {
      query = {'part': 'snippet', 'id': path.substring('channel/'.length)};
    } else {
      return const {};
    }
    try {
      final response = await this._client.get(
        this._uri('channels', query, apiKey: apiKey),
      );
      if (response.statusCode != 200) return const {};
      final items = (json.decode(response.body) as Map)['items'];
      if (items is! List || items.isEmpty || items.first is! Map) {
        return const {};
      }
      final item = items.first as Map;
      final id = item['id'];
      final snippet = item['snippet'];
      final customUrl = snippet is Map ? snippet['customUrl'] : null;
      return {
        if (id is String) YouTubeChannelTarget('channel/$id').key,
        if (customUrl is String && customUrl.startsWith('@'))
          YouTubeChannelTarget(customUrl).key,
      }..remove(target.key);
    } catch (_) {
      return const {};
    }
  }

  /// The account's subscriptions, A–Z. A Google account without a channel
  /// has none to list (`subscriberNotFound`, 404) — answered as empty.
  Future<List<YouTubeChannelSuggestion>> listSubscriptions({
    required String accessToken,
    String? apiKey,
  }) async {
    final subscriptions = <YouTubeChannelSuggestion>[];
    String? pageToken;
    for (var page = 0; page < kSubscriptionPages; page++) {
      final response = await this._client.get(
        this._uri('subscriptions', {
          'part': 'snippet',
          'mine': 'true',
          'order': 'alphabetical',
          'maxResults': '50',
          'pageToken': ?pageToken,
        }),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode == 404) return const [];
      if (response.statusCode != 200) {
        throw YouTubeLiveChatService.errorFor(
          response,
          'Loading your subscriptions',
        );
      }
      final body = json.decode(response.body) as Map;
      final items = body['items'];
      final batch = <YouTubeChannelSuggestion>[];
      if (items is List) {
        for (final item in items) {
          final snippet = item is Map ? item['snippet'] : null;
          if (snippet is! Map) continue;
          final resource = snippet['resourceId'];
          final channelId = resource is Map ? resource['channelId'] : null;
          if (channelId is! String) continue;
          final title = snippet['title'];
          batch.add(
            YouTubeChannelSuggestion(
              channelId: channelId,
              title: title is String && title.isNotEmpty ? title : channelId,
            ),
          );
        }
      }
      subscriptions.addAll(
        await this._enrich(batch, accessToken: accessToken, apiKey: apiKey),
      );
      final next = body['nextPageToken'];
      if (next is! String || next.isEmpty) break;
      pageToken = next;
    }
    return subscriptions;
  }

  /// `channels.list?part=snippet,statistics&id=…` for up to 50 hits —
  /// handle + subscriber count. Any failure keeps the bare hits.
  Future<List<YouTubeChannelSuggestion>> _enrich(
    List<YouTubeChannelSuggestion> hits, {
    String? apiKey,
    String? accessToken,
  }) async {
    if (hits.isEmpty) return hits;
    try {
      final response = await this._client.get(
        this._uri('channels', {
          'part': 'snippet,statistics',
          'id': hits.take(50).map((hit) => hit.channelId).join(','),
          'maxResults': '50',
        }, apiKey: accessToken == null ? apiKey : null),
        headers: {
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode != 200) return hits;
      final items = (json.decode(response.body) as Map)['items'];
      if (items is! List) return hits;
      final details = <String, _ChannelDetails>{};
      for (final item in items) {
        if (item is! Map || item['id'] is! String) continue;
        final snippet = item['snippet'];
        final stats = item['statistics'];
        final customUrl = snippet is Map ? snippet['customUrl'] : null;
        final hidden = stats is Map && stats['hiddenSubscriberCount'] == true;
        final count = stats is Map
            ? int.tryParse('${stats['subscriberCount']}')
            : null;
        details[item['id'] as String] = _ChannelDetails(
          handle: customUrl is String && customUrl.startsWith('@')
              ? customUrl
              : null,
          subscriberCount: hidden ? null : count,
        );
      }
      return [for (final hit in hits) hit._withDetails(details[hit.channelId])];
    } catch (_) {
      return hits;
    }
  }
}
