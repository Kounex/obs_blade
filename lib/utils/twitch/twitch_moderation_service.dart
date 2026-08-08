import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';

/// Helix mod actions for the multi-chat mod action sheet — delete a
/// message, timeout or ban a user — in any channel the logged-in user
/// moderates. Requires a user access token with
/// `moderator:manage:chat_messages` (delete) and
/// `moderator:manage:banned_users` (timeout/ban); see `kTwitchChatScopes`.
///
/// [client] is injectable for tests — no real HTTP in unit tests.
class TwitchModerationService {
  final http.Client _client;

  TwitchModerationService({http.Client? client})
      : _client = client ?? http.Client();

  /// Delete one chat message (Helix answers 204 No Content).
  Future<void> deleteChatMessage({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
    required String messageId,
  }) async {
    final response = await this._client.delete(
      Uri.parse('$kTwitchHelixBase/moderation/chat').replace(queryParameters: {
        'broadcaster_id': broadcasterId,
        'moderator_id': moderatorId,
        'message_id': messageId,
      }),
      headers: TwitchAuthService.helixHeaders(accessToken),
    );
    if (response.statusCode != 204) {
      throw TwitchAuthException(
        'Deleting a Twitch chat message failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
  }

  /// Ban [userId] in [broadcasterId]'s channel, or time them out when
  /// [durationSeconds] is given (the `duration` key is omitted for a
  /// permanent ban — Helix treats its presence as a timeout).
  Future<void> banUser({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
    required String userId,
    int? durationSeconds,
  }) async {
    final response = await this._client.post(
      Uri.parse('$kTwitchHelixBase/moderation/bans').replace(queryParameters: {
        'broadcaster_id': broadcasterId,
        'moderator_id': moderatorId,
      }),
      headers: {
        ...TwitchAuthService.helixHeaders(accessToken),
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'data': {
          'user_id': userId,
          if (durationSeconds != null) 'duration': durationSeconds,
        },
      }),
    );
    if (response.statusCode != 200) {
      throw TwitchAuthException(
        'Banning a Twitch user failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
  }
}
