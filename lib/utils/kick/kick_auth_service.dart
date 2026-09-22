import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/kick/kick_token.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

/// App-owned Kick OAuth client id. Public — it is in the authorize URL.
/// The matching secret is not in this repo; token exchange goes to
/// [kKickTokenProxyUrl] unless [kKickOAuthClientSecret] is also compiled in.
const String kKickOAuthClientId = String.fromEnvironment(
  'KICK_OAUTH_CLIENT_ID',
  defaultValue: '01M356MAT9Z4YB9HBESV9ZQN6S',
);

/// Optional override. Leave empty so the phone uses [kKickTokenProxyUrl]
/// and the secret stays on that host. Compiling a secret in sends the
/// exchange straight to Kick and puts the secret in the binary.
const String kKickOAuthClientSecret = String.fromEnvironment(
  'KICK_OAUTH_CLIENT_SECRET',
);

/// OAuth scopes requested in the authorize URL — one bundle: identity
/// read, chat send (incl. replies), ban + message-manage moderation.
const List<String> kKickChatScopes = <String>[
  'user:read',
  'chat:write',
  'moderation:ban',
  'moderation:chat_message:manage',
];

/// Redirect registered on the OBS Blade Kick app. Kick sends the browser
/// here after consent; the exchange host consumes the code and the app
/// picks up the tokens. A bring-your-own app that still uses the paste
/// flow registers `https://localhost/kick-callback` instead.
const String kKickOAuthRedirectUri =
    'https://kick-auth.kounex.com/oauth/callback';

const String _kAuthorizeUrl = 'https://id.kick.com/oauth/authorize';
const String _kTokenUrl = 'https://id.kick.com/oauth/token';

/// Token exchange for the app-owned Kick client. The secret stays on this
/// host; the phone posts the code and PKCE verifier here and the host adds
/// the secret. Used only when [kKickOAuthClientId] is compiled in and
/// [kKickOAuthClientSecret] is not.
const String kKickTokenProxyUrl = String.fromEnvironment(
  'KICK_TOKEN_PROXY_URL',
  defaultValue: 'https://kick-auth.kounex.com/oauth/token',
);
const String _kRevokeUrl = 'https://id.kick.com/oauth/revoke';
const String _kUsersUrl = 'https://api.kick.com/public/v1/users';

/// Terminal auth-flow failure the UI can surface via [message].
class KickAuthException implements Exception {
  final String message;
  final Object? cause;

  /// HTTP status of the failing response, when the failure came from an
  /// HTTP call — `null` for local/pre-flight failures (bad paste, state
  /// mismatch). Lets callers tell a definitive 400/401/403 (dead
  /// credentials) from a transient 5xx.
  final int? statusCode;

  const KickAuthException(this.message, {this.cause, this.statusCode});

  @override
  String toString() =>
      'KickAuthException: $message${this.cause != null ? ' (${this.cause})' : ''}';
}

/// A pending PKCE login — the verifier/state pair the pasted redirect URL
/// is validated against. Held by the caller between "open browser" and
/// "paste redirect URL"; never persisted.
class KickPkceSession {
  /// RFC 7636 code verifier (43–128 url-safe chars; 64 random bytes).
  final String verifier;

  /// Anti-CSRF state echoed back on the redirect.
  final String state;

  /// `base64url(sha256(verifier))` without padding.
  final String codeChallenge;

  /// Proves the polling phone is the one that started this login. Never
  /// sent to Kick and never present on the redirect URL.
  final String pollToken;

  const KickPkceSession({
    required this.verifier,
    required this.state,
    required this.codeChallenge,
    this.pollToken = '',
  });
}

/// Identity of the token's Kick account (`GET /public/v1/users`, no
/// params = own user). [userId] doubles as the echo-dedup marker: own
/// messages come back over Pusher with `sender.id == userId`.
class KickUserIdentity {
  final int userId;
  final String? name;
  final String? profilePicture;

  const KickUserIdentity({
    required this.userId,
    this.name,
    this.profilePicture,
  });
}

/// Kick OAuth 2.1 authorization-code flow with PKCE (S256 mandatory) at
/// `id.kick.com` + token lifecycle. Mirrors [YouTubeAuthService]'s shape,
/// but the flow differs: Kick has no device flow, so the user opens the
/// authorize URL in a browser and pastes the redirect URL back (see
/// [parseRedirectCode]).
///
/// [client] and [random] are injectable for tests — no real HTTP and
/// deterministic PKCE material in unit tests.
class KickAuthService {
  final http.Client _client;
  final Random _random;

