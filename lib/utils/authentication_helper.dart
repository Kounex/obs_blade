import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:obs_blade/types/classes/session.dart';
import 'package:obs_blade/types/enums/web_socket_codes/event_subscription.dart';

import '../models/connection.dart';
import '../types/enums/web_socket_codes/web_socket_op_code.dart';

class AuthenticationHelper {
  /// OBS WebSocket auth string: SHA256(password+salt) → b64, then
  /// SHA256(secret+challenge) → b64. Matches protocol “Creating an
  /// authentication string”.
  static String createAuthenticationString(
    String password,
    String salt,
    String challenge,
  ) {
    final secretHash = sha256.convert(utf8.encode('$password$salt'));
    final secret = base64.encode(secretHash.bytes);

    final authResponseHash = sha256.convert(utf8.encode('$secret$challenge'));
    return base64.encode(authResponseHash.bytes);
  }

  /// Sends Identify. Include [authentication] only when Hello required auth
  /// ([Connection.challenge] / [Connection.salt] set).
  static void identify(
    Session activeSession, {
    int rpcVersion = 1,
    int eventSubscriptions = EventSubscription.appDefault,
  }) {
    final connection = activeSession.connection;
    final authRequired =
        connection.challenge != null && connection.salt != null;

    final Map<String, dynamic> data = {
      'rpcVersion': rpcVersion,
      'eventSubscriptions': eventSubscriptions,
    };

    if (authRequired) {
      data['authentication'] = createAuthenticationString(
        connection.pw ?? '',
        connection.salt!,
        connection.challenge!,
      );
    }

    activeSession.socket.sink.add(
      jsonEncode({
        'op': WebSocketOpCode.Identify.identifier,
        'd': data,
      }),
    );
  }
}
