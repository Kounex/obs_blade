import '../models/connection.dart';

/// Whether [code] is an OBS WebSocket "Connect QR" payload.
bool isObsConnectUri(String? code) {
  if (code == null) return false;
  final lower = code.toLowerCase();
  return lower.startsWith('obsws://') || lower.startsWith('obswss://');
}

/// Official Connect Info QR: `obsws[s]://host:port/password`.
///
/// OBS percent-encodes the password (`QUrl::toPercentEncoding`), and
/// [Uri.path] keeps that encoding - it has to be decoded or every password
/// with a special character fails authentication. A payload that isn't
/// valid percent-encoding (hand-made QR) keeps the raw text.
Connection? connectionFromObsConnectUri(String data) {
  try {
    final uri = Uri.parse(data);
    if (uri.host.isEmpty) return null;

    final port = uri.hasPort ? uri.port : 4455;
    final rawPw = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
    String pw;
    try {
      pw = Uri.decodeComponent(rawPw);
    } catch (_) {
      pw = rawPw;
    }

    final isSecure = uri.scheme.toLowerCase() == 'obswss';
    final host = isSecure ? 'wss://${uri.host}' : uri.host;

    return Connection(host, port, pw.isEmpty ? null : pw, isSecure);
  } catch (_) {
    return null;
  }
}
