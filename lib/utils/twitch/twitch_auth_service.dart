import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/twitch/twitch_device_code.dart';
import 'package:obs_blade/types/classes/twitch/twitch_token.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user.dart';

/// Public client id of the "OBS Blade Chat" Twitch developer application
/// (not a secret — Twitch treats client ids as embeddable).
const String kTwitchClientId = 't3muhu36do5wemeeilzl57v48gwcmh';

/// Chat scopes requested in the device flow — read incoming chat and send
/// messages as the authenticated user.
const List<String> kTwitchChatScopes = <String>[
  'user:read:chat',
  'user:write:chat',
];

const String _kIdBase = 'https://id.twitch.tv/oauth2';

/// Base for Helix calls (user info, chat badges)
const String kTwitchHelixBase = 'https://api.twitch.tv/helix';

/// Terminal auth-flow failure the UI can surface via [message].
class TwitchAuthException implements Exception {
  final String message;
  final Object? cause;

  /// HTTP status of the failing response, when the failure came from an
  /// HTTP call — `null` for local/pre-flight failures. Lets callers tell a
  /// definitive 401/403 (dead credentials) from a transient Twitch 5xx.
  final int? statusCode;

  const TwitchAuthException(this.message, {this.cause, this.statusCode});

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
        cause: response.body,
        statusCode: response.statusCode,
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
          throw TwitchAuthException(
            'Authorization denied on Twitch',
            statusCode: response.statusCode,
          );
        case 'expired_token':
          throw TwitchAuthException(
            'Device code expired',
            statusCode: response.statusCode,
          );
        default:
          throw TwitchAuthException(
            'Token polling failed (${response.statusCode})',
            cause: response.body,
            statusCode: response.statusCode,
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
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    return TwitchToken.fromJson(
      json.decode(response.body) as Map<String, Object?>,
    );
  }

  /// Twitch's validate endpoint — note the required `OAuth` prefix
  /// (not `Bearer`, unlike every other endpoint).
  ///
  /// Tri-state: `true` on 200, `false` only on a definitive 401. Any other
  /// status (e.g. a 5xx during a Twitch incident) throws so callers keep
  /// the stored session instead of destructively logging the user out.
  Future<bool> validate(String accessToken) async {
    final response = await this._client.get(
      Uri.parse('$_kIdBase/validate'),
      headers: {'Authorization': 'OAuth $accessToken'},
    );
    if (response.statusCode == 200) return true;
    if (response.statusCode == 401) return false;
    throw TwitchAuthException(
      'Token validation failed (status ${response.statusCode})',
      cause: response.body,
      statusCode: response.statusCode,
    );
  }

  /// `GET /helix/users` without a filter returns the token's own user.
  Future<TwitchUser> fetchOwnUser(String accessToken) async {
    final response = await this._client.get(
      Uri.parse('$kTwitchHelixBase/users'),
      headers: TwitchAuthService.helixHeaders(accessToken),
    );
    if (response.statusCode != 200) {
      throw TwitchAuthException(
        'Fetching the Twitch user failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
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
