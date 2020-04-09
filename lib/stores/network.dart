// Include generated file
import 'dart:async';
import 'dart:convert';

import 'package:mobx/mobx.dart';
import 'package:mobx_provider/mobx_provider.dart';
import 'package:obs_station/models/connection.dart';
import 'package:obs_station/utils/network_helper.dart';
import 'package:web_socket_channel/io.dart';

part 'network.g.dart';

class NetworkStore = _NetworkStore with _$NetworkStore;

abstract class _NetworkStore extends MobxBase with Store {
  @observable
  Future<List<Connection>> _autodiscoverConnections;
  @observable
  String _autodiscoverPort = '4444';

  @observable
  IOWebSocketChannel _obsWebSocket;

  @observable
  bool _connectionWasInProgress = false;
  @observable
  bool _connectionInProgress = false;
  @observable
  bool _connected = false;

  String get autodiscoverPort => _autodiscoverPort;

  Future<List<Connection>> get obsAutodiscoverConnections =>
      _autodiscoverConnections;

  IOWebSocketChannel get obsWebSocket => _obsWebSocket;

  bool get connectionWasInProgress => _connectionWasInProgress;

  bool get connectionInProgress => _connectionInProgress;

  bool get connected => _connected;

  @action
  void setAutodiscoverPort(String autodiscoverPort) =>
      _autodiscoverPort = autodiscoverPort;

  @action
  void updateAutodiscoverConnections() {
    int port = int.tryParse(autodiscoverPort);
    if (port != null && port > 0 && port <= 65535) {
      _autodiscoverConnections = NetworkHelper.getAvailableOBSIPs(port: port);
    }
  }

  @action
  Future<void> setOBSWebSocket(Connection connection,
      {Duration timeout = const Duration(seconds: 3)}) async {
    if (_obsWebSocket != null) {
      _obsWebSocket.sink.close();
      _obsWebSocket = null;
      _connected = false;
    }
    if (!_connectionWasInProgress) {
      _connectionWasInProgress = true;
    }
    _connectionInProgress = true;
    _obsWebSocket = NetworkHelper.establishWebSocket(connection);
    Completer<bool> authCompleter = Completer();
    bool authRequired;

    StreamSubscription subscription;
    subscription = _obsWebSocket.stream.listen(
      (event) {
        authRequired = json.decode(event)['authRequired'];
        authCompleter.complete(true);
        subscription.cancel();
      },
      onDone: () => print('done'),
      onError: (error) => print(error),
    );
    _obsWebSocket.sink.add(
        json.encode({'request-type': 'GetAuthRequired', 'message-id': '0'}));

    bool connected = await Future.any([
      authCompleter.future,
      Future.delayed(timeout, () {
        subscription.cancel();
        return false;
      })
    ]);
    print('connected: $connected');
    if (connected) {
      print('auth required: $authRequired');
      _connected = true;
    } else {
      _obsWebSocket = null;
    }
    _connectionInProgress = false;
  }

  @override
  void dispose() {}
}
