import 'dart:convert';

import 'package:http/http.dart' as http;

import '../general_helper.dart';
import '../youtube_target.dart';
import 'youtube_live_resolver.dart';
import 'package:obs_blade/utils/renewing_http_client.dart';

/// Whether a channel is live right now and how many watch (null: the
/// channel hides the count).
typedef YouTubeLiveStatus = ({bool live, int? viewers});

/// LIVE + viewers for a list of channels (the YouTube "Add chat" picker):
///
/// 1. the channel's `/live` page (quota-free, ~3 KB with the mobile user
///    agent) names its current stream - a few channels at a time;
/// 2. one `videos.list?part=liveStreamingDetails` per chunk (1 unit for up
///    to 50 ids) confirms it really started (`actualStartTime` set,
///    `actualEndTime` not - `/live` can point at a scheduled stream) and
///    gives `concurrentViewers`.
///
/// Answers are remembered [ttl] per channel. Results arrive chunk by
/// chunk through `onUpdate`, so a long subscription list fills in as it
/// goes. Failures leave a channel unknown (no LIVE shown, not cached);
/// `logFailure` keeps a long list failing offline to one log line.
class YouTubeLiveStatusService {
  static final YouTubeLiveStatusService shared = YouTubeLiveStatusService();

  static const Duration ttl = Duration(minutes: 1);

  /// `/live` reads in flight at once (~3 KB each)
  static const int concurrency = 10;

  /// Channels per `videos.list` round (and per update)
  static const int chunkSize = 30;

  /// One `/live` read; a stalled one counts as unknown instead of holding
  /// up the rest
  static const Duration pageTimeout = Duration(seconds: 8);

  final YouTubeLiveResolver _resolver;
  final http.Client _client;
  final DateTime Function() _now;

  YouTubeLiveStatusService({
    YouTubeLiveResolver? resolver,
    http.Client? client,
    DateTime Function()? now,
  }) : _resolver = resolver ?? YouTubeLiveResolver(),
       _client = client ?? RenewingHttpClient(),
       _now = now ?? DateTime.now;

  final Map<String, (DateTime, YouTubeLiveStatus)> _cache = {};

  /// The remembered status of [channelId], if fresh.
  YouTubeLiveStatus? cached(String channelId) {
    final hit = this._cache[channelId];
    if (hit == null) return null;
    if (this._now().difference(hit.$1) > ttl) {
      this._cache.remove(channelId);
      return null;
    }
    return hit.$2;
  }

  /// Check [channelIds] (`UC…`); fresh answers come back at once through
  /// [onUpdate], the rest per chunk. Stops between chunks once
  /// [cancelled] says so (the sheet closed). [onProgress] gets how many
  /// of the channels are done (answered or given up on) after each step.
  /// `videos.list` reads with
  /// [apiKey], else a signed-in [accessToken]; with neither nothing is
  /// read (`/live` alone can't tell a scheduled stream from a live one).
  Future<void> check(
    List<String> channelIds, {
    required String apiKey,
    Future<String?> Function()? accessToken,
    required void Function(Map<String, YouTubeLiveStatus> update) onUpdate,
    void Function(int done, int total)? onProgress,
    bool Function()? cancelled,
  }) async {
    final known = <String, YouTubeLiveStatus>{};
    final pending = <String>[];
    for (final id in {...channelIds}) {
      final hit = this.cached(id);
      if (hit != null) {
        known[id] = hit;
      } else {
        pending.add(id);
      }
    }
    final total = known.length + pending.length;
    if (known.isNotEmpty) onUpdate(known);
    onProgress?.call(known.length, total);
    if (pending.isEmpty) return;
    final token = apiKey.isEmpty ? await accessToken?.call() : null;
    if (apiKey.isEmpty && token == null) {
      onProgress?.call(total, total);
      return;
    }
    for (var start = 0; start < pending.length; start += chunkSize) {
      if (cancelled?.call() ?? false) return;
      final chunk = pending.sublist(
        start,
        (start + chunkSize).clamp(0, pending.length),
      );
      final update = await this._checkChunk(
        chunk,
        apiKey: apiKey,
        token: token,
      );
      if (cancelled?.call() ?? false) return;
      if (update.isNotEmpty) onUpdate(update);
      onProgress?.call(
        known.length + (start + chunk.length).clamp(0, pending.length),
        total,
      );
    }
  }

  Future<Map<String, YouTubeLiveStatus>> _checkChunk(
    List<String> channelIds, {
    required String apiKey,
    String? token,
  }) async {
    /// channel → its `/live` video (null: not live), unknown on failure
    final videos = <String, String?>{};
    for (var start = 0; start < channelIds.length; start += concurrency) {
      final batch = channelIds.sublist(
        start,
        (start + concurrency).clamp(0, channelIds.length),
      );
      await Future.wait([
        for (final id in batch)
          this._resolver
              .resolveLiveVideoId(YouTubeChannelTarget('channel/$id'))
              .timeout(pageTimeout)
              .then((video) => videos[id] = video)
              .catchError((Object e) {
                GeneralHelper.logFailure('YouTube live check failed', e);
                return null;
              }),
      ]);
    }
    final candidates = {
      for (final entry in videos.entries)
        if (entry.value != null) entry.value!: entry.key,
    };
    final details = candidates.isEmpty
        ? const <String, YouTubeLiveStatus>{}
        : await this._details(
            candidates.keys.toList(),
            apiKey: apiKey,
            token: token,
          );
    final now = this._now();
    final update = <String, YouTubeLiveStatus>{};
    for (final entry in videos.entries) {
      final video = entry.value;

      /// Not live, or live per `videos.list`; a candidate whose details
      /// failed stays unknown
      final YouTubeLiveStatus? status = video == null
          ? (live: false, viewers: null)
          : details[video];
      if (status == null) continue;
      update[entry.key] = status;
      this._cache[entry.key] = (now, status);
    }
    return update;
  }

  /// `videos.list` for [videoIds] → status per video. Empty on failure.
  Future<Map<String, YouTubeLiveStatus>> _details(
    List<String> videoIds, {
    required String apiKey,
    String? token,
  }) async {
    try {
      final response = await this._client.get(
        Uri.https('www.googleapis.com', '/youtube/v3/videos', {
          'part': 'liveStreamingDetails',
          'id': videoIds.join(','),
          if (apiKey.isNotEmpty) 'key': apiKey,
        }),
        headers: apiKey.isEmpty && token != null
            ? {'Authorization': 'Bearer $token'}
            : null,
      );
      if (response.statusCode != 200) {
        throw Exception('videos.list HTTP ${response.statusCode}');
      }
      final items = (json.decode(response.body) as Map)['items'];
      final result = <String, YouTubeLiveStatus>{};
      if (items is List) {
        for (final item in items) {
          if (item is! Map || item['id'] is! String) continue;
          final details = item['liveStreamingDetails'];
          final started = details is Map && details['actualStartTime'] != null;
          final ended = details is Map && details['actualEndTime'] != null;
          final viewers = details is Map
              ? int.tryParse('${details['concurrentViewers'] ?? ''}')
              : null;
          result[item['id'] as String] = (
            live: started && !ended,
            viewers: started && !ended ? viewers : null,
          );
        }
      }
      return result;
    } catch (e) {
      GeneralHelper.logFailure('YouTube live viewers lookup failed', e);
      return const {};
    }
  }
}
