import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:connectivity/connectivity.dart';
import 'package:crypto/crypto.dart';
import 'package:obs_blade/types/exceptions/network.dart';
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

  /// Returns a list of network addresses which are candidates for the assigned
  /// local wifi address
  static Future<Iterable<String>> getLocalIPAdress() async {
    final List<NetworkInterface> interfaces =
        await NetworkInterface.list(type: InternetAddressType.IPv4);

    /// Currently checking if any of the network interfaces contain those
    /// names since they can have different names in different OS environments.
    /// Need to test this on several Android devices. If this filtered list
    /// is empty, all interfaces will be searched which will increase
    /// the probability of finding the correct one but might take a longer
    /// time than anticipated

    Iterable<NetworkInterface> candidateInterfaces = interfaces.where(
        (interface) =>
            interface.name.contains('en') ||
            interface.name.contains('eth') ||
            interface.name.contains('wlan'));

    return (candidateInterfaces.isEmpty ? interfaces : candidateInterfaces)
        .expand((interface) =>
            interface.addresses.map((addresses) => addresses.address));
  }

  /// Initiating an autodiscover process with an isolate function to make this
  /// kind of resource hungry operation threaded.
  static Future<List<Connection>> getAvailableOBSIPs(int port) async {
    if ((await Connectivity().checkConnectivity()) == ConnectivityResult.wifi) {
      List<String> baseIPs = (await NetworkHelper.getLocalIPAdress()).toList();

      print(baseIPs);

      Completer completer = Completer();
      ReceivePort receivePort = ReceivePort();
      Isolate.spawn(_isolateScan, {
        'sendPort': receivePort.sendPort,
        'baseIPs': baseIPs,
        'port': port,
      });

      receivePort.listen((availableConnections) {
        receivePort.close();
        completer.complete(availableConnections);
      });

      return await completer.future;
    }
    throw NotInWLANException();
  }

  static void _isolateScan(Map<dynamic, dynamic> arguments) async {
    SendPort sendPort = arguments['sendPort'];
    List<String> baseIPs = List.from(arguments['baseIPs']);
    int port = arguments['port'];

    List<Connection> availableConnections = [];

    Socket? socket;
    String? address;
    Connection? connection;

    for (int i = 0; i < baseIPs.length; i++) {
      String baseIP = baseIPs[i].split('.').take(3).join('.');

      print('$baseIP.x');

      for (int k = 0; k < 256; k++) {
        address = '$baseIP.${k.toString()}';
        connection = Connection(address, port);
        try {
          availableConnections.add(connection);
          socket = await Socket.connect(address, port,
              timeout: Duration(milliseconds: 1));
        } catch (e) {
          availableConnections.remove(connection);
        } finally {
          if (socket != null) socket.destroy();
        }
      }
    }

    sendPort.send(availableConnections);
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
