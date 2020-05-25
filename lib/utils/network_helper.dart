import 'dart:async';
import 'dart:convert';

import 'package:connectivity/connectivity.dart';
import 'package:crypto/crypto.dart';
import 'package:tcp_scanner/tcp_scanner.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/connection.dart';
import '../types/enums/request_type.dart';

class NetworkHelper {
  static IOWebSocketChannel establishWebSocket(Connection connection) =>
      IOWebSocketChannel.connect(
          'ws://${connection.ip}:${connection.port.toString()}');

  static Future<List<Connection>> getAvailableOBSIPs({int port = 4444}) async {
    String baseIP =
        (await Connectivity().getWifiIP()).split('.').take(3).join('.');
    List<int> availableIPs = [];

    List<ScanResult> results = await Future.wait<ScanResult>(
        List.generate(256, (index) => index).map((index) =>
            TCPScanner('$baseIP.${index.toString()}', [port], timeout: 1000)
                .noIsolateScan()));

    results.forEach((r) => r.open.length > 0
        ? availableIPs.add(int.parse(r.host.split('.').last))
        : null);

    return availableIPs.map((i) => Connection('$baseIP.$i', port)).toList();
  }

  static String getAuthResponse(Connection connection) {
    String secretString = '${connection.pw}${connection.salt}';
    Digest secretHash = sha256.convert(utf8.encode(secretString));
    String secret = Base64Codec().encode(secretHash.bytes);

    String authResponseString = '$secret${connection.challenge}';
    Digest authResponseHash = sha256.convert(utf8.encode(authResponseString));
    String authResponse = Base64Codec().encode(authResponseHash.bytes);

    return authResponse;
  }

  static void makeRequest(WebSocketSink sink, RequestType request,
      [Map<String, dynamic> fields]) {
    sink.add(json.encode({
      'message-id': request.index.toString(),
      'request-type': request.type,
      if (fields != null) ...fields
    }));
  }
}
