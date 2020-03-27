import 'package:get_ip/get_ip.dart';
import 'package:ping_discover_network/ping_discover_network.dart';
import 'package:web_socket_channel/io.dart';

class NetworkHelper {
  static Future<List<NetworkAddress>> getOBSNetworkAddresses() async {
    return NetworkAnalyzer.discover(
      (await GetIp.ipAddress).split('.').take(3).join('.'),
      4444,
      timeout: Duration(milliseconds: 5000),
    ).toList();
  }

  static Future<Stream<dynamic>> getOBSWebsocketStream() async {
    String baseIP = (await GetIp.ipAddress).split('.').take(3).join('.');
    int ipCount = 0;
    Future.doWhile(() {
      IOWebSocketChannel.connect("ws://$baseIP.${ipCount.toString()}:4444")
          .stream
          .listen(
            ((event) => print(event.toString())),
            onError: (error) => print(error.toString()),
          );
      ipCount++;
    });
  }
}
