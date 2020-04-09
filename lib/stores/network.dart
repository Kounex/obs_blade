// Include generated file
import 'dart:async';
import 'dart:convert';

import 'package:mobx/mobx.dart';
import 'package:obs_station/models/connection.dart';
import 'package:obs_station/models/session.dart';
import 'package:obs_station/utils/network_helper.dart';
import 'package:web_socket_channel/io.dart';

part 'network.g.dart';

class NetworkStore = _NetworkStore with _$NetworkStore;

abstract class _NetworkStore with Store {
  @observable
  Future<List<Connection>> autodiscoverConnections;
  @observable
  String autodiscoverPort = '4444';

  @observable
  Session activeSession;
  @observable
  bool connected = false;

  @observable
  bool connectionWasInProgress = false;
  @observable
  bool connectionInProgress = false;

  @action
  void setAutodiscoverPort(String autodiscoverPort) =>
      this.autodiscoverPort = autodiscoverPort;

  @action
  void updateAutodiscoverConnections() {
    int port = int.tryParse(autodiscoverPort);
    if (port != null && port > 0 && port <= 65535) {
      this.autodiscoverConnections =
          NetworkHelper.getAvailableOBSIPs(port: port);
    }
  }

  @action
  Future<void> setOBSWebSocket(Connection connection,
      {Duration timeout = const Duration(seconds: 3)}) async {
    this.closeSession();
    if (!this.connectionWasInProgress) {
      this.connectionWasInProgress = true;
    }
    this.connectionInProgress = true;
    this.activeSession =
        Session(NetworkHelper.establishWebSocket(connection), connection);
    Completer<bool> authCompleter = Completer();
    bool authRequired;

    StreamSubscription subscription;
    subscription = this.activeSession.socket.stream.listen(
      (event) {
        authRequired = json.decode(event)['authRequired'];
        authCompleter.complete(true);
        subscription.cancel();
      },
      onDone: () => print('done'),
      onError: (error) => print(error),
    );
    this.activeSession.socket.sink.add(
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
      this.connected = true;
    } else {
      this.activeSession = null;
    }
    this.connectionInProgress = false;
  }

  @action
  void closeSession() {
    if (this.activeSession != null) {
      this.activeSession.socket.sink.close();
      this.activeSession = null;
      this.connected = false;
      this.connectionWasInProgress = false;
    }
  }
}
