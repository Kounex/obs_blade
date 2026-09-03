import 'dart:async';
import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/youtube/youtube_device_code.dart';
import 'package:obs_blade/types/classes/youtube/youtube_token.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

/// App-owned Google OAuth client id for the YouTube device flow. Empty for
/// now — no app-owned client exists yet, so the BYO client id
/// ([SettingsKeys.YouTubeOAuthClientId]) is the only working path. See
/// docs/youtube-native-chat-audit.md.
const String kYouTubeOAuthClientId = '';

/// App-owned Google OAuth client secret paired with
/// [kYouTubeOAuthClientId]. Google's device flow for "TVs and Limited
/// Input" clients requires a client secret on token polling/refresh —
/// empty until an app-owned client exists, BYO via
/// [SettingsKeys.YouTubeOAuthClientSecret]. See
/// docs/youtube-native-chat-audit.md.
const String kYouTubeOAuthClientSecret = '';

/// App-owned YouTube Data API key for native chat reads. Empty for now —
/// see docs/youtube-native-chat-audit.md; the BYO key
/// ([SettingsKeys.YouTubeApiKey]) is the only working path.
const String kYouTubeApiKey = '';

/// OAuth scope requested in the device flow — read, send and moderate
/// live chat (the device flow allows `youtube` but not `force-ssl`).
const List<String> kYouTubeChatScopes = <String>[
  'https://www.googleapis.com/auth/youtube',
];

const String _kDeviceCodeUrl = 'https://oauth2.googleapis.com/device/code';
const String _kTokenUrl = 'https://oauth2.googleapis.com/token';
const String _kRevokeUrl = 'https://oauth2.googleapis.com/revoke';

/// Terminal auth-flow failure the UI can surface via [message].
class YouTubeAuthException implements Exception {
  final String message;
  final Object? cause;

  /// HTTP status of the failing response, when the failure came from an
  /// HTTP call — `null` for local/pre-flight failures. Lets callers tell a
  /// definitive 401/403 (dead credentials) from a transient Google 5xx.
  final int? statusCode;

  const YouTubeAuthException(this.message, {this.cause, this.statusCode});

  @override
  String toString() =>
      'YouTubeAuthException: $message${this.cause != null ? ' (${this.cause})' : ''}';
}

/// Google OAuth device flow (RFC 8628-style:
/// `oauth2.googleapis.com/device/code` + token polling) + token
/// lifecycle. Mirrors [TwitchAuthService]'s shape.
///
/// [client] and [sleep] are injectable for tests — no real HTTP or real
/// polling delays in unit tests.
class YouTubeAuthService {
  final http.Client _client;
  final Future<void> Function(Duration) _sleep;

  YouTubeAuthService({
    http.Client? client,
    Future<void> Function(Duration)? sleep,
  }) : _client = client ?? http.Client(),
       _sleep = sleep ?? Future.delayed;

  /// Reads a non-empty String setting; `null` when the settings box isn't
  /// open (unit tests without Hive) or the key is missing/empty.
  static String? _settingsValue(SettingsKeys key) {
    if (!Hive.isBoxOpen(HiveKeys.Settings.name)) return null;
    final value = Hive.box(HiveKeys.Settings.name).get(key.name);
    return value is String && value.isNotEmpty ? value : null;
  }

  /// OAuth client id resolution: the user's own client
  /// ([SettingsKeys.YouTubeOAuthClientId]) wins over the app-owned
  /// [kYouTubeOAuthClientId] constant.
  String resolveClientId() =>
      YouTubeAuthService._settingsValue(SettingsKeys.YouTubeOAuthClientId) ??
      kYouTubeOAuthClientId;

  /// OAuth client secret resolution — `null` when none is configured
  /// (public/installed-app clients don't have one). The user's own secret
  /// ([SettingsKeys.YouTubeOAuthClientSecret]) wins over the app-owned
  /// [kYouTubeOAuthClientSecret] constant.
  String? resolveClientSecret() {
    final configured =
        YouTubeAuthService._settingsValue(
          SettingsKeys.YouTubeOAuthClientSecret,
        ) ??
        kYouTubeOAuthClientSecret;
    return configured.isNotEmpty ? configured : null;
  }

