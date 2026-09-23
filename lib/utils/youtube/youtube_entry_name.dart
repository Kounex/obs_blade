import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/utils/youtube_target.dart';

/// Default label for a YouTube chat entry saved without a name — the
/// label is only the entry's display name (and map key), so it can be
/// derived from what was pasted:
///
/// - `@handle`, `c/name`, `user/name` → the channel title from the
///   channel page's `og:title`
/// - `UC…` channel id → the channel title from the public RSS feed
/// - a video → its channel name via YouTube's keyless oEmbed endpoint
///
/// Always the channel's display name, never an `@handle`. Lookups are
/// best-effort with a short timeout; failures fall back to a readable
/// local name (the handle without `@`) so saving never blocks.
class YouTubeEntryNamer {
  static const Duration kTimeout = Duration(seconds: 4);

  /// Max gap between body chunks of a channel page download.
  static const Duration kPageTimeout = Duration(seconds: 4);

  static final RegExp _kOgTitle = RegExp(
    r'<meta property="og:title" content="([^"]*)"',
  );

  final http.Client _client;

  YouTubeEntryNamer({http.Client? client}) : _client = client ?? http.Client();

  Future<String> nameFor(YouTubeTarget target) async {
    switch (target) {
      case YouTubeChannelTarget(:final path):
        if (path.startsWith('channel/')) {
          final id = path.substring('channel/'.length);
          return await this._channelTitle(id) ?? id;
        }
        final fallback = target.displayName.startsWith('@')
            ? target.displayName.substring(1)
            : target.displayName;
        return await this._pageTitle(path) ?? fallback;
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

  /// `og:title` of the channel page (`youtube.com/<path>`). The page is
  /// large (the desktop variant YouTube serves here is ~1.5 MB with the
  /// tag ~750 KB in), so it's streamed and dropped once the tag arrives.
  Future<String?> _pageTitle(String path) async {
    final request = http.Request(
      'GET',
      Uri.parse('https://www.youtube.com/$path'),
    )..headers['Cookie'] = 'SOCS=CAI; CONSENT=YES+1';
    try {
      final response = await this._client.send(request).timeout(kTimeout);
      if (response.statusCode != 200) {
        unawaited(response.stream.listen(null).cancel());
        return null;
      }
      var window = '';
      final lines = response.stream
          .transform(const Utf8Decoder(allowMalformed: true))
          .timeout(kPageTimeout);
      await for (final chunk in lines) {
        window += chunk;
        final match = _kOgTitle.firstMatch(window);
        if (match != null) return _clean(match.group(1));
        if (window.length > 4096) {
          window = window.substring(window.length - 4096);
        }
      }
    } catch (_) {
      return null;
    }
    return null;
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
