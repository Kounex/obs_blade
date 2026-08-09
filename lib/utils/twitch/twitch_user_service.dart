import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/twitch/twitch_user.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';

/// Self subscription to the selected channel — tier label + tenure months.
class TwitchSelfSubscription {
  final String tier;
  final int months;

  const TwitchSelfSubscription({
    required this.tier,
    required this.months,
  });
}

/// Helix user lookups for the native chat user card — identity, follow
/// dates, and self sub facts. Every call returns null on 4xx / missing
/// data so the sheet can omit rows without surfacing errors.
///
/// [client] is injectable for tests — no real HTTP in unit tests.
class TwitchUserService {
  final http.Client _client;

  TwitchUserService({http.Client? client})
      : _client = client ?? http.Client();

  /// `GET /helix/users?id=` — avatar, login, display name, created_at.
  Future<TwitchUser?> fetchUser({
    required String accessToken,
    required String userId,
  }) async {
    final response = await this._client.get(
      Uri.parse('$kTwitchHelixBase/users').replace(
        queryParameters: {'id': userId},
      ),
      headers: TwitchAuthService.helixHeaders(accessToken),
    );
    if (response.statusCode != 200) return null;
    final data = (json.decode(response.body) as Map<String, dynamic>)['data'];
    if (data is! List || data.isEmpty) return null;
    return TwitchUser.fromJson(data.first as Map<String, Object?>);
  }

  /// When [userId] follows [broadcasterId] — `moderator:read:followers`.
  Future<DateTime?> followerSince({
    required String accessToken,
    required String broadcasterId,
    required String userId,
  }) async {
    final response = await this._client.get(
      Uri.parse('$kTwitchHelixBase/channels/followers').replace(
        queryParameters: {
          'broadcaster_id': broadcasterId,
          'user_id': userId,
        },
      ),
      headers: TwitchAuthService.helixHeaders(accessToken),
    );
    return this._followedAtFromResponse(response);
  }

  /// When the authenticated user ([userId]) follows [broadcasterId] —
  /// `user:read:follows`.
  Future<DateTime?> selfFollowedAt({
    required String accessToken,
    required String userId,
    required String broadcasterId,
  }) async {
    final response = await this._client.get(
      Uri.parse('$kTwitchHelixBase/channels/followed').replace(
        queryParameters: {
          'user_id': userId,
          'broadcaster_id': broadcasterId,
        },
      ),
      headers: TwitchAuthService.helixHeaders(accessToken),
    );
    return this._followedAtFromResponse(response);
  }

  /// Whether the token user is subscribed to [broadcasterId] —
  /// `user:read:subscriptions`.
  Future<TwitchSelfSubscription?> selfSubscription({
    required String accessToken,
    required String broadcasterId,
  }) async {
    final response = await this._client.get(
      Uri.parse('$kTwitchHelixBase/subscriptions/user').replace(
        queryParameters: {'broadcaster_id': broadcasterId},
      ),
      headers: TwitchAuthService.helixHeaders(accessToken),
    );
    if (response.statusCode != 200) return null;
    final data = (json.decode(response.body) as Map<String, dynamic>)['data'];
    if (data is! List || data.isEmpty) return null;
    final entry = data.first as Map<String, dynamic>;
    final tier = entry['tier'] as String?;
    if (tier == null) return null;
    final months = (entry['cumulative_months'] as num?)?.toInt() ?? 0;
    return TwitchSelfSubscription(tier: tier, months: months);
  }

  DateTime? _followedAtFromResponse(http.Response response) {
    if (response.statusCode != 200) return null;
    final data = (json.decode(response.body) as Map<String, dynamic>)['data'];
    if (data is! List || data.isEmpty) return null;
    final followedAt = (data.first as Map<String, dynamic>)['followed_at'];
    if (followedAt is! String) return null;
    return DateTime.tryParse(followedAt);
  }
}
