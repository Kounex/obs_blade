import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/twitch/twitch_send_result.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';

/// Helix `chat/messages` endpoint — sends a chat message as the
/// authenticated user into [broadcasterId]'s channel (their own channel
/// in single-chat mode, any added channel in multi-chat). Requires a user
/// access token with the `user:write:chat` scope (see `kTwitchChatScopes`).
///
/// [client] is injectable for tests — no real HTTP in unit tests.
class TwitchMessageService {
  final http.Client _client;

  TwitchMessageService({http.Client? client})
      : _client = client ?? http.Client();

  Future<TwitchSendResult> sendChatMessage({
    required String accessToken,
    required String senderId,
    required String broadcasterId,
    required String message,

    /// Threaded reply target — Helix `reply_parent_message_id`. Null sends
    /// a plain top-level message.
    String? replyParentMessageId,
  }) async {
    final response = await this._client.post(
      Uri.parse('$kTwitchHelixBase/chat/messages'),
      headers: {
        ...TwitchAuthService.helixHeaders(accessToken),
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'broadcaster_id': broadcasterId,
        'sender_id': senderId,
        'message': message,
        if (replyParentMessageId != null)
          'reply_parent_message_id': replyParentMessageId,
      }),
    );
    if (response.statusCode != 200) {
      throw TwitchAuthException(
        'Sending Twitch chat message failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    final data = (json.decode(response.body) as Map<String, dynamic>)['data'];
    if (data is! List || data.isEmpty) {
      throw const TwitchAuthException(
          'Sending Twitch chat message returned no data');
    }
    return TwitchSendResult.fromJson(data.first as Map<String, Object?>);
  }
}
