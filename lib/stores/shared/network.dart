// Include generated file
import 'dart:async';
import 'dart:convert';

import 'package:connectivity/connectivity.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_station/models/connection.dart';
import 'package:obs_station/models/session.dart';
import 'package:obs_station/types/classes/responses/base.dart';
import 'package:obs_station/types/classes/responses/get_auth_required.dart';
import 'package:obs_station/types/enums/request_type.dart';
import 'package:obs_station/types/enums/response_status.dart';
import 'package:obs_station/utils/network_helper.dart';

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
    StreamSubscription subscription = this.activeSession.socketStream.listen(
      (event) {
        Map<String, dynamic> jsonObject = json.decode(event);
        BaseResponse response = BaseResponse(jsonObject);
        switch (RequestType.values[response.messageID]) {
          case RequestType.GetAuthRequired:
            GetAuthRequiredResponse getAuthResponse =
                GetAuthRequiredResponse(jsonObject);
            this.activeSession.connection.challenge = getAuthResponse.challenge;
            this.activeSession.connection.salt = getAuthResponse.salt;
            if (getAuthResponse.authRequired) {
              this.makeRequest(RequestType.Authenticate,
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
    this.makeRequest(RequestType.GetAuthRequired);
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

  bool makeRequest(RequestType request, [Map<String, dynamic> fields]) {
    if (this.activeSession != null) {
      this.activeSession.socket.sink.add(json.encode({
            'message-id': request.index.toString(),
            'request-type': request.type,
            if (fields != null) ...fields
          }));
      return true;
    }
    return false;
  }
}