  /// Kick off the device flow: the user authorizes
  /// [YouTubeDeviceCode.userCode] at [YouTubeDeviceCode.verificationUrl].
  Future<YouTubeDeviceCode> requestDeviceCode() async {
    final response = await this._client.post(
      Uri.parse(_kDeviceCodeUrl),
      body: {
        'client_id': this.resolveClientId(),
        'client_secret': ?this.resolveClientSecret(),
        'scope': kYouTubeChatScopes.join(' '),
      },
    );
    if (response.statusCode != 200) {
      throw YouTubeAuthException(
        'Device code request failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    return YouTubeDeviceCode.fromJson(
      json.decode(response.body) as Map<String, Object?>,
    );
  }

  /// Poll the token endpoint until authorized, expired, denied or cancelled.
  /// Respects the server-provided interval and backs off on `slow_down`.
  Future<YouTubeToken> pollForToken(
    YouTubeDeviceCode deviceCode, {
    required FutureOr<void> Function() onPending,
    required bool Function() isCancelled,
  }) async {
    int interval = deviceCode.interval;
    final deadline = DateTime.now().add(
      Duration(seconds: deviceCode.expiresIn),
    );

    while (DateTime.now().isBefore(deadline)) {
      if (isCancelled()) {
        throw const YouTubeAuthException('Login cancelled');
      }
      await this._sleep(Duration(seconds: interval));
      await onPending();

      final response = await this._client.post(
        Uri.parse(_kTokenUrl),
        body: {
          'client_id': this.resolveClientId(),
          'client_secret': ?this.resolveClientSecret(),
          'device_code': deviceCode.deviceCode,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
        },
      );

      if (response.statusCode == 200) {
        return YouTubeToken.fromJson(
          json.decode(response.body) as Map<String, Object?>,
        );
      }

      switch (YouTubeAuthService._errorCode(response.body)) {
        case 'authorization_pending':
          break;
        case 'slow_down':
          interval += 5;
          break;
        case 'access_denied':
          throw YouTubeAuthException(
            'Authorization denied on Google',
            statusCode: response.statusCode,
          );
        case 'expired_token':
          throw YouTubeAuthException(
            'Device code expired',
            statusCode: response.statusCode,
          );
        default:
          throw YouTubeAuthException(
            'Token polling failed (${response.statusCode})',
            cause: response.body,
            statusCode: response.statusCode,
          );
      }
    }
    throw const YouTubeAuthException('Device code expired');
  }

  /// Exchange a refresh token for a new token pair. Google only returns a
  /// new refresh token when access was originally granted with
  /// `access_type=offline` re-consent — keep the stored one when absent.
  Future<YouTubeToken> refreshToken(String refreshToken) async {
    final response = await this._client.post(
      Uri.parse(_kTokenUrl),
      body: {
        'client_id': this.resolveClientId(),
        'client_secret': ?this.resolveClientSecret(),
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
    );
    if (response.statusCode != 200) {
      throw YouTubeAuthException(
        'Token refresh failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    return YouTubeToken.fromJson(
      json.decode(response.body) as Map<String, Object?>,
    );
  }

  /// Revoke a token (logout hygiene). Google expects the token as a query
  /// parameter. Best effort — must never block a local logout because the
  /// network is down.
  Future<void> revoke(String accessToken) async {
    try {
      await this._client.post(
        Uri.parse(
          '$_kRevokeUrl?token=${Uri.encodeQueryComponent(accessToken)}',
        ),
      );
    } catch (_) {
      // best effort
    }
  }

  /// RFC 8628 puts the code in `error`.
  static String? _errorCode(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded['error'] as String?;
      }
    } catch (_) {
      // non-JSON body
    }
    return null;
  }
}
