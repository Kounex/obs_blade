import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/twitch/third_party_emote.dart';

/// Failure of a third-party emote endpoint (non-200 other than 404 —
/// a 404 means "channel has no presence there" and degrades to empty).
class ThirdPartyEmoteException implements Exception {
  final String message;
  final int? statusCode;

  const ThirdPartyEmoteException(this.message, {this.statusCode});

  @override
  String toString() =>
      'ThirdPartyEmoteException: ${this.message}'
      '${this.statusCode != null ? ' (status ${this.statusCode})' : ''}';
}

/// 7TV (v3) and BTTV (v3) emote catalogs — the global sets plus a
/// channel's set. Both APIs are public, no auth.
///
/// [client] is injectable for tests — no real HTTP in unit tests.
class ThirdPartyEmoteService {
  final http.Client _client;

  ThirdPartyEmoteService({http.Client? client})
      : _client = client ?? http.Client();

  /// 7TV global emote set.
  Future<Map<String, ThirdPartyEmote>> fetchSevenTvGlobal() async {
    final body =
        await this._get(Uri.parse('https://7tv.io/v3/emote-sets/global'));
    if (body is! Map<String, Object?>) return const {};
    return this._parseSevenTvEmotes(body['emotes']);
  }

  /// 7TV emote set of the channel with [broadcasterId] (its active set).
  Future<Map<String, ThirdPartyEmote>> fetchSevenTvChannel(
      String broadcasterId) async {
    final body = await this
        ._get(Uri.parse('https://7tv.io/v3/users/twitch/$broadcasterId'));
    if (body is! Map<String, Object?>) return const {};
    final emoteSet = body['emote_set'];
    if (emoteSet is! Map<String, Object?>) return const {};
    return this._parseSevenTvEmotes(emoteSet['emotes']);
  }

  /// BTTV global emotes.
  Future<Map<String, ThirdPartyEmote>> fetchBttvGlobal() async {
    final body = await this._get(
        Uri.parse('https://api.betterttv.net/3/cached/emotes/global'));
    return this._parseBttvEmotes(body);
  }

  /// BTTV emotes of the channel with [broadcasterId] — its own channel
  /// emotes plus the shared emotes enabled there (shared wins name ties).
  Future<Map<String, ThirdPartyEmote>> fetchBttvChannel(
      String broadcasterId) async {
    final body = await this._get(Uri.parse(
        'https://api.betterttv.net/3/cached/users/twitch/$broadcasterId'));
    if (body is! Map<String, Object?>) return const {};
    return {
      ...this._parseBttvEmotes(body['channelEmotes']),
      ...this._parseBttvEmotes(body['sharedEmotes']),
    };
  }

  /// BTTV shape: flat `{ id, code }` entries; the CDN serves the animated
  /// variant when the emote has one.
  Map<String, ThirdPartyEmote> _parseBttvEmotes(Object? emotes) {
    if (emotes is! List) return const {};
    final parsed = <String, ThirdPartyEmote>{};
    for (final emote in emotes) {
      if (emote is! Map<String, Object?>) continue;
      final id = emote['id'];
      final code = emote['code'];
      if (id is! String ||
          id.isEmpty ||
          code is! String ||
          code.isEmpty) {
        continue;
      }
      parsed[code] = ThirdPartyEmote(
        name: code,
        imageUrl: 'https://cdn.betterttv.net/emote/$id/2x',
      );
    }
    return parsed;
  }

  /// 404 → null (channel without a presence — expected, not an error).
  /// Other non-200 → [ThirdPartyEmoteException].
  Future<Object?> _get(Uri uri) async {
    final response = await this._client.get(uri);
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw ThirdPartyEmoteException(
        'GET $uri failed',
        statusCode: response.statusCode,
      );
    }
    return json.decode(response.body);
  }

  /// 7TV shape: `{ name, data: { host: { url } } }` — `host.url` is
  /// protocol-relative (`//cdn.7tv.app/emote/{id}`); `2x.webp` keeps the
  /// animation and Flutter decodes WebP (AVIF variants are skipped on
  /// purpose: no Flutter decoder).
  Map<String, ThirdPartyEmote> _parseSevenTvEmotes(Object? emotes) {
    if (emotes is! List) return const {};
    final parsed = <String, ThirdPartyEmote>{};
    for (final emote in emotes) {
      if (emote is! Map<String, Object?>) continue;
      final name = emote['name'];
      final data = emote['data'];
      if (name is! String ||
          name.isEmpty ||
          data is! Map<String, Object?>) {
        continue;
      }
      final host = data['host'];
      if (host is! Map<String, Object?>) continue;
      final url = host['url'];
      if (url is! String || url.isEmpty) continue;
      parsed[name] =
          ThirdPartyEmote(name: name, imageUrl: 'https:$url/2x.webp');
    }
    return parsed;
  }
}
