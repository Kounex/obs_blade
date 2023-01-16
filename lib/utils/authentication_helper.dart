import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:obs_blade/types/classes/session.dart';

import '../models/connection.dart';
import '../types/enums/web_socket_codes/web_socket_op_code.dart';

class AuthenticationHelper {
  /// This is the content of the auth field which is needed to correctly
  /// authenticate with the OBS WebSocket if a password has been set
  static String _getAuthRequestContent(Connection connection) {
    String secretString = '${connection.pw}${connection.salt}';
    Digest secretHash = sha256.convert(utf8.encode(secretString));
    String secret = const Base64Codec().encode(secretHash.bytes);

    String authResponseString = '$secret${connection.challenge}';
    Digest authResponseHash = sha256.convert(utf8.encode(authResponseString));
    String authResponse = const Base64Codec().encode(authResponseHash.bytes);

    return authResponse;
  }

  static void identify(Session activeSession) {
    activeSession.socket.sink.add(
      jsonEncode(
        {
          'op': WebSocketOpCode.Identify.identifier,
          'd': {
            'rpcVersion': 1,
            'authentication': AuthenticationHelper._getAuthRequestContent(
                activeSession.connection),
            'eventSubscriptions': 131071
          }
        },
      ),
    );
  }
}
