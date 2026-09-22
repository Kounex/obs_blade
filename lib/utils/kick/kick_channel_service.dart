import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';

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

  KickChannelService({http.Client? client}) : _client = client ?? http.Client();

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
  /// sort oldest). Unparseable entries are skipped one by one. Note: this
  /// endpoint encodes nested `metadata` as a JSON STRING — the DTOs
  /// tolerate both shapes (see [kickJsonObject]).
  Future<List<KickChatMessage>> backfillMessages(int channelId) async {
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
    if (rawMessages is! List) return const [];
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
    return messages;
  }
}
