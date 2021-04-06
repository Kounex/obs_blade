import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:crypto/crypto.dart';
import 'package:obs_blade/types/exceptions/network.dart';
import 'package:tcp_scanner/tcp_scanner.dart';
import 'package:web_socket_channel/io.dart';

import '../models/connection.dart';
import '../types/enums/request_type.dart';

class NetworkHelper {
  /// Establish and return an instance of [IOWebSocketChannel] based on the
  /// information inside a connection (IP and port). Currently using a
  /// [pingInterval] of 3 seconds which will check if the WebSocket connection
  /// is still alive in a 3 seconds interval - this will result in being able
  /// to check for [closeStatus] or [closeResult] whether the connection is
  /// alive or not. Mainly used in [DashboardStore] where a [Timer] is periodically
  /// checking this to be able to reconnect if possible or navigate back to
  /// [HomeView] otherwise
  static IOWebSocketChannel establishWebSocket(Connection connection) =>
      IOWebSocketChannel.connect(
        'ws://${connection.ip}:${connection.port.toString()}',
        pingInterval: Duration(seconds: 3),
      );

  static Future<Iterable<String>> getLocalIPAdress() async {
    final List<NetworkInterface> interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4, includeLinkLocal: true);

    return interfaces.expand((interface) =>
        interface.addresses.map((addresses) => addresses.address));
  }

  /// Initiating an autodiscover process (based on [TCPScanner]) to look for
  /// applications in the local network which listen on the given port (default
  /// port is 4444)
  static Future<List<Connection>> getAvailableOBSIPs(int port) async {
    if ((await Connectivity().checkConnectivity()) == ConnectivityResult.wifi) {
      List<String> baseIPs = (await NetworkHelper.getLocalIPAdress()).toList();
      List<String> availableIPs = [];

      print(baseIPs);

      for (int i = 0; i < baseIPs.length; i++) {
        List<ScanResult> results = [];
        String baseIP = baseIPs[i].split('.').take(3).join('.');

        results = await Future.wait<ScanResult>(
            List.generate(256, (index) => index).map((index) =>
                TCPScanner('$baseIP.${index.toString()}', [port], timeout: 1000)
                    .noIsolateScan()));

        results.forEach(
            (r) => r.open.length > 0 ? availableIPs.add(r.host) : null);
      }

      return availableIPs.map((address) => Connection(address, port)).toList();
    }
    throw NotInWLANException();
  }

  /// This is the content of the auth field which is needed to correctly
  /// authenticate with the OBS WebSocket if a password has been set
  static String getAuthRequestContent(Connection connection) {
    String secretString = '${connection.pw}${connection.salt}';
    Digest secretHash = sha256.convert(utf8.encode(secretString));
    String secret = Base64Codec().encode(secretHash.bytes);

    String authResponseString = '$secret${connection.challenge}';
    Digest authResponseHash = sha256.convert(utf8.encode(authResponseString));
    String authResponse = Base64Codec().encode(authResponseHash.bytes);

    return authResponse;
  }

  /// Making a request to the OBS WebSocket to trigger a request being
  /// sent back through the stream so we every listener can act accordingly
  static void makeRequest(IOWebSocketChannel channel, RequestType request,
      [Map<String, dynamic>? fields]) {
    print(request);
    channel.sink.add(json.encode({
      'message-id': request.index.toString(),
      'request-type': request.toString().split('.')[1],
      if (fields != null) ...fields
    }));
  }
}
