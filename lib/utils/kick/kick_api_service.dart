import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/utils/kick/kick_auth_service.dart'
    show KickUserIdentity;
import 'package:obs_blade/utils/kick/kick_channel_service.dart';

/// Supplies a valid access token for authed calls — [forceRefresh] asks
/// the owner (the chat store) to refresh the persisted token first (the
/// 401 retry path). Throws when no usable session exists.
typedef KickTokenProvider =
    Future<String> Function({required bool forceRefresh});

/// Kick's official write/moderation REST surface (`api.kick.com/public/v1`,
/// Bearer token, JSON) — send, delete, ban/timeout, unban. Reads stay on
/// the anonymous [KickChannelService]/Pusher path; errors are the shared
/// [KickApiException] (its [KickApiException.statusCode] lets the UI tell
/// an honest 403 "not a mod" from a 429 rate limit).
///
/// Auth resilience: any call that comes back 401 refreshes the token once
/// (via [KickTokenProvider]) and retries the call once — a second 401
/// surfaces as a typed error.
class KickApiService {
  static const String _kApiBase = 'https://api.kick.com/public/v1';

  /// Kick caps chat messages at 500 chars (mirrored in the input dock).
  static const int kMaxMessageLength = 500;

  final http.Client _client;
  final KickTokenProvider _tokenProvider;

  KickApiService({
    http.Client? client,
    required KickTokenProvider tokenProvider,
  }) : _client = client ?? http.Client(),
       _tokenProvider = tokenProvider;

  Map<String, String> _headers(String token) => <String, String>{
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// Run [call] with a valid token; on 401 refresh once and retry once.
  Future<http.Response> _authed(
    Future<http.Response> Function(String token) call,
  ) async {
    var response = await call(await this._tokenProvider(forceRefresh: false));
    if (response.statusCode == 401) {
      response = await call(await this._tokenProvider(forceRefresh: true));
    }
    return response;
  }

  /// Typed failure with an honest message for the statuses the UI
  /// distinguishes: 403 (not a mod / chat-mode restriction), 429 (rate
  /// limit), 401-after-retry (dead session).
  KickApiException _error(String action, http.Response response) {
    final status = response.statusCode;
    final message = switch (status) {
      401 => '$action - the Kick session expired, sign in again',
      403 =>
        '$action - no permission (moderator status or a chat mode restriction)',
      429 => '$action - Kick rate limit hit, wait a moment',
      _ => '$action ($status)',
    };
    return KickApiException(message, cause: response.body, statusCode: status);
  }

  /// `POST /chat` — send [content] (max [kMaxMessageLength] chars) to the
  /// channel owned by [broadcasterUserId], optionally as a reply to
  /// [replyToMessageId]. Returns the sent message id (the Pusher echo's
  /// dedup key).
  Future<String> sendMessage({
    required int broadcasterUserId,
    required String content,
    String? replyToMessageId,
  }) async {
    final response = await this._authed(
      (token) => this._client.post(
        Uri.parse('$_kApiBase/chat'),
        headers: this._headers(token),
        body: json.encode(<String, Object?>{
          'type': 'user',
          'broadcaster_user_id': broadcasterUserId,
          'content': content,
          'reply_to_message_id': ?replyToMessageId,
        }),
      ),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw this._error('Could not send the message', response);
    }
    final data = (json.decode(response.body) as Map).cast<String, Object?>();
    final payload = data['data'];
    final messageId = payload is Map ? payload['message_id'] : null;
    final isSent = payload is Map ? payload['is_sent'] : null;
    if (isSent != true || messageId is! String || messageId.isEmpty) {
      throw KickApiException(
        'Kick did not accept the message',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    return messageId;
  }

  /// `DELETE /chat/{message_id}` — 204 on success; 403 = not a mod.
  Future<void> deleteMessage({required String messageId}) async {
    final response = await this._authed(
      (token) => this._client.delete(
        Uri.parse('$_kApiBase/chat/$messageId'),
        headers: this._headers(token),
      ),
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw this._error('Could not delete the message', response);
    }
  }

  /// `POST /moderation/bans` — ban [userId] in the channel owned by
  /// [broadcasterUserId]; [durationMinutes] (1..10080) makes it a timeout,
  /// omitted = permanent. [reason] is capped at 100 chars by Kick.
  Future<void> banUser({
    required int broadcasterUserId,
    required int userId,
    int? durationMinutes,
    String? reason,
  }) async {
    final response = await this._authed(
      (token) => this._client.post(
        Uri.parse('$_kApiBase/moderation/bans'),
        headers: this._headers(token),
        body: json.encode(<String, Object?>{
          'broadcaster_user_id': broadcasterUserId,
          'user_id': userId,
          'duration': ?durationMinutes,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        }),
      ),
    );
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw this._error('Could not ban the user', response);
    }
  }

  /// `GET /users?id=` — best-effort profile lookup for the user card
  /// (name + avatar only; Kick's public API has no account-age, follow
  /// or subscription data for arbitrary users). Requires a signed-in
  /// reader's token (`user:read`, in the always-held scope bundle) —
  /// anonymous readers never call this.
  Future<KickUserIdentity?> fetchUser(int userId) async {
    final response = await this._authed(
      (token) => this._client.get(
        Uri.parse('$_kApiBase/users?id=$userId'),
        headers: this._headers(token),
      ),
    );
    if (response.statusCode != 200) {
      throw this._error('Could not fetch the user', response);
    }
    final data = (json.decode(response.body) as Map)['data'];
    if (data is! List || data.isEmpty) return null;
    final user = data.first;
    if (user is! Map) return null;
    final id = user['user_id'];
    if (id is! int) return null;
    return KickUserIdentity(
      userId: id,
      name: user['name'] as String?,
      profilePicture: user['profile_picture'] as String?,
    );
  }

  /// `DELETE /moderation/bans` — lift a ban / remove a timeout. Note:
  /// a DELETE WITH a JSON body (Kick's spec), so this goes through a
  /// streamed [http.Request].
  Future<void> unbanUser({
    required int broadcasterUserId,
    required int userId,
  }) async {
    final response = await this._authed((token) async {
      final request = http.Request(
        'DELETE',
        Uri.parse('$_kApiBase/moderation/bans'),
      );
      request.headers.addAll(this._headers(token));
      request.body = json.encode(<String, Object?>{
        'broadcaster_user_id': broadcasterUserId,
        'user_id': userId,
      });
      return http.Response.fromStream(await this._client.send(request));
    });
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw this._error('Could not lift the ban', response);
    }
  }
}
