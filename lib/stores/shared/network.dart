import 'dart:async';
import 'dart:convert';

import 'package:connectivity/connectivity.dart';
import 'package:mobx/mobx.dart';

import '../../models/connection.dart';
import '../../types/classes/session.dart';
import '../../types/classes/stream/events/base.dart';
import '../../types/classes/stream/responses/base.dart';
import '../../types/classes/stream/responses/get_auth_required.dart';
import '../../types/enums/event_type.dart';
import '../../types/enums/request_type.dart';
import '../../types/interfaces/message.dart';
import '../../utils/network_helper.dart';

part 'network.g.dart';

class NetworkStore = _NetworkStore with _$NetworkStore;

abstract class _NetworkStore with Store {
  @observable
  Session activeSession;

  @observable
  bool connectionInProgress = false;
  @observable
  BaseResponse connectionResponse;

  @observable
  bool obsTerminated = false;

  @action
  Future<BaseResponse> setOBSWebSocket(Connection connection,
      {Duration timeout = const Duration(seconds: 3)}) async {
    this.closeSession();
    this.connectionResponse = null;
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
      authCompleter.future,
      Future.delayed(
          timeout, () => BaseResponse({'status': 'error', 'error': 'timeout'}))
    ]);

    subscription.cancel();
    if (this.connectionResponse.status != BaseResponse.ok) {
      this.activeSession.socket.sink.close();
      this.activeSession = null;
    } else {
      this.activeSession.connection.ssid = await Connectivity().getWifiName();
      this.handleStream();
    }
    this.connectionInProgress = false;
    return this.connectionResponse;
  }

  @action
  void closeSession({bool manually = true}) {
    this.obsTerminated = !manually;
    if (this.activeSession != null) {
      this.activeSession.socket.sink.close();
      this.activeSession = null;
      this.connectionResponse = null;
    }
  }

  @action
  void _handleEvent(BaseEvent event) {
    switch (event.eventType) {
      case EventType.Exiting:
        this.closeSession(manually: false);
        break;
      default:
        break;
    }
  }

  StreamSubscription _handleInitialWebSocket(
          Connection connection, Completer authCompleter) =>
      this.activeSession.socketStream.listen(
        (event) {
          Map<String, dynamic> jsonObject = json.decode(event);
          BaseResponse response = BaseResponse(jsonObject);
          switch (response.requestType) {
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
                    {'auth': NetworkHelper.getAuthRequestContent(connection)});
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

  Stream<Message> watchOBSStream() async* {
    try {
      await for (final event in this.activeSession.socketStream) {
        Map<String, dynamic> fullJSON = json.decode(event);
        if (fullJSON['update-type'] != null) {
          yield BaseEvent(fullJSON);
        } else {
          yield BaseResponse(fullJSON);
        }
      }
    } finally {
      this.activeSession?.socket?.sink?.close();
    }
  }

  void handleStream() {
    this.watchOBSStream().listen((message) {
      if (message is BaseEvent) {
        _handleEvent(message);
      }
    });
  }
}
