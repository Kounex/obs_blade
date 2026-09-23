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

/// BTTV's overlay emotes — BTTV has no zero-width flag in its API, the
/// set is fixed (same list Chatterino hardcodes in `BttvEmotes.cpp`).
const Set<String> kBttvZeroWidthEmotes = {
  'SoSnowy',
  'IceCold',
  'SantaHat',
  'TopHat',
  'ReinDeer',
  'CandyCane',
  'cvMask',
  'cvHazmat',
};

/// 7TV active-emote flag bit for zero-width (`flags & 1`).
const int kSevenTvZeroWidthFlag = 1;

/// 7TV (v3), BTTV (v3) and FrankerFaceZ (v1) emote catalogs — the global
/// sets plus a channel's set. All three APIs are public, no auth.
///
/// [client] is injectable for tests — no real HTTP in unit tests.
class ThirdPartyEmoteService {
  final http.Client _client;

  ThirdPartyEmoteService({http.Client? client})
    : _client = client ?? http.Client();

  /// 7TV global emote set.
  Future<Map<String, ThirdPartyEmote>> fetchSevenTvGlobal() async {
    final body = await this._get(
      Uri.parse('https://7tv.io/v3/emote-sets/global'),
    );
    if (body is! Map<String, Object?>) return const {};
    return this._parseSevenTvEmotes(body['emotes']);
  }

  /// 7TV emote set of the channel with [broadcasterId] (its active set).
  Future<Map<String, ThirdPartyEmote>> fetchSevenTvChannel(
    String broadcasterId,
  ) => this._fetchSevenTvChannel(platform: 'twitch', id: broadcasterId);

  /// 7TV emote set of the Kick channel with [kickUserId] (its active
  /// set) — 7TV's `kick` platform is keyed by Kick's numeric USER id,
  /// not the channel/chatroom id (verified live: `/v3/users/kick/{id}`
  /// 404s for a channel id but resolves for the linked user id). BTTV
  /// has no Kick platform at all (`/3/cached/users/kick/{id}` 404s
  /// unconditionally, even for a real linked user) — there is no Kick
  /// counterpart to [fetchBttvChannel].
  Future<Map<String, ThirdPartyEmote>> fetchSevenTvKickChannel(
    String kickUserId,
  ) => this._fetchSevenTvChannel(platform: 'kick', id: kickUserId);

  Future<Map<String, ThirdPartyEmote>> _fetchSevenTvChannel({
    required String platform,
    required String id,
  }) async {
    final body = await this._get(
      Uri.parse('https://7tv.io/v3/users/$platform/$id'),
    );
    if (body is! Map<String, Object?>) return const {};
    final emoteSet = body['emote_set'];
    if (emoteSet is! Map<String, Object?>) return const {};
    return this._parseSevenTvEmotes(emoteSet['emotes']);
  }

  /// BTTV global emotes.
  Future<Map<String, ThirdPartyEmote>> fetchBttvGlobal() async {
    final body = await this._get(
      Uri.parse('https://api.betterttv.net/3/cached/emotes/global'),
    );
    return this._parseBttvEmotes(body);
  }

  /// BTTV emotes of the channel with [broadcasterId] — its own channel
  /// emotes plus the shared emotes enabled there (shared wins name ties).
  Future<Map<String, ThirdPartyEmote>> fetchBttvChannel(
    String broadcasterId,
  ) async {
    final body = await this._get(
      Uri.parse(
        'https://api.betterttv.net/3/cached/users/twitch/$broadcasterId',
      ),
    );
    if (body is! Map<String, Object?>) return const {};
    return {
      ...this._parseBttvEmotes(body['channelEmotes']),
      ...this._parseBttvEmotes(body['sharedEmotes']),
    };
  }

  /// FrankerFaceZ global emotes — the sets listed in `default_sets` (the
  /// response also carries opt-in sets that aren't global).
  Future<Map<String, ThirdPartyEmote>> fetchFfzGlobal() async {
    final body = await this._get(
      Uri.parse('https://api.frankerfacez.com/v1/set/global'),
    );
    if (body is! Map<String, Object?>) return const {};
    final defaults = body['default_sets'];
    final sets = body['sets'];
    if (defaults is! List || sets is! Map<String, Object?>) return const {};
    return {for (final id in defaults) ...this._parseFfzSet(sets['$id'])};
  }

  /// FrankerFaceZ emotes of the Twitch channel with [broadcasterId] (its
  /// room set). FFZ is Twitch-only — there is no Kick counterpart.
  Future<Map<String, ThirdPartyEmote>> fetchFfzChannel(
    String broadcasterId,
  ) async {
    final body = await this._get(
      Uri.parse('https://api.frankerfacez.com/v1/room/id/$broadcasterId'),
    );
    if (body is! Map<String, Object?>) return const {};
    final room = body['room'];
    final sets = body['sets'];
    if (room is! Map<String, Object?> || sets is! Map<String, Object?>) {
      return const {};
    }
    return this._parseFfzSet(sets['${room['set']}']);
  }

  /// FFZ shape: `{ emoticons: [{ name, urls: {1,2,4}, animated?: {…},
  /// modifier, modifier_flags }] }`. Animated emotes prefer the animated
  /// URL map (WebP). Effect modifiers (`modifier_flags != 0`, e.g.
  /// ffzHyper/ffzRainbow) transform the previous emote — not reproducible
  /// here, so they're skipped (stay text); image modifiers overlay.
  Map<String, ThirdPartyEmote> _parseFfzSet(Object? set) {
    if (set is! Map<String, Object?>) return const {};
    final emotes = set['emoticons'];
    if (emotes is! List) return const {};
    final parsed = <String, ThirdPartyEmote>{};
    for (final emote in emotes) {
      if (emote is! Map<String, Object?>) continue;
      final name = emote['name'];
      if (name is! String || name.isEmpty) continue;
      final modifier = emote['modifier'] == true;
      final modifierFlags = emote['modifier_flags'];
      if (modifier && modifierFlags is num && modifierFlags != 0) continue;
      String? pick(Object? urls) {
        if (urls is! Map<String, Object?>) return null;
        final url = urls['2'] ?? urls['1'];
        return url is String && url.isNotEmpty ? url : null;
      }

      final url = pick(emote['animated']) ?? pick(emote['urls']);
      if (url == null) continue;
      parsed[name] = ThirdPartyEmote(
        name: name,
        imageUrl: url.startsWith('//') ? 'https:$url' : url,
        zeroWidth: modifier,
      );
    }
    return parsed;
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
      if (id is! String || id.isEmpty || code is! String || code.isEmpty) {
        continue;
      }
      parsed[code] = ThirdPartyEmote(
        name: code,
        imageUrl: 'https://cdn.betterttv.net/emote/$id/2x',
        zeroWidth: kBttvZeroWidthEmotes.contains(code),
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
      if (name is! String || name.isEmpty || data is! Map<String, Object?>) {
        continue;
      }
      final host = data['host'];
      if (host is! Map<String, Object?>) continue;
      final url = host['url'];
      if (url is! String || url.isEmpty) continue;
      final flags = emote['flags'];
      parsed[name] = ThirdPartyEmote(
        name: name,
        imageUrl: 'https:$url/2x.webp',
        zeroWidth: flags is num && (flags.toInt() & kSevenTvZeroWidthFlag) != 0,
      );
    }
    return parsed;
  }
}
