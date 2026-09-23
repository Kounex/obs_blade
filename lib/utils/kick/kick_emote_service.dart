import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/kick/kick_emote.dart';
import 'package:obs_blade/utils/kick/kick_channel_service.dart'
    show KickApiException, kKickUserAgent;

const String _kEmotesBase = 'https://kick.com';

/// Kick's channel-emote catalog for the picker — `GET /emotes/{slug}`
/// (same Cloudflare-fronted host + UA policy as `KickChannelService`, no
/// auth). Verified live 2026-09-23 against a real channel (xQc): the
/// response is a JSON array of THREE entries — the requested channel's
/// own emote set first, then Kick's platform-wide `Global` and `Emojis`
/// sets. There is no separate "global emotes" endpoint, but this one
/// conveniently bundles all three in a single call.
class KickEmoteService {
  final http.Client _client;

  KickEmoteService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => const {
    'User-Agent': kKickUserAgent,
    'Accept': 'application/json',
  };

  Future<List<KickEmoteSection>> fetchChannelEmotes(String slug) async {
    final response = await this._client.get(
      Uri.parse('$_kEmotesBase/emotes/$slug'),
      headers: this._headers,
    );
    if (response.statusCode != 200) {
      throw KickApiException(
        'Loading Kick emotes failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) return const [];

    final sections = <KickEmoteSection>[];
    for (var i = 0; i < decoded.length; i++) {
      final entry = decoded[i];
      if (entry is! Map) continue;
      final rawEmotes = entry['emotes'];
      if (rawEmotes is! List) continue;

      final emotes = <KickEmote>[];
      for (final raw in rawEmotes) {
        if (raw is! Map) continue;
        try {
          emotes.add(KickEmote.fromJson(raw.cast<String, Object?>()));
        } catch (_) {
          /// One malformed emote entry must not fail the whole catalog.
        }
      }
      if (emotes.isEmpty) continue;

      /// The channel's own set (always first) carries no `name` field —
      /// the platform-wide sets that follow do (`'Global'`, `'Emojis'`).
      final label = i == 0
          ? 'Channel'
          : (entry['name'] is String ? entry['name'] as String : 'More');
      sections.add(KickEmoteSection(label: label, emotes: emotes));
    }
    return sections;
  }
}
