// Include generated file
import 'dart:async';
import 'dart:convert';

import 'package:mobx/mobx.dart';
import 'package:obs_station/models/connection.dart';
import 'package:obs_station/models/session.dart';
import 'package:obs_station/types/enums/request_type.dart';
import 'package:obs_station/utils/network_helper.dart';

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
  bool authRequired = false;
  @observable
  bool wrongPW = false;
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

    StreamSubscription subscription;
    subscription = this.activeSession.socket.stream.listen(
      (event) {
        print(event);
        Map<String, dynamic> result = json.decode(event);
        switch (RequestType.values[int.parse(result['message-id'])]) {
          case RequestType.GetAuthRequired:
            this.authRequired = result['authRequired'];
            this.activeSession.connection.challenge = result['challenge'];
            this.activeSession.connection.salt = result['salt'];
            if (this.authRequired) {
              this.makeRequest(RequestType.Authenticate,
                  {'auth': NetworkHelper.getAuthResponse(connection)});
            } else {
              authCompleter.complete(true);
            }
            break;
          case RequestType.Authenticate:
            authCompleter.complete(result['status'] == 'ok' ? true : false);
            break;
        }
      },
      onDone: () => print('done'),
      onError: (error) => print(error),
    );
    this.makeRequest(RequestType.GetAuthRequired);
    this.connected = await Future.any([
      authCompleter.future,
      Future.delayed(timeout, () {
        subscription.cancel();
        return false;
      })
    ]);
    print('connected: ${this.connected}');
    if (!this.connected) {
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

  bool makeRequest(RequestType request, [Map<String, dynamic> fields]) {
    if (this.activeSession != null) {
      this.activeSession.socket.sink.add(json.encode({
            'request-type': request.type,
            'message-id': request.index.toString(),
            if (fields != null) ...fields
          }));
      return true;
    }
    return false;
  }
}
