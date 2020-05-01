import 'dart:async';
import 'dart:convert';

import 'package:connectivity/connectivity.dart';
import 'package:crypto/crypto.dart';
import 'package:obs_station/models/connection.dart';

import 'package:tcp_scanner/tcp_scanner.dart';
import 'package:web_socket_channel/io.dart';

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
    /*
    password = "supersecretpassword"
challenge = "ztTBnnuqrqaKDzRM3xcVdbYm"
salt = "PZVbYpvAnZut2SS6JNJytDm9"

secret_string = password + salt
secret_hash = binary_sha256(secret_string)
secret = base64_encode(secret_hash)

auth_response_string = secret + challenge
auth_response_hash = binary_sha256(auth_response_string)
auth_response = base64_encode(auth_response_hash)
    */
  }
}
