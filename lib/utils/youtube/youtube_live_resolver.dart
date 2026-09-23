import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/utils/youtube_target.dart';

/// Resolving a channel's current live stream failed for a reason other
/// than "not live" (network, 4xx/5xx, unparseable page) — the caller
/// retries on its own backoff.
class YouTubeLiveResolveException implements Exception {
  final String message;
  final int? statusCode;

  const YouTubeLiveResolveException(this.message, {this.statusCode});

  @override
  String toString() => 'YouTubeLiveResolveException: $message';
}

/// Channel → current live video id, without spending Data API quota.
///
/// `youtube.com/<channel>/live` serves the live watch page when the
/// channel is live, and its `<link rel="canonical">` then points at
/// `watch?v=<id>`; offline (or only scheduled) channels keep a channel
/// canonical instead. Same technique as the `youtube-chat` npm package —
/// see `docs/chatterino-comparison.md` § YouTube. This page scrape only
/// *finds* the id; chat reads stay on the official Data API.
///
/// Unofficial by nature: the page layout can change without notice, so
/// the parse is deliberately tiny (one tag, two attribute orders) and a
/// pasted video id always bypasses this class.
class YouTubeLiveResolver {
  final http.Client _client;

  YouTubeLiveResolver({http.Client? client})
    : _client = client ?? http.Client();

  /// YouTube picks the page variant per request (mobile / desktop; e.g. an
  /// `Accept-Language` header moves the canonical tag from ~30 KB to
  /// ~700 KB deep, and offline channel pages emit it *after* `</head>`),
  /// so the body is streamed and dropped as soon as the tag has arrived.
  static const String kUserAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 '
      'Mobile/15E148 Safari/604.1';

  /// Pre-accepted consent cookies — without them EU requests land on
  /// `consent.youtube.com` instead of the channel page.
  static const String kConsentCookie = 'SOCS=CAI; CONSENT=YES+1';

  /// Tags can straddle chunk boundaries — each scan re-reads this much of
  /// the previous text.
  static const int _kScanOverlap = 4096;

  /// Give up after this many characters without a canonical tag (pages
  /// seen so far top out around 1.3 MB).
  static const int kMaxScanChars = 3 * 1024 * 1024;

  /// The live video id of [channel], or `null` when it isn't live right
  /// now. Throws [YouTubeLiveResolveException] for anything that isn't a
  /// clear answer (the caller shouldn't treat it as "offline").
  Future<String?> resolveLiveVideoId(YouTubeChannelTarget channel) async {
    final request = http.Request('GET', channel.liveUri)
      ..headers.addAll(const {
        'User-Agent': kUserAgent,
        'Cookie': kConsentCookie,
      });
    final http.StreamedResponse response;
    try {
      response = await this._client.send(request);
    } catch (e) {
      throw YouTubeLiveResolveException('Could not reach YouTube ($e)');
    }
    if (response.statusCode != 200) {
      unawaited(response.stream.listen(null).cancel());
      if (response.statusCode == 404) {
        throw YouTubeLiveResolveException(
          'YouTube channel ${channel.displayName} not found',
          statusCode: 404,
        );
      }
      throw YouTubeLiveResolveException(
        'Looking up ${channel.displayName} failed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    /// Only the unscanned tail (+ overlap) is searched per chunk — the
    /// desktop variant is >1 MB, rescanning everything would be quadratic.
    var window = '';
    var scanned = 0;
    try {
      await for (final chunk in response.stream.transform(
        const Utf8Decoder(allowMalformed: true),
      )) {
        window += chunk;
        scanned += chunk.length;
        final href = _findCanonicalHref(window);
        if (href != null) return _videoIdFromCanonical(href);
        if (scanned > kMaxScanChars) break;
        if (window.length > _kScanOverlap) {
          window = window.substring(window.length - _kScanOverlap);
        }
      }
    } catch (e) {
      throw YouTubeLiveResolveException('Reading the YouTube page failed ($e)');
    }
    return parseLiveVideoIdFromChannelPage(window);
  }
}

final RegExp _kLinkTag = RegExp(r'<link\b[^>]*>', caseSensitive: false);
final RegExp _kRelCanonical = RegExp(
  r'''\brel\s*=\s*["']canonical["']''',
  caseSensitive: false,
);
final RegExp _kHref = RegExp(r'''\bhref\s*=\s*["']([^"']+)["']''');
final RegExp _kWatchId = RegExp(r'[?&]v=([\w-]{11})(?![\w-])');

/// Pull the live video id out of a `<channel>/live` page — `null` when the
/// canonical isn't a watch URL (channel not live). Throws
/// [YouTubeLiveResolveException] when no canonical exists at all (consent
/// wall, captcha, layout change): that's "unknown", not "offline".
String? parseLiveVideoIdFromChannelPage(String html) {
  final href = _findCanonicalHref(html);
  if (href == null) {
    throw const YouTubeLiveResolveException(
      'Unexpected YouTube page (no canonical link)',
    );
  }
  return _videoIdFromCanonical(href);
}

/// `href` of the first complete `<link rel="canonical">` tag, if any.
String? _findCanonicalHref(String html) {
  for (final match in _kLinkTag.allMatches(html)) {
    final tag = match.group(0)!;
    if (!_kRelCanonical.hasMatch(tag)) continue;
    final href = _kHref.firstMatch(tag)?.group(1);
    if (href != null) return href;
  }
  return null;
}

String? _videoIdFromCanonical(String href) {
  final decoded = href.replaceAll('&amp;', '&');
  if (!decoded.contains('/watch')) return null;
  return _kWatchId.firstMatch(decoded)?.group(1);
}
