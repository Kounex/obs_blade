import 'dart:async';

import 'package:get_ip/get_ip.dart';

import 'package:ping_discover_network/ping_discover_network.dart';
import 'package:tcp_scanner/tcp_scanner.dart';

class NetworkHelper {
  static Future<List<NetworkAddress>> getOBSNetworkAddresses() async {
    return NetworkAnalyzer.discover2(
      (await GetIp.ipAddress).split('.').take(3).join('.'),
      4444,
      timeout: Duration(milliseconds: 5000),
    ).toList();
  }

  static Future<List<String>> getAvailableOBSIPs(
      {Duration timeout = const Duration(seconds: 5)}) async {
    String baseIP = (await GetIp.ipAddress).split('.').take(3).join('.');
    List<int> availableIPs = [];

    List<ScanResult> results = await Future.wait<ScanResult>(
        List.generate(256, (index) => index).map((index) =>
            TCPScanner('$baseIP.${index.toString()}', [4444], timeout: 300)
                .noIsolateScan()));

    results.forEach((r) => r.open.length > 0
        ? availableIPs.add(int.parse(r.host.split('.').last))
        : null);

    return availableIPs.map((i) => '$baseIP.$i').toList();
  }
}
