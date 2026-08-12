import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/twitch/chat_settings.dart';
import 'package:obs_blade/types/classes/twitch/twitch_banned_user.dart';
import 'package:obs_blade/types/classes/twitch/twitch_pinned_message.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';

/// Helix mod actions for the multi-chat mod action sheet — delete a
/// message, timeout or ban a user, clear chat, chat modes, Shield Mode,
/// announcements, message pins, and the ban inbox (banned users, unban,
/// pending unban requests) — in any channel the logged-in user moderates
/// (the banned-users list is the exception: Helix only serves the token
/// user's own channel there).
/// Requires a user access token with `moderator:manage:chat_messages`
/// (delete / clear / pins), `moderator:manage:banned_users` (timeout/ban/
/// unban), `moderator:manage:chat_settings` (modes),
/// `moderator:manage:shield_mode` (shield), and
/// `moderator:manage:announcements` (announce); see
/// `kTwitchChatScopes`. Reading the pinned message only needs
/// `moderator:read:chat_messages`, the ban list `moderator:manage:
/// banned_users` (or `moderation:read`, not requested), and unban
/// requests `moderator:read:unban_requests` — all in the held bundles.
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

  /// Clear all chat messages in [broadcasterId]'s channel (Helix 204).
  /// Omits `message_id` — the same endpoint as [deleteChatMessage].
  Future<void> clearChat({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
  }) async {
    final response = await this._client.delete(
      Uri.parse('$kTwitchHelixBase/moderation/chat').replace(queryParameters: {
        'broadcaster_id': broadcasterId,
        'moderator_id': moderatorId,
      }),
      headers: TwitchAuthService.helixHeaders(accessToken),
    );
    if (response.statusCode != 204) {
      throw TwitchAuthException(
        'Clearing Twitch chat failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
  }

  /// Fetch current chat mode settings for [broadcasterId]'s channel.
  Future<TwitchChatSettings> getChatSettings({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
  }) async {
    final response = await this._client.get(
      Uri.parse('$kTwitchHelixBase/chat/settings').replace(queryParameters: {
        'broadcaster_id': broadcasterId,
        'moderator_id': moderatorId,
      }),
      headers: TwitchAuthService.helixHeaders(accessToken),
    );
    if (response.statusCode != 200) {
      throw TwitchAuthException(
        'Fetching Twitch chat settings failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    final data = json.decode(response.body) as Map<String, Object?>;
    final rows = data['data'] as List<Object?>?;
    if (rows == null || rows.isEmpty) {
      throw TwitchAuthException(
        'Fetching Twitch chat settings returned no data',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    return TwitchChatSettings.fromHelixJson(
      rows.first as Map<String, Object?>,
    );
  }

  /// Patch chat mode settings — only non-null parameters are sent.
  Future<void> updateChatSettings({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
    bool? emoteMode,
    bool? followerMode,
    int? followerModeDurationMinutes,
    bool? subscriberMode,
    bool? slowMode,
    int? slowModeWaitTimeSeconds,
    bool? uniqueChatMode,
  }) async {
    final body = <String, Object?>{
      if (emoteMode != null) 'emote_mode': emoteMode,
      if (followerMode != null) 'follower_mode': followerMode,
      if (followerModeDurationMinutes != null)
        'follower_mode_duration': followerModeDurationMinutes,
      if (subscriberMode != null) 'subscriber_mode': subscriberMode,
      if (slowMode != null) 'slow_mode': slowMode,
      if (slowModeWaitTimeSeconds != null)
        'slow_mode_wait_time': slowModeWaitTimeSeconds,
      if (uniqueChatMode != null) 'unique_chat_mode': uniqueChatMode,
    };
    final response = await this._client.patch(
      Uri.parse('$kTwitchHelixBase/chat/settings').replace(queryParameters: {
        'broadcaster_id': broadcasterId,
        'moderator_id': moderatorId,
      }),
      headers: {
        ...TwitchAuthService.helixHeaders(accessToken),
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );
    if (response.statusCode != 204) {
      throw TwitchAuthException(
        'Updating Twitch chat settings failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
  }

  /// Whether Shield Mode is active in [broadcasterId]'s channel.
  Future<bool> getShieldModeStatus({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
  }) async {
    final response = await this._client.get(
      Uri.parse('$kTwitchHelixBase/moderation/shield_mode')
          .replace(queryParameters: {
        'broadcaster_id': broadcasterId,
        'moderator_id': moderatorId,
      }),
      headers: TwitchAuthService.helixHeaders(accessToken),
    );
    if (response.statusCode != 200) {
      throw TwitchAuthException(
        'Fetching Twitch Shield Mode status failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    final data = json.decode(response.body) as Map<String, Object?>;
    final rows = data['data'] as List<Object?>?;
    if (rows == null || rows.isEmpty) {
      throw TwitchAuthException(
        'Fetching Twitch Shield Mode status returned no data',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    return (rows.first as Map<String, Object?>)['is_active'] as bool? ?? false;
  }

  /// Enable or disable Shield Mode in [broadcasterId]'s channel.
  Future<void> updateShieldModeStatus({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
    required bool isActive,
  }) async {
    final response = await this._client.put(
      Uri.parse('$kTwitchHelixBase/moderation/shield_mode')
          .replace(queryParameters: {
        'broadcaster_id': broadcasterId,
        'moderator_id': moderatorId,
      }),
      headers: {
        ...TwitchAuthService.helixHeaders(accessToken),
        'Content-Type': 'application/json',
      },
      body: json.encode({'is_active': isActive}),
    );
    if (response.statusCode != 200) {
      throw TwitchAuthException(
        'Updating Twitch Shield Mode failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
  }

  /// Post a chat announcement in [broadcasterId]'s channel (Helix 204).
  Future<void> sendChatAnnouncement({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
    required String message,
    required String color,
  }) async {
    final response = await this._client.post(
      Uri.parse('$kTwitchHelixBase/chat/announcements')
          .replace(queryParameters: {
        'broadcaster_id': broadcasterId,
        'moderator_id': moderatorId,
      }),
      headers: {
        ...TwitchAuthService.helixHeaders(accessToken),
        'Content-Type': 'application/json',
      },
      body: json.encode({'message': message, 'color': color}),
    );
    if (response.statusCode != 204) {
      throw TwitchAuthException(
        'Sending a Twitch chat announcement failed (${response.statusCode})',
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

  /// Fetch the currently pinned chat message in [broadcasterId]'s channel,
  /// or null when nothing is pinned (Helix answers 200 with empty `data`
  /// — at most one pin per channel, and there is no EventSub for pins, so
  /// callers re-fetch after local pin/unpin mutations).
  Future<TwitchPinnedMessage?> getPinnedChatMessage({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
  }) async {
    final response = await this._client.get(
      Uri.parse('$kTwitchHelixBase/chat/pins').replace(queryParameters: {
        'broadcaster_id': broadcasterId,
        'moderator_id': moderatorId,
      }),
      headers: TwitchAuthService.helixHeaders(accessToken),
    );
    if (response.statusCode != 200) {
      throw TwitchAuthException(
        'Fetching the pinned Twitch chat message failed '
        '(${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    final data = json.decode(response.body) as Map<String, Object?>;
    final rows = data['data'] as List<Object?>?;
    if (rows == null || rows.isEmpty) {
      return null;
    }
    return TwitchPinnedMessage.fromHelixJson(
      rows.first as Map<String, Object?>,
    );
  }

  /// Pin [messageId] in [broadcasterId]'s channel until the stream ends
  /// (Helix 204; auto-replaces an existing pin). `duration_seconds` is
  /// intentionally not exposed — OBS Blade always pins without expiry.
  Future<void> pinChatMessage({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
    required String messageId,
  }) async {
    final response = await this._client.put(
      Uri.parse('$kTwitchHelixBase/chat/pins').replace(queryParameters: {
        'broadcaster_id': broadcasterId,
        'moderator_id': moderatorId,
        'message_id': messageId,
      }),
      headers: TwitchAuthService.helixHeaders(accessToken),
    );
    if (response.statusCode != 204) {
      throw TwitchAuthException(
        'Pinning a Twitch chat message failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
  }

  /// Remove the pin from [messageId] in [broadcasterId]'s channel
  /// (Helix 204).
  Future<void> unpinChatMessage({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
    required String messageId,
  }) async {
    final response = await this._client.delete(
      Uri.parse('$kTwitchHelixBase/chat/pins').replace(queryParameters: {
        'broadcaster_id': broadcasterId,
        'moderator_id': moderatorId,
        'message_id': messageId,
      }),
      headers: TwitchAuthService.helixHeaders(accessToken),
    );
    if (response.statusCode != 204) {
      throw TwitchAuthException(
        'Unpinning a Twitch chat message failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
  }

  /// List banned/timed-out users in [broadcasterId]'s channel — Helix
  /// only serves the token user's **own** channel here (mods of other
  /// channels get a 401), so callers must pass the user's own id.
  /// Paginates (100 per page, up to 3 pages) so a large ban list doesn't
  /// silently truncate.
  Future<List<TwitchBannedUser>> getBannedUsers({
    required String accessToken,
    required String broadcasterId,
  }) async {
    final users = <TwitchBannedUser>[];
    String? cursor;
    for (var page = 0; page < 3; page++) {
      final response = await this._client.get(
        Uri.parse('$kTwitchHelixBase/moderation/banned')
            .replace(queryParameters: {
          'broadcaster_id': broadcasterId,
          'first': '100',
          if (cursor != null) 'after': cursor,
        }),
        headers: TwitchAuthService.helixHeaders(accessToken),
      );
      if (response.statusCode != 200) {
        throw TwitchAuthException(
          'Fetching banned Twitch users failed (${response.statusCode})',
          cause: response.body,
          statusCode: response.statusCode,
        );
      }
      final data = json.decode(response.body) as Map<String, Object?>;
      final rows = data['data'] as List<Object?>? ?? const [];
      users.addAll(rows.map(
        (row) => TwitchBannedUser.fromHelixJson(row as Map<String, Object?>),
      ));
      cursor = (data['pagination'] as Map<String, Object?>?)?['cursor']
          as String?;
      if (cursor == null || rows.isEmpty) break;
    }
    return users;
  }

  /// Unban (or lift the timeout of) [userId] in [broadcasterId]'s channel
  /// (Helix 204). Also resolves any pending unban request of that user.
  Future<void> unbanUser({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
    required String userId,
  }) async {
    final response = await this._client.delete(
      Uri.parse('$kTwitchHelixBase/moderation/bans').replace(queryParameters: {
        'broadcaster_id': broadcasterId,
        'moderator_id': moderatorId,
        'user_id': userId,
      }),
      headers: TwitchAuthService.helixHeaders(accessToken),
    );
    if (response.statusCode != 204) {
      throw TwitchAuthException(
        'Unbanning a Twitch user failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
  }

  /// Pending unban requests in [broadcasterId]'s channel (newest first;
  /// 100 per page, up to 3 pages like [getBannedUsers]). Read-only —
  /// approving/denying a request is a separate scope and not exposed.
  Future<List<TwitchUnbanRequest>> getPendingUnbanRequests({
    required String accessToken,
    required String broadcasterId,
    required String moderatorId,
  }) async {
    final requests = <TwitchUnbanRequest>[];
    String? cursor;
    for (var page = 0; page < 3; page++) {
      final response = await this._client.get(
        Uri.parse('$kTwitchHelixBase/moderation/unban_requests')
            .replace(queryParameters: {
          'broadcaster_id': broadcasterId,
          'moderator_id': moderatorId,
          'status': 'pending',
          'first': '100',
          if (cursor != null) 'after': cursor,
        }),
        headers: TwitchAuthService.helixHeaders(accessToken),
      );
      if (response.statusCode != 200) {
        throw TwitchAuthException(
          'Fetching Twitch unban requests failed (${response.statusCode})',
          cause: response.body,
          statusCode: response.statusCode,
        );
      }
      final data = json.decode(response.body) as Map<String, Object?>;
      final rows = data['data'] as List<Object?>? ?? const [];
      requests.addAll(rows.map(
        (row) => TwitchUnbanRequest.fromHelixJson(row as Map<String, Object?>),
      ));
      cursor = (data['pagination'] as Map<String, Object?>?)?['cursor']
          as String?;
      if (cursor == null || rows.isEmpty) break;
    }
    return requests;
  }
}
