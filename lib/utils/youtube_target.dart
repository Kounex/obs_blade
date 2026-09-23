import 'youtube_video_id.dart';

/// What a stored YouTube chat entry points at: one specific video (the
/// historical per-stream entry) or a channel whose *current* live stream
/// is resolved at connect time (see `YouTubeLiveResolver`).
sealed class YouTubeTarget {
  const YouTubeTarget();

  /// Stable identity of the target — two entries with the same key are the
  /// same conversation source (used to detect re-edits).
  String get key;

  /// Normalized value persisted in [SettingsKeys.YouTubeUsernames].
  String get storageValue;
}

class YouTubeVideoTarget extends YouTubeTarget {
  final String videoId;

  const YouTubeVideoTarget(this.videoId);

  @override
  String get key => 'video:$videoId';

  /// Bare id — what older builds persisted, so downgrades keep working.
  @override
  String get storageValue => this.videoId;

  @override
  bool operator ==(Object other) =>
      other is YouTubeVideoTarget && other.videoId == this.videoId;

  @override
  int get hashCode => this.key.hashCode;
}

class YouTubeChannelTarget extends YouTubeTarget {
  /// Channel path on youtube.com without leading/trailing slashes:
  /// `@handle`, `channel/UC…`, `c/name` or `user/name`.
  final String path;

  const YouTubeChannelTarget(this.path);

  /// Channel page whose `/live` suffix redirects to the current stream.
  Uri get liveUri => Uri.parse('https://www.youtube.com/${this.path}/live');

  /// Short human form for UI copy (`@handle`, the channel id, or the
  /// legacy custom name).
  String get displayName =>
      this.path.contains('/') ? this.path.split('/').last : this.path;

  @override
  String get key => 'channel:${this.path.toLowerCase()}';

  /// `@handle` and `UC…` ids store bare; legacy `c/` + `user/` paths keep
  /// their prefix (a bare name would be ambiguous).
  @override
  String get storageValue => this.path.startsWith('channel/')
      ? this.path.substring('channel/'.length)
      : this.path;

  @override
  bool operator ==(Object other) =>
      other is YouTubeChannelTarget && other.key == this.key;

  @override
  int get hashCode => this.key.hashCode;
}

final RegExp _kChannelId = RegExp(r'^UC[\w-]{22}$');

/// Handles are 3–30 chars and may include non-Latin letters — only
/// reject separators rather than whitelisting a script.
final RegExp _kHandle = RegExp(r'^@[^\s/?#@&]{3,30}$');
final RegExp _kLegacyName = RegExp(r'^[\w.\-]{1,100}$');

/// Parse a user-entered / stored value into a [YouTubeTarget].
///
/// Channel forms: `@handle`, a `UC…` channel id, `c/name`, `user/name`, or
/// any youtube.com URL whose path starts with one of those (a trailing
/// `/live`, `/streams`, `/featured` … is ignored). Everything else falls
/// through to [extractYouTubeVideoId] (bare id, watch / live / share /
/// pop-out chat links). Returns `null` when neither matches.
YouTubeTarget? parseYouTubeTarget(String? input) {
  if (input == null) return null;
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  final channel = _parseChannel(trimmed);
  if (channel != null) return channel;

  final videoId = extractYouTubeVideoId(trimmed);
  return videoId == null ? null : YouTubeVideoTarget(videoId);
}

YouTubeChannelTarget? _parseChannel(String value) {
  if (_kHandle.hasMatch(value)) return YouTubeChannelTarget(value);
  if (_kChannelId.hasMatch(value)) {
    return YouTubeChannelTarget('channel/$value');
  }

  final looksLikeUrl =
      value.contains('://') ||
      value.toLowerCase().contains('youtube.com') ||
      value.startsWith('c/') ||
      value.startsWith('user/') ||
      value.startsWith('channel/');
  if (!looksLikeUrl) return null;

  final String url;
  if (value.contains('://')) {
    url = value;
  } else if (value.toLowerCase().contains('youtube.com')) {
    url = 'https://$value';
  } else {
    url = 'https://www.youtube.com/$value';
  }
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final host = uri.host.toLowerCase();
  if (host != 'youtube.com' && !host.endsWith('.youtube.com')) return null;

  /// A `v=` query always means one specific video, whatever the path.
  if ((uri.queryParameters['v'] ?? '').isNotEmpty) return null;

  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return null;
  final first = Uri.decodeComponent(segments.first);

  if (first.startsWith('@') && _kHandle.hasMatch(first)) {
    return YouTubeChannelTarget(first);
  }
  if (segments.length >= 2) {
    final name = Uri.decodeComponent(segments[1]);
    switch (first.toLowerCase()) {
      case 'channel':
        if (_kChannelId.hasMatch(name)) {
          return YouTubeChannelTarget('channel/$name');
        }
      case 'c':
      case 'user':
        if (_kLegacyName.hasMatch(name)) {
          return YouTubeChannelTarget('${first.toLowerCase()}/$name');
        }
    }
  }
  return null;
}
