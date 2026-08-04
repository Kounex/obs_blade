import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/twitch/twitch_device_code.dart';
import 'package:obs_blade/types/classes/twitch/twitch_token.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user.dart';

/// Public client id of the "OBS Blade Chat" Twitch developer application
/// (not a secret — Twitch treats client ids as embeddable).
const String kTwitchClientId = 't3muhu36do5wemeeilzl57v48gwcmh';

/// Phase 1 is read-only — `user:write:chat` gets added in Phase 2.
const List<String> kTwitchChatScopes = <String>['user:read:chat'];

const String _kIdBase = 'https://id.twitch.tv/oauth2';

/// Base for Helix calls (token validation, chat)
const String _kHelixBase = 'https://api.twitch.tv/helix';

/// Terminal auth-flow failure the UI can surface via [message].
class TwitchAuthException implements Exception {
  final String message;
  final Object? cause;

  const TwitchAuthException(this.message, [this.cause]);

  @override
  String toString() =>
      'TwitchAuthException: $message${this.cause != null ? ' (${this.cause})' : ''}';
}

/// Device code grant (RFC 8628) + token lifecycle against Twitch.
///
/// [client] and [sleep] are injectable for tests — no real HTTP or real
/// polling delays in unit tests.
class TwitchAuthService {
  final http.Client _client;
  final Future<void> Function(Duration) _sleep;

  TwitchAuthService({
    http.Client? client,
    Future<void> Function(Duration)? sleep,
  })  : _client = client ?? http.Client(),
        _sleep = sleep ?? Future.delayed;

  static Map<String, String> helixHeaders(String accessToken) => {
        'Authorization': 'Bearer $accessToken',
        'Client-Id': kTwitchClientId,
      };

  /// Kick off the device flow: the user authorizes [TwitchDeviceCode.userCode]
  /// at [TwitchDeviceCode.verificationUri].
  Future<TwitchDeviceCode> requestDeviceCode() async {
    final response = await this._client.post(
      Uri.parse('$_kIdBase/device'),
      body: {
        'client_id': kTwitchClientId,
        'scopes': kTwitchChatScopes.join(' '),
      },
    );
    if (response.statusCode != 200) {
      throw TwitchAuthException(
        'Device code request failed (${response.statusCode})',
        response.body,
      );
    }
    return TwitchDeviceCode.fromJson(
      json.decode(response.body) as Map<String, Object?>,
    );
  }

  /// Poll the token endpoint until authorized, expired, denied or cancelled.
  /// Respects the server-provided interval and backs off on `slow_down`.
  Future<TwitchToken> pollForToken(
    TwitchDeviceCode deviceCode, {
    required FutureOr<void> Function() onPending,
    required bool Function() isCancelled,
  }) async {
    int interval = deviceCode.interval;
    final deadline =
        DateTime.now().add(Duration(seconds: deviceCode.expiresIn));

    while (DateTime.now().isBefore(deadline)) {
      if (isCancelled()) {
        throw const TwitchAuthException('Login cancelled');
      }
      await this._sleep(Duration(seconds: interval));
      await onPending();

      final response = await this._client.post(
        Uri.parse('$_kIdBase/token'),
        body: {
          'client_id': kTwitchClientId,
          'device_code': deviceCode.deviceCode,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
        },
      );

      if (response.statusCode == 200) {
        return TwitchToken.fromJson(
          json.decode(response.body) as Map<String, Object?>,
        );
      }

      switch (TwitchAuthService._errorCode(response.body)) {
        case 'authorization_pending':
          break;
        case 'slow_down':
          interval += 5;
          break;
        case 'access_denied':
          throw const TwitchAuthException('Authorization denied on Twitch');
        case 'expired_token':
          throw const TwitchAuthException('Device code expired');
        default:
          throw TwitchAuthException(
            'Token polling failed (${response.statusCode})',
            response.body,
          );
      }
    }
    throw const TwitchAuthException('Device code expired');
  }

  /// Exchange a refresh token for a new token pair. DCF-issued refresh
  /// tokens do not require a client secret.
  Future<TwitchToken> refreshToken(String refreshToken) async {
    final response = await this._client.post(
      Uri.parse('$_kIdBase/token'),
      body: {
        'client_id': kTwitchClientId,
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
    );
    if (response.statusCode != 200) {
      throw TwitchAuthException(
        'Token refresh failed (${response.statusCode})',
        response.body,
      );
    }
    return TwitchToken.fromJson(
      json.decode(response.body) as Map<String, Object?>,
    );
  }

  /// Twitch's validate endpoint — note the required `OAuth` prefix
  /// (not `Bearer`, unlike every other endpoint).
  Future<bool> validate(String accessToken) async {
    final response = await this._client.get(
      Uri.parse('$_kIdBase/validate'),
      headers: {'Authorization': 'OAuth $accessToken'},
    );
    return response.statusCode == 200;
  }

  /// `GET /helix/users` without a filter returns the token's own user.
  Future<TwitchUser> fetchOwnUser(String accessToken) async {
    final response = await this._client.get(
      Uri.parse('$_kHelixBase/users'),
      headers: TwitchAuthService.helixHeaders(accessToken),
    );
    if (response.statusCode != 200) {
      throw TwitchAuthException(
        'Fetching the Twitch user failed (${response.statusCode})',
        response.body,
      );
    }
    final data = (json.decode(response.body) as Map<String, dynamic>)['data'];
    if (data is! List || data.isEmpty) {
      throw const TwitchAuthException(
          'Fetching the Twitch user returned no data');
    }
    return TwitchUser.fromJson(data.first as Map<String, Object?>);
  }

  /// Revoke a token (logout hygiene). Best effort — must never block a
  /// local logout because the network is down.
  Future<void> revoke(String accessToken) async {
    try {
      await this._client.post(
        Uri.parse('$_kIdBase/revoke'),
        body: {'client_id': kTwitchClientId, 'token': accessToken},
      );
    } catch (_) {
      // best effort
    }
  }

  /// RFC 8628 puts the code in `error`; Twitch historically uses `message`.
  static String? _errorCode(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        return (decoded['error'] ?? decoded['message']) as String?;
      }
    } catch (_) {
      // non-JSON body
    }
    return null;
  }
}
