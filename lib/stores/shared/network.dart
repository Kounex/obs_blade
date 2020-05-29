import 'dart:async';
import 'dart:convert';

import 'package:connectivity/connectivity.dart';
import 'package:mobx/mobx.dart';

import '../../models/connection.dart';
import '../../types/classes/session.dart';
import '../../types/classes/stream/responses/base.dart';
import '../../types/classes/stream/responses/get_auth_required.dart';
import '../../types/enums/request_type.dart';
import '../../types/enums/response_status.dart';
import '../../utils/network_helper.dart';

part 'network.g.dart';

class NetworkStore = _NetworkStore with _$NetworkStore;

abstract class _NetworkStore with Store {
  @observable
  Session activeSession;
  @observable
  BaseResponse connectionResponse;

  @observable
  bool connectionWasInProgress = false;
  @observable
  bool connectionInProgress = false;

  @action
  Future<BaseResponse> setOBSWebSocket(Connection connection,
      {Duration timeout = const Duration(seconds: 3)}) async {
    this.closeSession();
    if (!this.connectionWasInProgress) {
      this.connectionWasInProgress = true;
    }
    this.connectionInProgress = true;
    this.activeSession =
        Session(NetworkHelper.establishWebSocket(connection), connection);
    Completer<BaseResponse> authCompleter = Completer();

    this.activeSession.socketStream =
        this.activeSession.socket.stream.asBroadcastStream();

    StreamSubscription subscription =
        _handleInitialWebSocket(connection, authCompleter);

    NetworkHelper.makeRequest(
        this.activeSession.socket.sink, RequestType.GetAuthRequired);
    this.connectionResponse = await Future.any([
      authCompleter.future.then((value) => value),
      Future.delayed(timeout, () {
        return BaseResponse({'status': 'error', 'error': 'timeout'});
      })
    ]);

    subscription.cancel();
    if (this.connectionResponse.status != ResponseStatus.OK.text) {
      this.activeSession.socket.sink.close();
      this.activeSession = null;
    } else {
      this.activeSession.connection.ssid = await Connectivity().getWifiName();
    }
    this.connectionInProgress = false;
    return this.connectionResponse;
  }

  @action
  void closeSession() {
    if (this.activeSession != null) {
      this.activeSession.socket.sink.close();
      this.activeSession = null;
      this.connectionWasInProgress = false;
      this.connectionResponse = null;
    }
  }

  StreamSubscription _handleInitialWebSocket(
          Connection connection, Completer authCompleter) =>
      this.activeSession.socketStream.listen(
        (event) {
          Map<String, dynamic> jsonObject = json.decode(event);
          BaseResponse response = BaseResponse(jsonObject);
          switch (RequestType.values[response.messageID]) {
            case RequestType.GetAuthRequired:
              GetAuthRequiredResponse getAuthResponse =
                  GetAuthRequiredResponse(jsonObject);
              this.activeSession.connection.challenge =
                  getAuthResponse.challenge;
              this.activeSession.connection.salt = getAuthResponse.salt;
              if (getAuthResponse.authRequired) {
                NetworkHelper.makeRequest(
                    this.activeSession.socket.sink,
                    RequestType.Authenticate,
                    {'auth': NetworkHelper.getAuthResponse(connection)});
              } else {
                authCompleter.complete(response);
              }
              break;
            case RequestType.Authenticate:
              authCompleter.complete(response);
              break;
            default:
              break;
          }
        },
        onDone: () => print('done'),
        onError: (error) => print(error),
      );
}
