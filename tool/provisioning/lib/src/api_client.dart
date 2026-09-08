import 'dart:convert';

import 'package:http/http.dart' as http;

/// Minimal response wrapper so the provisioning logic can be driven by a
/// fake client in tests (and by the dry-run client without any network).
class ApiResponse {
  ApiResponse(this.statusCode, this.body);

  final int statusCode;

  /// Decoded JSON body, or null when the body was empty / not JSON.
  final Object? body;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  Map<String, Object?> get json =>
      body is Map<String, Object?> ? body as Map<String, Object?> : const {};

  /// JSON:API `data` member — list for collection endpoints, map (or null)
  /// for single-resource endpoints.
  List<Map<String, Object?>> get dataList {
    final data = json['data'];
    if (data is List) {
      return data.whereType<Map<String, Object?>>().toList();
    }
    return const [];
  }

  Map<String, Object?>? get dataObject {
    final data = json['data'];
    return data is Map<String, Object?> ? data : null;
  }
}

/// Thrown on non-2xx responses. Carries the vendor error detail so the CLI
/// can print something actionable.
class ApiException implements Exception {
  ApiException(this.method, this.url, this.statusCode, this.detail);

  final String method;
  final String url;
  final int statusCode;
  final String detail;

  @override
  String toString() =>
      '$method $url -> HTTP $statusCode${detail.isEmpty ? '' : ': $detail'}';
}

/// Transport abstraction shared by the ASC and Play provisioners.
abstract class ApiClient {
  /// True for the dry-run client. Provisioners use it to tolerate lookups
  /// that cannot be simulated offline (e.g. price points).
  bool get isDryRun => false;

  Future<ApiResponse> get(String path, [Map<String, String> query = const {}]);

  Future<ApiResponse> post(
    String path,
    Map<String, Object?> body, [
    Map<String, String> query = const {},
  ]);

  Future<ApiResponse> patch(
    String path,
    Map<String, Object?> body, [
    Map<String, String> query = const {},
  ]);

  Future<ApiResponse> delete(String path);

  /// Like [get], but returns null on 404 instead of throwing.
  Future<ApiResponse?> getOrNull(
    String path, [
    Map<String, String> query = const {},
  ]) async {
    final response = await get(path, query);
    return response.statusCode == 404 ? null : response;
  }
}

/// Real HTTP transport against a JSON API base URL with a Bearer token.
class HttpApiClient extends ApiClient {
  HttpApiClient({required this.baseUrl, this.token, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;

  /// Bearer token. Null when [client] authenticates itself (e.g. an
  /// `AuthClient` from googleapis_auth, which injects the header).
  final String? token;
  final http.Client _client;

  Uri _uri(String path, Map<String, String> query) => Uri.parse(
    '$baseUrl/$path',
  ).replace(queryParameters: query.isEmpty ? null : query);

  Map<String, String> get _headers => {
    if (token != null) 'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  @override
  Future<ApiResponse> get(
    String path, [
    Map<String, String> query = const {},
  ]) async {
    final url = _uri(path, query);
    final response = await _client.get(url, headers: _headers);
    return _checked('GET', url, response);
  }

  @override
  Future<ApiResponse> post(
    String path,
    Map<String, Object?> body, [
    Map<String, String> query = const {},
  ]) async {
    final url = _uri(path, query);
    final response = await _client.post(
      url,
      headers: _headers,
      body: jsonEncode(body),
    );
    return _checked('POST', url, response);
  }

  @override
  Future<ApiResponse> patch(
    String path,
    Map<String, Object?> body, [
    Map<String, String> query = const {},
  ]) async {
    final url = _uri(path, query);
    final response = await _client.patch(
      url,
      headers: _headers,
      body: jsonEncode(body),
    );
    return _checked('PATCH', url, response);
  }

  @override
  Future<ApiResponse> delete(String path) async {
    final url = _uri(path, const {});
    final response = await _client.delete(url, headers: _headers);
    return _checked('DELETE', url, response);
  }

  ApiResponse _checked(String method, Uri url, http.Response response) {
    Object? body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } on FormatException {
        body = response.body;
      }
    }
    final wrapped = ApiResponse(response.statusCode, body);
    if (!wrapped.isSuccess && response.statusCode != 404) {
      throw ApiException(
        method,
        url.toString(),
        response.statusCode,
        _errorDetail(body) ?? response.reasonPhrase ?? '',
      );
    }
    return wrapped;
  }

  static String? _errorDetail(Object? body) {
    if (body is Map && body['errors'] is List) {
      return (body['errors'] as List)
          .whereType<Map>()
          .map((e) => '${e['code'] ?? e['title']}: ${e['detail'] ?? ''}'.trim())
          .join('; ');
    }
    if (body is Map && body['error'] is Map) {
      final error = body['error'] as Map;
      return '${error['code']}: ${error['message']}';
    }
    return null;
  }

  void close() => _client.close();
}

/// Client used for `--dry-run`: prints every request instead of sending it.
/// GETs report "nothing exists" so the full create flow (and its request
/// bodies) is shown; lookups that cannot be simulated (e.g. price points)
/// log a note and let the orchestrator skip the dependent call.
class DryRunApiClient extends ApiClient {
  DryRunApiClient({required this.serviceName, void Function(String)? log})
    : _log = log ?? print;

  final String serviceName;
  final void Function(String) _log;

  @override
  bool get isDryRun => true;

  void _print(
    String method,
    String path,
    Map<String, String> query, [
    Map<String, Object?>? body,
  ]) {
    final q = query.isEmpty
        ? ''
        : '?${query.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    _log('[dry-run/$serviceName] $method /$path$q');
    if (body != null) {
      _log(const JsonEncoder.withIndent('  ').convert(body));
    }
  }

  @override
  Future<ApiResponse> get(
    String path, [
    Map<String, String> query = const {},
  ]) async {
    _print('GET', path, query);
    // Report "empty" so every create path is exercised.
    return ApiResponse(200, {'data': <Object?>[]});
  }

  @override
  Future<ApiResponse?> getOrNull(
    String path, [
    Map<String, String> query = const {},
  ]) async {
    _print('GET', path, query);
    return null; // pretend it does not exist yet
  }

  @override
  Future<ApiResponse> post(
    String path,
    Map<String, Object?> body, [
    Map<String, String> query = const {},
  ]) async {
    _print('POST', path, query, body);
    return ApiResponse(201, {
      'data': {
        'type': body['data'] is Map ? (body['data'] as Map)['type'] : 'unknown',
        'id': 'DRY-RUN-ID',
      },
    });
  }

  @override
  Future<ApiResponse> patch(
    String path,
    Map<String, Object?> body, [
    Map<String, String> query = const {},
  ]) async {
    _print('PATCH', path, query, body);
    return ApiResponse(200, const {});
  }

  @override
  Future<ApiResponse> delete(String path) async {
    _print('DELETE', path, const {});
    return ApiResponse(204, null);
  }
}
