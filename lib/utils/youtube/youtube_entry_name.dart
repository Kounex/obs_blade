import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/utils/youtube_target.dart';

/// Default label for a YouTube chat entry saved without a name — the
/// label is only the entry's display name (and map key), so it can be
/// derived from what was pasted:
///
/// - `@handle` → the handle itself (no network)
/// - `UC…` channel id → the channel title from the public RSS feed
/// - `c/name`, `user/name` → the name
/// - a video → its channel name via YouTube's keyless oEmbed endpoint
///
/// Lookups are best-effort with a short timeout; failures fall back to a
/// readable local name so saving never blocks on the network.
class YouTubeEntryNamer {
  static const Duration kTimeout = Duration(seconds: 4);

  final http.Client _client;

  YouTubeEntryNamer({http.Client? client}) : _client = client ?? http.Client();

  Future<String> nameFor(YouTubeTarget target) async {
    switch (target) {
      case YouTubeChannelTarget(:final path):
        if (path.startsWith('@')) return path;
        if (path.startsWith('channel/')) {
          final id = path.substring('channel/'.length);
          return await this._channelTitle(id) ?? id;
        }
        return target.displayName;
      case YouTubeVideoTarget(:final videoId):
        return await this._videoAuthor(videoId) ?? 'Stream $videoId';
    }
  }

  /// `<feed><title>` of `feeds/videos.xml?channel_id=` — a few KB, no key.
  Future<String?> _channelTitle(String channelId) async {
    final body = await this._get(
      Uri.parse(
        'https://www.youtube.com/feeds/videos.xml',
      ).replace(queryParameters: {'channel_id': channelId}),
    );
    if (body == null) return null;
    final match = RegExp(r'<title>([^<]+)</title>').firstMatch(body);
    return _clean(match?.group(1));
  }

  /// oEmbed `author_name` of a video — the channel that streams it.
  Future<String?> _videoAuthor(String videoId) async {
    final body = await this._get(
      Uri.parse('https://www.youtube.com/oembed').replace(
        queryParameters: {
          'url': 'https://www.youtube.com/watch?v=$videoId',
          'format': 'json',
        },
      ),
    );
    if (body == null) return null;
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        return _clean(json['author_name'] as String?);
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  Future<String?> _get(Uri uri) async {
    try {
      final response = await this._client.get(uri).timeout(kTimeout);
      return response.statusCode == 200 ? response.body : null;
    } catch (_) {
      return null;
    }
  }

  static String? _clean(String? raw) {
    final value = raw
        ?.replaceAll('&amp;', '&')
        .replaceAll('&#39;', "'")
        .replaceAll('&quot;', '"')
        .trim();
    return value == null || value.isEmpty ? null : value;
  }
}

/// [name], or `name (2)`, `name (3)`… — the first one not in [taken]
/// (labels are map keys, so auto-names must not collide).
String uniqueYouTubeEntryLabel(String name, Iterable<String> taken) {
  final used = taken.toSet();
  if (!used.contains(name)) return name;
  for (var i = 2; ; i++) {
    final candidate = '$name ($i)';
    if (!used.contains(candidate)) return candidate;
  }
}
