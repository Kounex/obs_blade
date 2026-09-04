import 'package:provisioning/src/api_client.dart';

/// Records every request and answers from a scripted per-endpoint queue.
/// Unscripted endpoints answer with an empty JSON:API collection, which
/// reads as "does not exist" to the provisioners.
class FakeApiClient extends ApiClient {
  final requests = <String>[];
  final bodies = <String, Map<String, Object?>>{};
  final _responses = <String, List<ApiResponse>>{};

  void on(String method, String path, ApiResponse response) =>
      _responses.putIfAbsent('$method $path', () => []).add(response);

  ApiResponse _next(String method, String path) {
    final queue = _responses['$method $path'];
    if (queue == null || queue.isEmpty) return ApiResponse(200, {'data': []});
    return queue.removeAt(0);
  }

  String _key(String method, String path, Map<String, String> query) {
    final q = query.isEmpty
        ? ''
        : '?${query.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    return '$method $path$q';
  }

  @override
  Future<ApiResponse> get(String path,
      [Map<String, String> query = const {}]) async {
    requests.add(_key('GET', path, query));
    return _next('GET', path);
  }

  @override
  Future<ApiResponse> post(String path, Map<String, Object?> body,
      [Map<String, String> query = const {}]) async {
    requests.add(_key('POST', path, query));
    bodies[_key('POST', path, query)] = body;
    return _next('POST', path);
  }

  @override
  Future<ApiResponse> patch(String path, Map<String, Object?> body,
      [Map<String, String> query = const {}]) async {
    requests.add(_key('PATCH', path, query));
    bodies[_key('PATCH', path, query)] = body;
    return _next('PATCH', path);
  }

  @override
  Future<ApiResponse> delete(String path) async {
    requests.add('DELETE $path');
    return _next('DELETE', path);
  }

  /// Counts requests to an exact endpoint (query string ignored), so
  /// `.../subscriptions` does not match `.../subscriptions/pro/...`.
  int count(String method, String path) => requests
      .where((r) => r.split('?').first == '$method $path')
      .length;
}
