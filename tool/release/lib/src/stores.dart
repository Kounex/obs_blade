import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
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

/// Read access to App Store Connect, plus the writes fastlane has no action
/// for: submitting the subscriptions with the app version, and App Previews.
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
  // ------------------------------------------------------- app previews

  /// The iOS App Store version [versionString] (null when there is none).
  Future<Map<String, Object?>?> version(String versionString) async {
    final list = (await _client.get('v1/apps/$appId/appStoreVersions', {
      'filter[versionString]': versionString,
      'filter[platform]': 'IOS',
    })).dataList;
    return list.isEmpty ? null : list.first;
  }

  Future<String?> localizationId(String versionId, String locale) async {
    final list = (await _client.get(
      'v1/appStoreVersions/$versionId/appStoreVersionLocalizations',
    )).dataList;
    for (final l in list) {
      if ((l['attributes'] as Map)['locale'] == locale) return '${l['id']}';
    }
    return null;
  }

  /// The preview set of [previewType] (e.g. `IPHONE_67`), null when missing.
  Future<String?> previewSetId(
    String localizationId,
    String previewType,
  ) async {
    final list = (await _client.get(
      'v1/appStoreVersionLocalizations/$localizationId/appPreviewSets',
    )).dataList;
    for (final s in list) {
      if ((s['attributes'] as Map)['previewType'] == previewType) {
        return '${s['id']}';
      }
    }
    return null;
  }

  Future<String> createPreviewSet(
    String localizationId,
    String previewType,
  ) async =>
      '${(await _client.post('v1/appPreviewSets', {
        'data': {
          'type': 'appPreviewSets',
          'attributes': {'previewType': previewType},
          'relationships': {
            'appStoreVersionLocalization': {
              'data': {'type': 'appStoreVersionLocalizations', 'id': localizationId},
            },
          },
        },
      })).dataObject!['id']}';

  Future<List<Map<String, Object?>>> previews(String setId) async =>
      (await _client.get('v1/appPreviewSets/$setId/appPreviews')).dataList;

  Future<void> deletePreview(String id) async =>
      _client.delete('v1/appPreviews/$id');

  /// Reserves, uploads and commits [file] into the set, then waits for
  /// Apple's processing. Returns the final delivery state (`COMPLETE`,
  /// `FAILED`, or the last one seen when [timeout] ran out).
  Future<({String id, String state, List<Object?> errors})> uploadPreview(
    String setId,
    File file, {
    required String posterTimeCode,
    Duration timeout = const Duration(minutes: 20),
  }) async {
    final bytes = file.readAsBytesSync();
    final reserved = (await _client.post('v1/appPreviews', {
      'data': {
        'type': 'appPreviews',
        'attributes': {
          'fileName': file.uri.pathSegments.last,
          'fileSize': bytes.length,
          'mimeType': 'video/mp4',
        },
        'relationships': {
          'appPreviewSet': {
            'data': {'type': 'appPreviewSets', 'id': setId},
          },
        },
      },
    })).dataObject!;
    final id = '${reserved['id']}';
    final ops = ((reserved['attributes'] as Map)['uploadOperations'] as List)
        .cast<Map>();

    final uploader = http.Client();
    try {
      for (final op in ops) {
        final offset = op['offset'] as int;
        final length = op['length'] as int;
        final request = _UploadRequest(
          '${op['method']}',
          Uri.parse('${op['url']}'),
          bytes.sublist(offset, offset + length),
          {
            for (final h
                in ((op['requestHeaders'] as List?) ?? const []).cast<Map>())
              '${h['name']}': '${h['value']}',
          },
        );
        final status = await request.send(uploader);
        if (status < 200 || status >= 300) {
          throw StateError('preview chunk at $offset: HTTP $status');
        }
      }
    } finally {
      uploader.close();
    }

    await _client.patch('v1/appPreviews/$id', {
      'data': {
        'type': 'appPreviews',
        'id': id,
        'attributes': {
          'uploaded': true,
          'sourceFileChecksum': md5.convert(bytes).toString(),
          'previewFrameTimeCode': posterTimeCode,
        },
      },
    });

    final deadline = DateTime.now().add(timeout);
    var state = 'UPLOAD_COMPLETE';
    var errors = const <Object?>[];
    while (DateTime.now().isBefore(deadline)) {
      final a =
          (await _client.get('v1/appPreviews/$id')).dataObject!['attributes']
              as Map;
      final delivery = (a['assetDeliveryState'] as Map?) ?? const {};
      state = '${delivery['state']}';
      errors = (delivery['errors'] as List?) ?? const [];
      if (state == 'COMPLETE' || state == 'FAILED') break;
      await Future<void>.delayed(const Duration(seconds: 15));
    }
    return (id: id, state: state, errors: errors);
  }
}

/// One upload operation of a reserved asset (raw bytes, Apple's headers).
class _UploadRequest {
  _UploadRequest(this.method, this.url, this.body, this.headers);

  final String method;
  final Uri url;
  final List<int> body;
  final Map<String, String> headers;

  Future<int> send(http.Client client) async {
    final request = http.Request(method, url)
      ..headers.addAll(headers)
      ..bodyBytes = body;
    return (await client.send(request)).statusCode;
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
