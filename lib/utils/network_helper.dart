import 'dart:async';
import 'dart:convert';

import 'package:get_ip/get_ip.dart';
import 'package:mobx/mobx.dart';
import 'package:ping_discover_network/ping_discover_network.dart';
import 'package:web_socket_channel/io.dart';

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

    List.generate(256, (index) {
      IOWebSocketChannel channel =
          IOWebSocketChannel.connect("ws://$baseIP.${index.toString()}:4444");

      channel.stream.listen(
        ((event) {
          print(event);
          availableIPs.add(index);
          channel.sink.close();
        }),
        onError: (_) => channel.sink.close(),
      );

      channel.sink.add(json.encode('GetAuthRequired'));
    });

    await Future.delayed(timeout);

    return availableIPs.map((i) => '$baseIP.$i').toList();
  }
}
