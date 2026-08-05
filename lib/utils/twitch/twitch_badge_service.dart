import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/twitch/twitch_chat_badges.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';

/// Helix `chat/badges` endpoints — the global catalog and the per-channel
/// catalog (subscriber tenure / bits tier variants). Any user access token
/// works, no extra scope.
///
/// [client] is injectable for tests — no real HTTP in unit tests.
class TwitchBadgeService {
  final http.Client _client;

  TwitchBadgeService({http.Client? client})
      : _client = client ?? http.Client();

  Future<List<TwitchBadgeSet>> fetchGlobalBadges(String accessToken) =>
      this._fetch(
        Uri.parse('$kTwitchHelixBase/chat/badges/global'),
        accessToken,
      );

  Future<List<TwitchBadgeSet>> fetchChannelBadges(
    String accessToken,
    String broadcasterId,
  ) =>
      this._fetch(
        Uri.parse(
            '$kTwitchHelixBase/chat/badges?broadcaster_id=$broadcasterId'),
        accessToken,
      );

  Future<List<TwitchBadgeSet>> _fetch(Uri uri, String accessToken) async {
    final response = await this._client.get(
      uri,
      headers: TwitchAuthService.helixHeaders(accessToken),
    );
    if (response.statusCode != 200) {
      throw TwitchAuthException(
        'Fetching Twitch chat badges failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    final data = (json.decode(response.body) as Map<String, dynamic>)['data'];
    if (data is! List) {
      throw const TwitchAuthException(
          'Fetching Twitch chat badges returned no data');
    }
    return [
      for (final set in data)
        TwitchBadgeSet.fromJson(set as Map<String, Object?>),
    ];
  }
}
