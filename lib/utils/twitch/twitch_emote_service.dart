import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/twitch/twitch_user_emote.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';

/// Helix `chat/emotes/user` endpoint — the emotes the authenticated user
/// can use in a channel's chat (globals + that channel's own). Requires the
/// `user:read:emotes` scope.
///
/// [client] is injectable for tests — no real HTTP in unit tests.
class TwitchEmoteService {
  /// Defensive cap on pagination rounds — a misbehaving cursor must not
  /// loop forever (realistic catalogs are 1-3 pages).
  static const int kMaxPages = 50;

  final http.Client _client;

  TwitchEmoteService({http.Client? client})
      : _client = client ?? http.Client();

  /// All emotes usable by [userId] in [broadcasterId]'s chat, accumulated
  /// across pages.
  Future<List<TwitchUserEmote>> fetchUserEmotes(
    String accessToken, {
    required String userId,
    required String broadcasterId,
  }) async {
    final emotes = <TwitchUserEmote>[];
    String? after;
    for (var page = 0; page < kMaxPages; page++) {
      final result = await this._fetchPage(
        accessToken,
        userId: userId,
        broadcasterId: broadcasterId,
        after: after,
      );
      emotes.addAll(result.$1);
      if (result.$2 == null) return emotes;
      after = result.$2;
    }
    return emotes;
  }

  /// One page: (emotes, next cursor). A null/empty cursor means last page.
  Future<(List<TwitchUserEmote>, String?)> _fetchPage(
    String accessToken, {
    required String userId,
    required String broadcasterId,
    String? after,
  }) async {
    final response = await this._client.get(
      Uri.parse(
        '$kTwitchHelixBase/chat/emotes/user?user_id=$userId'
        '&broadcaster_id=$broadcasterId'
        '${after != null ? '&after=${Uri.encodeComponent(after)}' : ''}',
      ),
      headers: TwitchAuthService.helixHeaders(accessToken),
    );
    if (response.statusCode != 200) {
      throw TwitchAuthException(
        'Fetching Twitch user emotes failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    final body = json.decode(response.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is! List) {
      throw const TwitchAuthException(
          'Fetching Twitch user emotes returned no data');
    }
    final pagination = body['pagination'];
    final cursor = pagination is Map<String, dynamic>
        ? pagination['cursor'] as String?
        : null;
    return (
      [
        for (final emote in data)
          if (emote is Map<String, Object?> &&
              emote['id'] is String &&
              emote['name'] is String)
            TwitchUserEmote.fromJson(emote),
      ],
      (cursor != null && cursor.isNotEmpty) ? cursor : null,
    );
  }
}
