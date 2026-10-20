import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// The chat services' HTTP client: an [http.Client] that throws its
/// connections away after a connection-level failure, and on
/// [renewAll] (app resume).
///
/// Why: iOS takes a suspended app's sockets away. After a while in the
/// background every YouTube poll and Retry failed with
/// `ClientException: Write failed` / `Bad file descriptor` (Settings →
/// Logs, 2026-10-04: the same client failing again and again for minutes)
/// until the app was restarted - a fresh client worked at once. The pooled
/// connections of the long-lived `dart:io` client were what broke, so a
/// failure like that renews the client; a GET / HEAD is sent once more on
/// it ([send]), anything else is left to the caller's own retry (the poll
/// loop's backoff, a Retry button) - a POST may already have arrived.
class RenewingHttpClient extends http.BaseClient {
  /// Test seam - a client given here is closed with its own `close()`
  final http.Client Function()? _create;

  late _Inner _inner;
  bool _closed = false;

  static final List<WeakReference<RenewingHttpClient>> _instances = [];

  RenewingHttpClient({http.Client Function()? create}) : _create = create {
    this._inner = this._newInner();
    _instances.add(WeakReference(this));
  }

  _Inner _newInner() {
    if (this._create case final create?) return _Inner(create());
    final io = HttpClient();
    return _Inner(IOClient(io), io);
  }

  /// App resume: every live client starts over on fresh connections
  static void renewAll() {
    _instances.removeWhere((ref) => ref.target == null);
    for (final ref in _instances) {
      ref.target?.renew();
    }
  }

  /// Drop the pooled connections - requests in flight finish on the old
  /// client, new ones get a fresh one. The old client closes once its
  /// requests have their answers: `HttpClient.close()` cancels connections
  /// still being set up even without force (dart:io
  /// `_ConnectionTarget.close`) - one Kick request's failure renewed the
  /// client and failed the four previews running beside it with
  /// "Connection attempt cancelled" (Settings → Logs, 2026-10-20).
  void renew() {
    if (this._closed) return;
    final old = this._inner;
    this._inner = this._newInner();
    old.retire();
  }

  /// Connection-level: the socket or the HTTP exchange broke, not an
  /// answer the server gave (those come back as responses)
  static bool isConnectionFailure(Object error) =>
      error is SocketException ||
      error is HttpException ||
      error is http.ClientException;

  /// A GET / HEAD that failed at the connection goes out once more on
  /// fresh connections, like a browser retries one on a reused
  /// connection: after a stay in the background a timer that came due
  /// can fire before the app hears it resumed ([renewAll]), and its
  /// request rides a socket iOS took away - "Connection closed before
  /// full header was received" (Settings → Logs, 2026-10-20).
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      return await this._sendOn(this._inner, request);
    } catch (error) {
      final again = _repeatable(request);
      if (!isConnectionFailure(error) || again == null || this._closed) {
        rethrow;
      }
      return this._sendOn(this._inner, again);
    }
  }

  /// A copy of [request] safe to send again (null: not repeatable - a
  /// POST may already have arrived)
  static http.Request? _repeatable(http.BaseRequest request) {
    if (request is! http.Request ||
        (request.method != 'GET' && request.method != 'HEAD')) {
      return null;
    }
    return http.Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection;
  }

  Future<http.StreamedResponse> _sendOn(
    _Inner inner,
    http.BaseRequest request,
  ) async {
    inner.pending++;
    try {
      return await inner.client.send(request);
    } catch (error) {
      if (isConnectionFailure(error) && identical(inner, this._inner)) {
        this.renew();
      }
      rethrow;
    } finally {
      inner.done();
    }
  }

  @override
  void close() {
    this._closed = true;
    this._inner.client.close();
  }
}

/// One client of a [RenewingHttpClient] and the sends waiting on it
class _Inner {
  final http.Client client;

  /// The default client's `dart:io` client: closed without force on
  /// retire - `IOClient.close()` always forces, which would abort the
  /// requests still running (a send, a token poll, a refresh)
  final HttpClient? io;

  int pending = 0;
  bool _retired = false;

  _Inner(this.client, [this.io]);

  void retire() {
    this._retired = true;
    if (this.pending == 0) this._close();
  }

  void done() {
    this.pending--;
    if (this._retired && this.pending == 0) this._close();
  }

  void _close() {
    if (this.io case final io?) {
      io.close();
    } else {
      this.client.close();
    }
  }
}
