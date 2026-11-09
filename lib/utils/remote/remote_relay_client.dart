import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../renewing_http_client.dart';

/// OBS Blade's remote relay (`tool/remote_relay/`, Pro): connects the app
/// to the bridge next to OBS (the OBS Blade Remote plugin or standalone
/// app) from anywhere. Protocol: `tool/remote_relay/README.md`.
const String kRemoteRelayUrl = String.fromEnvironment(
  'REMOTE_RELAY_URL',
  defaultValue: 'https://relay.obs-blade.com',
);

/// Vendor name the OBS plugin registers in obs-websocket, and the
/// CustomEvent key the standalone listens for (`core/` of Kounex/obs-blade-remote).
const String kRemoteBridgeVendor = 'obs-blade-bridge';
const String kRemotePairEventKey = 'obs-blade-pair';

/// CustomEvent key of the bridge's answer: `{code, bridge_key}` - its
/// end-to-end key, through OBS only.
const String kRemotePairAckEventKey = 'obs-blade-pair-ack';

class RemoteRelayException implements Exception {
  final int? statusCode;

  /// The relay's `error` string (`pro_required`, `verify_unavailable`,
  /// `rate_limited`, `unknown_pairing`, `unpaired`, ...), null for
  /// network failures
  final String? error;

  const RemoteRelayException({this.statusCode, this.error});

  bool get isNetwork => this.statusCode == null;
  bool get isProRequired => this.error == 'pro_required';
  bool get isUnpaired => this.statusCode == 401;

  @override
  String toString() => 'RemoteRelayException($statusCode, $error)';
}

class RemotePairingTicket {
  /// Secret: collects the pairing's app token. Never logged, never in a URL.
  final String pairingId;
  final String code;
  final Duration expiresIn;

  const RemotePairingTicket({
    required this.pairingId,
    required this.code,
    required this.expiresIn,
  });
}

class RemotePairing {
  final String deviceId;
  final String appToken;
  final String bridgeId;
  final String bridgeName;

  /// `plugin` or `standalone`
  final String bridgeKind;

  const RemotePairing({
    required this.deviceId,
    required this.appToken,
    required this.bridgeId,
    required this.bridgeName,
    required this.bridgeKind,
  });
}

class RemoteDevice {
  final String id;
  final String name;
  final String platform;
  final DateTime lastUsed;
  final bool connected;
  final bool isThisDevice;

  const RemoteDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.lastUsed,
    required this.connected,
    required this.isThisDevice,
  });
}

class RemoteBridgeInfo {
  final String id;
  final String name;
  final String kind;
  final String version;
  final bool online;
  final DateTime? lastSeen;

  /// `running`, `closed`, `crashed`, `ws_off`, `auth_failed` or empty
  final String obsState;
  final bool updateRequired;
  final List<RemoteDevice> devices;

  const RemoteBridgeInfo({
    required this.id,
    required this.name,
    required this.kind,
    required this.version,
    required this.online,
    required this.lastSeen,
    required this.obsState,
    required this.updateRequired,
    required this.devices,
  });

  bool get isStandalone => this.kind == 'standalone';
}

DateTime? _epoch(Object? seconds) => seconds is num && seconds > 0
    ? DateTime.fromMillisecondsSinceEpoch((seconds * 1000).round())
    : null;

class RemoteRelayClient {
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;
  final String _baseUrl;

  RemoteRelayClient({http.Client? client, String baseUrl = kRemoteRelayUrl})
    : _client = client ?? RenewingHttpClient(),
      _baseUrl = baseUrl;

