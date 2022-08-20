import 'dart:async';
import 'dart:convert';

import 'package:mobx/mobx.dart';
import 'package:obs_blade/types/classes/stream/batch_responses/base.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_op_code.dart';
import 'package:obs_blade/utils/authentication_helper.dart';

import '../../models/connection.dart';
import '../../models/enums/log_level.dart';
import '../../types/classes/session.dart';
import '../../types/classes/stream/events/base.dart';
import '../../types/classes/stream/responses/base.dart';
import '../../types/enums/event_type.dart';
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
  WebSocketCloseCode? connectionClodeCode;

  @observable
  bool obsTerminated = false;

  @action
  Future<WebSocketCloseCode> setOBSWebSocket(
    Connection connection, {
    bool reconnect = false,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (!reconnect) {
      this.closeSession();
    }
    this.connectionClodeCode = null;
    this.connectionInProgress = true;

    try {
      Completer<WebSocketCloseCode> authCompleter = Completer();

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

      /// We wait for the [Completer] (which should complete
      /// once we are done with the auth part - either positive
      /// or negative) ot return a timeout response to handle
      this.connectionClodeCode = await Future.any([
        authCompleter.future,
        Future.delayed(
          timeout,
          () => WebSocketCloseCode.UnknownReason,
        )
      ]);

      subscription.cancel();

      if (!reconnect) {
        if (this.connectionClodeCode != WebSocketCloseCode.DontClose) {
          this.activeSession!.socket.sink.close();
          this.activeSession = null;
        } else {
          this.handleStream();
        }
      }
    } catch (e) {
      GeneralHelper.advLog(
        'Not possible to connect to ${connection.host}${connection.port != null ? (":" + connection.port.toString()) : ""}: $e',
        level: LogLevel.Error,
        includeInLogs: true,
      );

      this.connectionClodeCode =
          await Future.delayed(timeout, () => WebSocketCloseCode.UnknownReason);
    }

    this.connectionInProgress = false;
    return this.connectionClodeCode!;
  }

  @action
  void closeSession({bool manually = true}) {
    this.obsTerminated = !manually;
    if (this.activeSession != null) {
      this.activeSession!.socket.sink.close();
      this.activeSession = null;
      this.connectionClodeCode = null;
    }
  }

  @action
  void _handleEvent(BaseEvent event) {
    switch (event.eventType) {
      case EventType.ExitStarted:
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

          _handleNewProtocol(connection, authCompleter, jsonObject);
        },
        onDone: () {
          GeneralHelper.advLog(
            'Initial WebSocket connection done, close code: ${this.activeSession!.socket.closeCode}, {WebSocketCloseCode.values.firstWhere((closeCode) => closeCode.identifier == this.activeSession!.socket.closeCode, orElse: () => WebSocketCloseCode.UnknownReason).message}',
          );

          authCompleter.complete(
            WebSocketCloseCode.values.firstWhere(
                (closeCode) =>
                    closeCode.identifier ==
                    this.activeSession!.socket.closeCode,
                orElse: () => WebSocketCloseCode.UnknownReason),
          );
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
    /// OBS WebSocket answered with OP Hello - happens after initially connecting
    /// with the WebSocket
    if (json['op'] == WebSocketOpCode.Hello.identifier) {
      /// If authentication key is present, the WebSocket is password protected. We
      /// will set the challenge and salt value in the [Connection] object inside
      /// our [activeSession] which will be used in the [AuthenticationHelper.identify]
      /// function
      if (json['d']['authentication'] != null) {
        connection.challenge = json['d']['authentication']['challenge'];
        connection.salt = json['d']['authentication']['salt'];
      }

      /// Send out the Identify OP
      AuthenticationHelper.identify(activeSession!);

      /// OBS Websocket answered with OP Identified - means we were able to
      /// correctly identify against the plugin, conneciton was successfull and
      /// we can exchange messages now
    } else if (json['op'] == WebSocketOpCode.Identified.identifier) {
      authCompleter.complete(WebSocketCloseCode.DontClose);
    }
  }

  Stream<Message> watchOBSStream() async* {
    try {
      await for (final event in this.activeSession!.socketStream!) {
        Map<String, dynamic> fullJSON = json.decode(event);
        if (fullJSON['op'] == WebSocketOpCode.Event.identifier) {
          yield BaseEvent(fullJSON);
        } else if (fullJSON['op'] ==
            WebSocketOpCode.RequestResponse.identifier) {
          yield BaseResponse(fullJSON);
        } else if (fullJSON['op'] ==
            WebSocketOpCode.RequestBatchResponse.identifier) {
          yield BaseBatchResponse(fullJSON);
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
