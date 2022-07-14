import 'dart:async';
import 'dart:convert';

import 'package:mobx/mobx.dart';
import 'package:obs_blade/types/enums/web_socket_codes/request_status.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_op_code.dart';

import '../../models/connection.dart';
import '../../models/enums/log_level.dart';
import '../../types/classes/session.dart';
import '../../types/classes/stream/events/base.dart';
import '../../types/classes/stream/responses/base.dart';
import '../../types/classes/stream/responses/get_auth_required.dart';
import '../../types/enums/event_type.dart';
import '../../types/enums/request_type.dart';
import '../../types/interfaces/message.dart';
import '../../utils/general_helper.dart';
import '../../utils/network_helper.dart';

part 'network.g.dart';

class NetworkStore = _NetworkStore with _$NetworkStore;

abstract class _NetworkStore with Store {
  @observable
  Session? activeSession;

  @observable
  bool connectionInProgress = false;
  @observable
  BaseResponse? connectionResponse;

  @observable
  bool obsTerminated = false;

  /// Flag to detemine whether to use the old WebSocket
  /// protocol (< 5.X) or the new one
  bool newProtocol = true;

  BaseResponse get timeoutResponse => this.newProtocol
      ? BaseResponse(
          {
            'op': WebSocketOpCode.RequestResponse.identifier,
            'd': {
              'requestStatus': RequestStatusObject(
                false,
                RequestStatus.Timeout.identifier,
                RequestStatus.Timeout.message,
              ),
            },
          },
          this.newProtocol,
        )
      : BaseResponse(
          {'status': 'error', 'error': 'timeout'},
          this.newProtocol,
        );

