import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/twitch/twitch_device_code.dart';
import 'package:obs_blade/types/classes/twitch/twitch_token.dart';

/// Public client id of the "OBS Blade Chat" Twitch developer application
/// (not a secret — Twitch treats client ids as embeddable).
const String kTwitchClientId = 't3muhu36do5wemeeilzl57v48gwcmh';

/// Phase 1 is read-only — `user:write:chat` gets added in Phase 2.
const List<String> kTwitchChatScopes = <String>['user:read:chat'];

const String _kIdBase = 'https://id.twitch.tv/oauth2';

/// Base for Helix calls (token validation, chat) — used from Task 3 on.
// ignore: unused_element
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
