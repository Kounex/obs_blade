import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:provisioning/src/api_client.dart';
import 'package:provisioning/src/asc_jwt.dart';

import 'project.dart';

String _env(String name) {
  final value = Platform.environment[name];
  if (value == null || value.isEmpty) {
    throw StateError('$name is not set (see tool/provisioning/CREDENTIALS.md)');
  }
  return value;
}

/// Read access to App Store Connect, plus the one write fastlane has no
/// action for: submitting the subscriptions with the app version.
class AppStore {
  AppStore._(this._client, this.appId);

  static AppStore connect() => AppStore._(
    HttpApiClient(
      baseUrl: 'https://api.appstoreconnect.apple.com',
      token: buildAscJwt(
        privateKeyPem: File(_env('OBS_BLADE_ASC_KEY_PATH')).readAsStringSync(),
        keyId: _env('OBS_BLADE_ASC_KEY_ID'),
        issuerId: _env('OBS_BLADE_ASC_ISSUER_ID'),
      ),
    ),
    _env('OBS_BLADE_ASC_APP_ID'),
  );

  final HttpApiClient _client;
  final String appId;

  Future<List<Map<String, Object?>>> versions() async => (await _client.get(
    'v1/apps/$appId/appStoreVersions',
    {'limit': '4'},
  )).dataList;

  Future<List<Map<String, Object?>>> builds() async => (await _client.get(
    'v1/builds',
    {'filter[app]': appId, 'sort': '-uploadedDate', 'limit': '4'},
  )).dataList;

  /// Subscriptions of every group (id + attributes).
  Future<List<Map<String, Object?>>> subscriptions() async {
    final res = await _client.get('v1/apps/$appId/subscriptionGroups', {
      'include': 'subscriptions',
    });
    return ((res.json['included'] as List?) ?? const [])
        .whereType<Map<String, Object?>>()
        .toList();
  }

  Future<List<Map<String, Object?>>> inAppPurchases() async =>
      (await _client.get('v1/apps/$appId/inAppPurchasesV2', {
        'limit': '20',
      })).dataList;

  /// Submits one subscription for review (first subscriptions are reviewed
  /// together with the app version submitted next).
  Future<void> submitSubscription(String subscriptionId) async {
    await _client.post('v1/subscriptionSubmissions', {
      'data': {
        'type': 'subscriptionSubmissions',
        'relationships': {
          'subscription': {
            'data': {'type': 'subscriptions', 'id': subscriptionId},
          },
        },
      },
    });
  }
}

/// Read access to Google Play (tracks via a throwaway edit).
class PlayStore {
  PlayStore._(this._client, this._auth);

  static Future<PlayStore> connect() async {
    final creds = ServiceAccountCredentials.fromJson(
      jsonDecode(
        File(
          _env('OBS_BLADE_GOOGLE_APPLICATION_CREDENTIALS'),
        ).readAsStringSync(),
      ),
    );
    final auth = await clientViaServiceAccount(creds, [
      'https://www.googleapis.com/auth/androidpublisher',
    ]);
    return PlayStore._(
      HttpApiClient(
        baseUrl: 'https://androidpublisher.googleapis.com',
        client: auth,
      ),
      auth,
    );
  }

  final HttpApiClient _client;
  final AutoRefreshingAuthClient _auth;

  static const String _app =
      'androidpublisher/v3/applications/${Project.bundleId}';

  /// Every track with its releases. The edit is deleted, never committed.
  Future<List<Map<String, Object?>>> tracks() async {
    final edit = (await _client.post('$_app/edits', {})).json['id'];
    try {
      final res = await _client.get('$_app/edits/$edit/tracks');
      return ((res.json['tracks'] as List?) ?? const [])
          .whereType<Map<String, Object?>>()
          .toList();
    } finally {
      await _client.delete('$_app/edits/$edit');
    }
  }

  void close() => _auth.close();
}
