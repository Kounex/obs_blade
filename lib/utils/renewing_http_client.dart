import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// The chat services' HTTP client: an [http.Client] that throws its
/// connections away after a connection-level failure, and on
/// [renewAll] (app resume).
///
/// Why: iOS takes a suspended app's sockets away. After a while in the
/// background every YouTube poll and Retry failed with
/// `ClientException: Write failed` (Settings → Logs, 2026-10-04) until the
/// app was restarted - a fresh client worked at once. The pooled
/// connections of the long-lived `dart:io` client were what broke, so a
/// failure like that renews the client, and the caller's own retry (the
/// poll loop's backoff, a Retry button) goes out on new connections.
/// Requests are not repeated here - a POST may already have arrived.
class RenewingHttpClient extends http.BaseClient {
  final http.Client Function() _create;
  http.Client _inner;
  bool _closed = false;

  static final List<WeakReference<RenewingHttpClient>> _instances = [];

  RenewingHttpClient({http.Client Function()? create})
    : this._(create ?? http.Client.new);

  RenewingHttpClient._(this._create) : _inner = _create() {
    _instances.add(WeakReference(this));
  }

  /// App resume: every live client starts over on fresh connections
  static void renewAll() {
    _instances.removeWhere((ref) => ref.target == null);
    for (final ref in _instances) {
      ref.target?.renew();
    }
  }

  /// Drop the pooled connections - requests in flight finish on the old
  /// client (closed without force), new ones get a fresh one
  void renew() {
    if (this._closed) return;
    final old = this._inner;
    this._inner = this._create();
    old.close();
  }

  /// Connection-level: the socket or the HTTP exchange broke, not an
  /// answer the server gave (those come back as responses)
  static bool isConnectionFailure(Object error) =>
      error is SocketException ||
      error is HttpException ||
      error is http.ClientException;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final client = this._inner;
    try {
      return await client.send(request);
    } catch (error) {
      if (isConnectionFailure(error) && identical(client, this._inner)) {
        this.renew();
      }
      rethrow;
    }
  }

  @override
  void close() {
    this._closed = true;
    this._inner.close();
  }
}
