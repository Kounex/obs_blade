import 'dart:async';

import 'package:connectivity/connectivity.dart';

import 'package:tcp_scanner/tcp_scanner.dart';
import 'package:web_socket_channel/io.dart';

class NetworkHelper {
  static Future<void> establishWebSocket(String ip, int port,
      [String password]) async {
    IOWebSocketChannel channel =
        IOWebSocketChannel.connect('ws://$ip:${port.toString()}');
  }

  static Future<List<String>> getAvailableOBSIPs({int port = 4444}) async {
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

    return availableIPs.map((i) => '$baseIP.$i').toList();
  }
}