  /// Single-flight guard for token refresh: Kick rotates BOTH tokens on
  /// refresh, so two concurrent refreshes with the same refresh token
  /// would kill each other — concurrent callers share one in-flight
  /// refresh instead.
  Future<KickToken>? _refreshInFlight;

  KickAuthService({http.Client? client, Random? random})
    : _client = client ?? http.Client(),
      _random = random ?? Random.secure();

  /// Reads a non-empty String setting; `null` when the settings box isn't
  /// open (unit tests without Hive) or the key is missing/empty.
  static String? _settingsValue(SettingsKeys key) {
    if (!Hive.isBoxOpen(HiveKeys.Settings.name)) return null;
    final value = Hive.box(HiveKeys.Settings.name).get(key.name);
    return value is String && value.isNotEmpty ? value : null;
  }

  /// OAuth client id. A compiled-in app client
  /// ([kKickOAuthClientId]) wins. Otherwise the bring-your-own setting.
  String resolveClientId() {
    if (kKickOAuthClientId.isNotEmpty) return kKickOAuthClientId;
    return KickAuthService._settingsValue(SettingsKeys.KickOAuthClientId) ?? '';
  }

  /// OAuth client secret — `null` when none is configured.
  ///
  /// An app-owned client id means the secret lives on
  /// [kKickTokenProxyUrl], so a bring-your-own secret in settings is
  /// ignored. Otherwise the settings secret is used for a direct call.
  String? resolveClientSecret() {
    if (kKickOAuthClientId.isNotEmpty) {
      return kKickOAuthClientSecret.isNotEmpty ? kKickOAuthClientSecret : null;
    }
    return KickAuthService._settingsValue(SettingsKeys.KickOAuthClientSecret);
  }

  /// Kick's token URL when this install holds a secret. The proxy when
  /// the app client id is compiled in and the secret is not.
  Uri _tokenEndpoint() {
    if (kKickOAuthClientId.isNotEmpty && kKickOAuthClientSecret.isEmpty) {
      return Uri.parse(kKickTokenProxyUrl);
    }
    return Uri.parse(_kTokenUrl);
  }

  String _randomBase64Url(int byteCount) => base64Url
      .encode(List<int>.generate(byteCount, (_) => this._random.nextInt(256)))
      .replaceAll('=', '');

  /// Step 1 of the login: a fresh PKCE session (verifier, state, S256
  /// challenge).
  KickPkceSession beginSession() {
    final verifier = this._randomBase64Url(64);
    final challenge = base64Url
        .encode(sha256.convert(ascii.encode(verifier)).bytes)
        .replaceAll('=', '');
    return KickPkceSession(
      verifier: verifier,
      state: this._randomBase64Url(32),
      codeChallenge: challenge,
      pollToken: this._randomBase64Url(32),
    );
  }

  Uri _proxyUri(String path) {
    final base = Uri.parse(kKickTokenProxyUrl);
    return base.replace(path: path);
  }

