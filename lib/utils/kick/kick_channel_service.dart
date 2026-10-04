import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/types/classes/kick/kick_channel_suggestion.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/utils/renewing_http_client.dart';

const String _kApiBase = 'https://kick.com/api/v2';

/// kick.com sits behind Cloudflare. A browser User-Agent on dart:io's TLS
/// fingerprint is rejected ("Request blocked by security policy", verified
/// 2026-09-23 — the same request with no browser agent returns 200). Reads
/// send this plain app agent instead. Do not spoof Safari or Chrome here.
const String kKickUserAgent = 'OBSBlade';

/// Failure of a kick.com API call the UI can surface via [message].
class KickApiException implements Exception {
  final String message;
  final Object? cause;
  final int? statusCode;

  const KickApiException(this.message, {this.cause, this.statusCode});

  @override
  String toString() =>
      'KickApiException: $message${this.cause != null ? ' (${this.cause})' : ''}';
}

/// Kick's public REST surface for chat reads — same idiom as
/// `lib/utils/youtube/` ([client] is injectable, no real HTTP in tests).
/// No auth: channel resolution + history backfill are anonymous.
class KickChannelService {
  final http.Client _client;

  KickChannelService({http.Client? client})
    : _client = client ?? RenewingHttpClient();

  Map<String, String> get _headers => const {
    'User-Agent': kKickUserAgent,
    'Accept': 'application/json',
  };

  /// `GET /channels/{slug}` — resolves a channel slug to the chatroom
  /// descriptor (id + modes) and the live status. Null = the channel does
  /// not exist (404) — a normal state, not an error.
  Future<KickChannelInfo?> resolveChannel(String slug) async {
    final response = await this._client.get(
      Uri.parse('$_kApiBase/channels/$slug'),
      headers: this._headers,
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw KickApiException(
        'Resolving the Kick channel failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    return KickChannelInfo.fromJson(
      (json.decode(response.body) as Map).cast<String, Object?>(),
    );
  }

  /// `GET /channels/{channel_id}/messages` — recent history (newest ~50),
  /// returned in arrival order (sorted by `created_at`; undated entries
  /// sort oldest), plus the channel's current pin (`data.pinned_message`,
  /// null when nothing is pinned). Unparseable entries are skipped one by
  /// one. Note: this endpoint encodes nested `metadata` as a JSON STRING —
  /// the DTOs tolerate both shapes (see [kickJsonObject]).
  Future<KickChatBackfill> backfillMessages(int channelId) async {
    final response = await this._client.get(
      Uri.parse('$_kApiBase/channels/$channelId/messages'),
      headers: this._headers,
    );
    if (response.statusCode != 200) {
      throw KickApiException(
        'Loading the Kick chat history failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    final body = (json.decode(response.body) as Map).cast<String, Object?>();
    final data = body['data'];
    final rawMessages = data is Map
        ? data['messages']
        : data is List
        ? data
        : null;
    final pinned = data is Map
        ? kickPinnedMessage(data['pinned_message'])
        : null;
    if (rawMessages is! List) {
      return KickChatBackfill(messages: const [], pinnedMessage: pinned);
    }
    final messages = <KickChatMessage>[];
    for (final raw in rawMessages) {
      final map = raw is Map ? raw.cast<String, Object?>() : null;
      if (map == null) continue;
      try {
        messages.add(KickChatMessage.fromJson(map));
      } catch (_) {
        // one malformed history entry must not fail the backfill
      }
    }
    messages.sort(
      (a, b) => (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
    );
    return KickChatBackfill(messages: messages, pinnedMessage: pinned);
  }

  /// Fewest characters `kick.com/api/search` accepts — shorter queries
  /// answer 400 "Please enter at least 3 characters".
  static const int kSearchMinLength = 3;

  /// `GET kick.com/api/search?searched_word=` — the website's own channel
  /// search (Kick's official API has none). Anonymous; answers the top 20
  /// channels by followers with live flag and verified seal (verified
  /// 2026-10-03). Undocumented, like the other `kick.com/api` reads here,
  /// so callers keep a paste-the-slug fallback. Queries under
  /// [kSearchMinLength] return empty without a request.
  Future<List<KickChannelSuggestion>> searchChannels(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < kSearchMinLength) return const [];
    final response = await this._client.get(
      Uri.parse(
        'https://kick.com/api/search',
      ).replace(queryParameters: {'searched_word': trimmed}),
      headers: this._headers,
    );
    if (response.statusCode != 200) {
      throw KickApiException(
        'Searching Kick channels failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    final body = json.decode(response.body);
    final channels = body is Map ? body['channels'] : null;
    if (channels is! List) return const [];
    return [
      for (final raw in channels) ?KickChannelSuggestion.fromSearchJson(raw),
    ];
  }
}

/// History backfill plus the pin that was active when it was fetched.
class KickChatBackfill {
  final List<KickChatMessage> messages;
  final KickChatMessage? pinnedMessage;

  const KickChatBackfill({required this.messages, this.pinnedMessage});
}
