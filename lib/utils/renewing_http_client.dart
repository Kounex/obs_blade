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
/// failure like that renews the client, and the caller's own retry (the
/// poll loop's backoff, a Retry button) goes out on new connections.
/// Requests are not repeated here - a POST may already have arrived.
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

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final inner = this._inner;
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