  @action
  Future<BaseResponse> setOBSWebSocket(
    Connection connection, {
    bool reconnect = false,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (!reconnect) {
      this.closeSession();
    }
    this.connectionResponse = null;
    this.connectionInProgress = true;

    try {
      Completer<BaseResponse> authCompleter = Completer();

      /// Create a WebSocket connection
      this.activeSession =
          Session(NetworkHelper.establishWebSocket(connection), connection);

      /// Set the stream as boradcast so it can be listened to
      /// multiple times
      this.activeSession!.socketStream =
          this.activeSession!.socket.stream.asBroadcastStream();

      /// Subscription which will handle the auth part
      StreamSubscription subscription =
          _handleInitialWebSocket(connection, authCompleter);

      /// Fire the first auth request which will be handled by the
      /// subscription above - only necessary with the olf protocol.
      /// The new protocol will already answer once we connect and
      /// we go from there (in [_handleInitialWebSocket])
      if (!this.newProtocol) {
        NetworkHelper.makeRequest(
          this.activeSession!.socket,
          RequestType.GetAuthRequired,
        );
      }

      /// We wait for the [Completer] (which should complete
      /// once we are done with the auth part - either positive
      /// or negative) ot return a timeout response to handle
      this.connectionResponse = await Future.any([
        authCompleter.future,
        Future.delayed(
          timeout,
          () => this.timeoutResponse,
        )
      ]);

      subscription.cancel();

      if (!reconnect) {
        if (this.newProtocol
            ? (!this.connectionResponse!.statusNew.result)
            : (this.connectionResponse!.statusOld != BaseResponse.ok)) {
          this.activeSession!.socket.sink.close();
          this.activeSession = null;
        } else {
          // this.activeSession.connection.ssid = await Connectivity().getWifiName();
          this.handleStream();
        }
      }
    } catch (e) {
      GeneralHelper.advLog(
        'Not possible to connect to ${connection.host}${connection.port != null ? (":" + connection.port.toString()) : ""}: $e',
        level: LogLevel.Error,
        includeInLogs: true,
      );

      this.connectionResponse =
          await Future.delayed(timeout, () => this.timeoutResponse);
    }

    this.connectionInProgress = false;
    return this.connectionResponse!;
  }

  @action
  void closeSession({bool manually = true}) {
    this.obsTerminated = !manually;
    if (this.activeSession != null) {
      this.activeSession!.socket.sink.close();
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
      this.activeSession!.socketStream!.listen(
        (event) {
          Map<String, dynamic> jsonObject = json.decode(event);

          /// While hadling the initial messages of the WebSocket,
          /// we check whether 'op' is included (which is always
          /// present when using the new protocol) and set our
          /// internal flag accordignly
          this.newProtocol = jsonObject['op'] != null;

          if (this.newProtocol) {
            _handleNewProtocol(connection, authCompleter, jsonObject);
          } else {
            BaseResponse response = BaseResponse(jsonObject, this.newProtocol);
            _handleOldProtocol(connection, authCompleter, response);
          }
        },
        onDone: () {
          GeneralHelper.advLog(
            'Initial WebSocket connection done, close code: ${this.activeSession!.socket.closeCode}',
          );
          authCompleter.complete(BaseResponse(
            {
              'op': WebSocketOpCode.RequestResponse.identifier,
              'd': {
                'requestStatus': RequestStatusObject(
                  false,
                  this.activeSession!.socket.closeCode!,
                  WebSocketCloseCode.values
                      .firstWhere(
                          (closeCode) =>
                              closeCode.identifier ==
                              this.activeSession!.socket.closeCode,
                          orElse: () => WebSocketCloseCode.UnknownReason)
                      .message,
                ),
              },
            },
            this.newProtocol,
          ));
        },
        onError: (error) => GeneralHelper.advLog(
          'Error initial WebSocket connection (stores/shared/network.dart) | $error',
          includeInLogs: true,
        ),
      );

  void _handleNewProtocol(
    Connection connection,
    Completer authCompleter,
    Map<String, dynamic> json,
  ) {
    if (json['op'] == WebSocketOpCode.Hello.identifier) {
      String? authentication;
      if (json['d']['authentication'] != null) {
        connection.challenge = json['d']['authentication']['challenge'];
        connection.salt = json['d']['authentication']['salt'];

        authentication = NetworkHelper.getAuthRequestContent(connection);
      }
      this.activeSession!.socket.sink.add(
            jsonEncode(
              {
                'op': WebSocketOpCode.Identify.identifier,
                'd': {
                  'rpcVersion': 1,
                  'authentication': authentication,
                  'eventSubscriptions': 1048575
                }
              },
            ),
          );
    } else if (json['op'] == WebSocketOpCode.Identified.identifier) {
      authCompleter.complete(BaseResponse(
        {
          'op': WebSocketOpCode.RequestResponse.identifier,
          'd': {
            'requestStatus': RequestStatusObject(
              true,
              RequestStatus.Success.identifier,
              RequestStatus.Success.message,
            ),
          },
        },
        true,
      ));
    }
  }

  void _handleOldProtocol(
    Connection connection,
    Completer authCompleter,
    BaseResponse response,
  ) {
    switch (response.requestType) {
      case RequestType.GetAuthRequired:
        GetAuthRequiredResponse getAuthResponse =
            GetAuthRequiredResponse(response.json, false);
        connection.challenge = getAuthResponse.challenge;
        connection.salt = getAuthResponse.salt;
        if (getAuthResponse.authRequired) {
          NetworkHelper.makeRequest(
            this.activeSession!.socket,
            RequestType.Authenticate,
            {'auth': NetworkHelper.getAuthRequestContent(connection)},
          );
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
  }

  Stream<Message> watchOBSStream() async* {
    try {
      await for (final event in this.activeSession!.socketStream!) {
        Map<String, dynamic> fullJSON = json.decode(event);
        if (this.newProtocol
            ? (fullJSON['op'] == WebSocketOpCode.Event.identifier)
            : (fullJSON['update-type'] != null)) {
          yield BaseEvent(fullJSON, this.newProtocol);
        } else {
          yield BaseResponse(fullJSON, this.newProtocol);
        }
      }
    } finally {
      this.activeSession?.socket.sink.close();
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