  /// `wss://…/v1/app?bridge=<id>` - the app's obs-websocket session.
  Uri appSocketUri(String bridgeId) {
    final base = Uri.parse(this._baseUrl);
    return base.replace(
      scheme: base.scheme == 'http' ? 'ws' : 'wss',
      path: '/v1/app',
      queryParameters: {'bridge': bridgeId},
    );
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
    Set<int> ok = const {200},
  }) async {
    final request = http.Request(method, Uri.parse('${this._baseUrl}$path'));
    request.headers['Content-Type'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) request.body = json.encode(body);
    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await this._client.send(request).timeout(_timeout),
      ).timeout(_timeout);
    } catch (_) {
      throw const RemoteRelayException();
    }
    Object? decoded;
    try {
      decoded = response.body.isEmpty ? null : json.decode(response.body);
    } on FormatException {
      decoded = null;
    }
    final map = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    if (!ok.contains(response.statusCode)) {
      throw RemoteRelayException(
        statusCode: response.statusCode,
        error: map['error'] as String?,
      );
    }
    return map;
  }

  /// Step 1 of pairing (Pro checked by the relay).
  Future<RemotePairingTicket> createPairing({
    required String appUserId,
    required String deviceName,
    required String platform,
  }) async {
    final body = await this._send(
      'POST',
      '/v1/pairings',
      body: {
        'app_user_id': appUserId,
        'device_name': deviceName,
        'platform': platform,
      },
      ok: const {201},
    );
    final id = body['pairing_id'];
    final code = body['code'];
    if (id is! String || code is! String) {
      throw const RemoteRelayException(error: 'bad_answer');
    }
    return RemotePairingTicket(
      pairingId: id,
      code: code,
      expiresIn: Duration(
        seconds: (body['expires_in'] as num?)?.toInt() ?? 120,
      ),
    );
  }

  /// Step 4: null while no bridge redeemed the code yet. Throws
  /// `unknown_pairing` (404) once it expired - or after it was collected
  /// (the app token is handed out once).
  Future<RemotePairing?> collectPairing(String pairingId) async {
    final body = await this._send(
      'POST',
      '/v1/pairings/collect',
      body: {'pairing_id': pairingId},
    );
    if (body['state'] != 'paired') return null;
    final bridge = body['bridge'];
    if (bridge is! Map ||
        body['device_id'] is! String ||
        body['app_token'] is! String) {
      throw const RemoteRelayException(error: 'bad_answer');
    }
    return RemotePairing(
      deviceId: body['device_id'] as String,
      appToken: body['app_token'] as String,
      bridgeId: '${bridge['id']}',
      bridgeName: (bridge['name'] as String?) ?? '',
      bridgeKind: (bridge['kind'] as String?) ?? '',
    );
  }

  Future<RemoteBridgeInfo> bridgeInfo(String bridgeId, String appToken) async {
    final body = await this._send(
      'GET',
      '/v1/bridges/${Uri.encodeComponent(bridgeId)}',
      token: appToken,
    );
    final devices = (body['devices'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (d) => RemoteDevice(
            id: '${d['id']}',
            name: (d['name'] as String?) ?? '',
            platform: (d['platform'] as String?) ?? '',
            lastUsed:
                _epoch(d['last_used']) ??
                DateTime.fromMillisecondsSinceEpoch(0),
            connected: d['connected'] == true,
            isThisDevice: d['self'] == true,
          ),
        )
        .toList();
    return RemoteBridgeInfo(
      id: '${body['id']}',
      name: (body['name'] as String?) ?? '',
      kind: (body['kind'] as String?) ?? '',
      version: (body['version'] as String?) ?? '',
      online: body['online'] == true,
      lastSeen: _epoch(body['last_seen']),
      obsState: (body['obs'] as String?) ?? '',
      updateRequired: body['update_required'] == true,
      devices: devices,
    );
  }

  /// Renames any device of the same bridge (the name the PC lists it
  /// under), this one included.
  Future<void> renameDevice(String deviceId, String name, String appToken) =>
      this._send(
        'PATCH',
        '/v1/devices/${Uri.encodeComponent(deviceId)}',
        body: {'name': name},
        token: appToken,
        ok: const {204},
      );

  /// Removes any device of the same bridge, this one included.
  Future<void> removeDevice(String deviceId, String appToken) => this._send(
    'DELETE',
    '/v1/devices/${Uri.encodeComponent(deviceId)}',
    token: appToken,
    ok: const {204},
  );

  /// Standalone bridges only (a plugin ends with OBS).
  Future<void> startObs(String bridgeId, String appToken) => this._send(
    'POST',
    '/v1/bridges/${Uri.encodeComponent(bridgeId)}/start-obs',
    token: appToken,
    ok: const {202},
  );
}