  /// Tell the exchange host which PKCE verifier belongs to [session],
  /// before the browser is opened. The host exchanges the code when Kick
  /// redirects the browser, and only hands the tokens to this poll token.
  Future<void> registerProxyLogin(KickPkceSession session) async {
    final response = await this._client.post(
      this._proxyUri('/oauth/session'),
      headers: const {'Content-Type': 'application/json'},
      body: json.encode(<String, String>{
        'state': session.state,
        'code_verifier': session.verifier,
        'poll_token': session.pollToken,
      }),
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw KickAuthException(
        'Could not start the Kick login (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
  }

  /// Null while the browser has not returned yet. The token once the
  /// exchange host has finished. Throws if Kick denied the login.
  Future<KickToken?> pollProxyLogin(KickPkceSession session) async {
    final response = await this._client.post(
      this._proxyUri('/oauth/session/result'),
      headers: const {'Content-Type': 'application/json'},
      body: json.encode(<String, String>{
        'state': session.state,
        'poll_token': session.pollToken,
      }),
    );
    if (response.statusCode == 202) return null;
    if (response.statusCode != 200) {
      throw KickAuthException(
        'Kick login failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    return KickToken.fromJson(
      (json.decode(response.body) as Map).cast<String, Object?>(),
    );
  }

  /// The authorize URL the user opens in the browser (url_launcher) —
  /// carries the PKCE challenge and anti-CSRF state of [session].
  Uri authorizeUrl(KickPkceSession session) =>
      Uri.parse(_kAuthorizeUrl).replace(
        queryParameters: <String, String>{
          'response_type': 'code',
          'client_id': this.resolveClientId(),
          'redirect_uri': kKickOAuthRedirectUri,
          'state': session.state,
          'scope': kKickChatScopes.join(' '),
          'code_challenge': session.codeChallenge,
          'code_challenge_method': 'S256',
        },
      );

  /// Step 2: parse the pasted redirect URL into the authorization code.
  /// Rejects (throws [KickAuthException]) on an unparsable URL, a
  /// `?error=` denial, a state mismatch (CSRF / stale paste) or a missing
  /// code.
  String parseRedirectCode(String pastedUrl, {required String expectedState}) {
    final uri = Uri.tryParse(pastedUrl.trim());
    if (uri == null || !uri.hasScheme) {
      throw const KickAuthException(
        'Not a valid URL — paste the full address from the browser',
      );
    }
    final error = uri.queryParameters['error'];
    if (error != null) {
      throw KickAuthException('Kick denied the authorization ($error)');
    }
    final state = uri.queryParameters['state'];
    if (state == null || state != expectedState) {
      throw const KickAuthException(
        'State mismatch — paste the URL of the login you just started',
      );
    }
    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw const KickAuthException('No authorization code in this URL');
    }
    return code;
  }

  /// `authorization_code` exchange at the token endpoint.
  Future<KickToken> exchangeCode({
    required String code,
    required KickPkceSession session,
  }) async {
    final response = await this._client.post(
      this._tokenEndpoint(),
      body: <String, String>{
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': this.resolveClientId(),
        'client_secret': ?this.resolveClientSecret(),
        'redirect_uri': kKickOAuthRedirectUri,
        'code_verifier': session.verifier,
      },
    );
    if (response.statusCode != 200) {
      throw KickAuthException(
        'Token exchange failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    return KickToken.fromJson(
      (json.decode(response.body) as Map).cast<String, Object?>(),
    );
  }

  /// Exchange a refresh token for a new token pair. Kick rotates BOTH
  /// tokens on refresh — callers must persist both. Single-flight: a
  /// concurrent refresh shares the in-flight one (see [_refreshInFlight]).
  Future<KickToken> refreshToken(String refreshToken) {
    final inFlight = this._refreshInFlight;
    if (inFlight != null) return inFlight;
    final future = this._refresh(refreshToken);
    this._refreshInFlight = future;
    return future.whenComplete(() {
      if (identical(this._refreshInFlight, future)) {
        this._refreshInFlight = null;
      }
    });
  }

  Future<KickToken> _refresh(String refreshToken) async {
    final response = await this._client.post(
      this._tokenEndpoint(),
      body: <String, String>{
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': this.resolveClientId(),
        'client_secret': ?this.resolveClientSecret(),
      },
    );
    if (response.statusCode != 200) {
      throw KickAuthException(
        'Token refresh failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    return KickToken.fromJson(
      (json.decode(response.body) as Map).cast<String, Object?>(),
    );
  }

  /// Identity of the token's account (display + echo-dedup marker).
  /// Mirrors [YouTubeAuthService.fetchOwnChannelTitle].
  Future<KickUserIdentity?> fetchOwnUser(String accessToken) async {
    final response = await this._client.get(
      Uri.parse(_kUsersUrl),
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      throw KickAuthException(
        'Fetching the Kick user failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    final data = (json.decode(response.body) as Map<String, dynamic>)['data'];
    if (data is! List || data.isEmpty) return null;
    final user = data.first;
    if (user is! Map<String, dynamic>) return null;
    final userId = user['user_id'];
    if (userId is! int) return null;
    return KickUserIdentity(
      userId: userId,
      name: user['name'] as String?,
      profilePicture: user['profile_picture'] as String?,
    );
  }

  /// Revoke a token (logout hygiene). Best effort — must never block a
  /// local logout because the network is down.
  Future<void> revoke(String token, {String tokenHint = 'access_token'}) async {
    try {
      await this._client.post(
        Uri.parse(
          '$_kRevokeUrl?token=${Uri.encodeQueryComponent(token)}&token_hint_type=$tokenHint',
        ),
      );
    } catch (_) {
      // best effort
    }
  }
}
