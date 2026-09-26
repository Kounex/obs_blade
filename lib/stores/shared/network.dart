import 'dart:async';
import 'dart:convert';

import 'package:mobx/mobx.dart';
import 'package:obs_blade/types/classes/connection_attempt_result.dart';
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

/// Default client-side handshake budget (Hello → Identified).
const Duration kObsHandshakeTimeout = Duration(seconds: 10);

class NetworkStore = _NetworkStore with _$NetworkStore;

abstract class _NetworkStore with Store {
  @observable
  Session? activeSession;
  @observable
  bool connectionInProgress = false;
  @observable
  WebSocketCloseCode? connectionClodeCode;

  @observable
  ConnectionAttemptResult? lastConnectionResult;

  @observable
  bool obsTerminated = false;

  /// Used as part of the autodiscovery process and will only be set when used.
  /// If we want to know more about an active connection, use [activeSession].
  String? ip;
  String? subnetMask;
  bool nonDefaultSubnetMask = false;

  StreamSubscription? _authSubscription;
  StreamSubscription? _messagePumpSubscription;
  ConnectionStage _handshakeStage = ConnectionStage.connecting;

  /// Connects (or reconnects) to OBS. The new socket is only published as
  /// [activeSession] once OBS answered Identified - until then nothing else
  /// can send on it (OBS closes a socket with 4007 NotIdentified when any
  /// non-Identify message arrives first). On a failed reconnect the previous
  /// (dead) session stays in place so the reconnect loop keeps its target.
  @action
  Future<WebSocketCloseCode> setOBSWebSocket(
    Connection connection, {
    bool reconnect = false,
    Duration timeout = kObsHandshakeTimeout,
  }) async {
    if (!reconnect) {
      this.closeSession();
    } else {
      await _cancelAuthSubscription();
      await _cancelMessagePump();
    }

    this.connectionClodeCode = null;
    this.lastConnectionResult = null;
    this.connectionInProgress = true;
    _handshakeStage = ConnectionStage.connecting;

    Session? session;

    try {
      final authCompleter = Completer<ConnectionAttemptResult>();
      final startedAt = DateTime.now();

      session = Session(
        NetworkHelper.establishWebSocket(connection, connectTimeout: timeout),
        connection,
      );

      session.socketStream = session.socket.stream.asBroadcastStream();

      GeneralHelper.advLog(
        'Handshake: connecting to ${connection.host}'
        '${connection.port != null ? ":${connection.port}" : ""}',
        includeInLogs: true,
      );

      // TCP/WS upgrade — stay on [connecting] until ready so unreachable
      // hosts don't get the "did not greet" message.
      try {
        await session.socket.ready;
      } catch (e) {
        GeneralHelper.advLog(
          'Handshake: could not open WebSocket | $e',
          level: LogLevel.Error,
          includeInLogs: true,
        );
        this.lastConnectionResult = ConnectionAttemptResult(
          closeCode: WebSocketCloseCode.HandshakeTimeout,
          stage: ConnectionStage.connecting,
          detail: e.toString(),
        );
        this.connectionClodeCode = this.lastConnectionResult!.closeCode;
        session.socket.sink.close();
        this.connectionInProgress = false;
        return this.connectionClodeCode!;
      }

      _handshakeStage = ConnectionStage.waitingHello;
      _authSubscription = _handleInitialWebSocket(session, authCompleter);

      GeneralHelper.advLog(
        'Handshake: waiting Hello for ${connection.host}'
        '${connection.port != null ? ":${connection.port}" : ""}',
        includeInLogs: true,
      );

      final remaining = timeout - DateTime.now().difference(startedAt);
      final helloBudget = remaining.isNegative ? Duration.zero : remaining;

      this.lastConnectionResult = await Future.any([
        authCompleter.future,
        Future.delayed(
          helloBudget,
          () => ConnectionAttemptResult(
            closeCode: WebSocketCloseCode.HandshakeTimeout,
            stage: _handshakeStage,
            detail: 'Timed out at $_handshakeStage',
          ),
        ),
      ]);

      await _cancelAuthSubscription();

      this.connectionClodeCode = this.lastConnectionResult!.closeCode;

      GeneralHelper.advLog(
        'Handshake result: ${this.lastConnectionResult}',
        level: this.lastConnectionResult!.isSuccess
            ? LogLevel.Info
            : LogLevel.Warning,
        includeInLogs: true,
      );

      if (this.connectionClodeCode != WebSocketCloseCode.DontClose) {
        session.socket.sink.close();
      } else {
        // Fresh connect or reconnect: publish the identified session and
        // own the message pump once.
        this.activeSession = session;
        this.handleStream();
      }
    } catch (e) {
      GeneralHelper.advLog(
        'Not possible to connect to ${connection.host}'
        '${connection.port != null ? (":${connection.port}") : ""}: $e',
        level: LogLevel.Error,
        includeInLogs: true,
      );

      this.lastConnectionResult = ConnectionAttemptResult(
        closeCode: WebSocketCloseCode.UnknownReason,
        stage: _handshakeStage,
        detail: e.toString(),
      );
      this.connectionClodeCode = WebSocketCloseCode.UnknownReason;
      session?.socket.sink.close();
    }

    this.connectionInProgress = false;
    return this.connectionClodeCode!;
  }

  @action
  void closeSession({bool manually = true}) {
    this.obsTerminated = !manually;
    _cancelAuthSubscription();
    _cancelMessagePump();
    NetworkHelper.failAllPendingAcks();
    if (this.activeSession != null) {
      this.activeSession!.socket.sink.close();
      this.activeSession = null;
      this.connectionClodeCode = null;
    }
  }

  Future<void> _cancelAuthSubscription() async {
    await _authSubscription?.cancel();
    _authSubscription = null;
  }

  Future<void> _cancelMessagePump() async {
    await _messagePumpSubscription?.cancel();
    _messagePumpSubscription = null;
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

  void _completeAuth(
    Completer<ConnectionAttemptResult> authCompleter,
    ConnectionAttemptResult result,
  ) {
    if (!authCompleter.isCompleted) {
      authCompleter.complete(result);
    }
  }

  StreamSubscription _handleInitialWebSocket(
    Session session,
    Completer<ConnectionAttemptResult> authCompleter,
  ) => session.socketStream!.listen(
    (event) {
      try {
        final jsonObject = json.decode(event) as Map<String, dynamic>;
        _handleNewProtocol(session, authCompleter, jsonObject);
      } catch (e) {
        GeneralHelper.advLog(
          'Handshake decode error: $e',
          level: LogLevel.Error,
          includeInLogs: true,
        );
        _completeAuth(
          authCompleter,
          ConnectionAttemptResult(
            closeCode: WebSocketCloseCode.MessageDecodeError,
            stage: _handshakeStage,
            detail: e.toString(),
          ),
        );
      }
    },
    onDone: () {
      final closeCode = WebSocketCloseCode.fromIdentifier(
        session.socket.closeCode,
      );
      GeneralHelper.advLog(
        'Initial WebSocket done, close code: '
        '${session.socket.closeCode} (${closeCode.message})',
        includeInLogs: true,
      );

      _completeAuth(
        authCompleter,
        ConnectionAttemptResult(
          closeCode: closeCode,
          stage: _handshakeStage,
          detail: session.socket.closeReason,
        ),
      );
    },
    onError: (error) {
      GeneralHelper.advLog(
        'Error initial WebSocket connection | $error',
        level: LogLevel.Error,
        includeInLogs: true,
      );
      _completeAuth(
        authCompleter,
        ConnectionAttemptResult(
          closeCode: WebSocketCloseCode.UnknownReason,
          stage: _handshakeStage,
          detail: error.toString(),
        ),
      );
    },
  );

  void _handleNewProtocol(
    Session session,
    Completer<ConnectionAttemptResult> authCompleter,
    Map<String, dynamic> json,
  ) {
    final connection = session.connection;
    if (json['op'] == WebSocketOpCode.Hello.identifier) {
      final d = json['d'] as Map<String, dynamic>? ?? {};
      final auth = d['authentication'];

      connection.challenge = null;
      connection.salt = null;

      if (auth is Map) {
        connection.challenge = auth['challenge'] as String?;
        connection.salt = auth['salt'] as String?;
      }

      final rpcVersion = (d['rpcVersion'] as num?)?.toInt() ?? 1;
      GeneralHelper.advLog(
        'Handshake: Hello obsWebSocketVersion='
        '${d['obsWebSocketVersion']} rpcVersion=$rpcVersion '
        'authRequired=${auth != null}',
        includeInLogs: true,
      );

      _handshakeStage = ConnectionStage.waitingIdentified;
      AuthenticationHelper.identify(session, rpcVersion: rpcVersion);
    } else if (json['op'] == WebSocketOpCode.Identified.identifier) {
      _handshakeStage = ConnectionStage.identified;
      _completeAuth(authCompleter, ConnectionAttemptResult.success);
    }
  }

  /// Yields protocol messages for the active session without owning/closing
  /// the socket. Prefer [handleStream] / dashboard listen via this stream.
  ///
  /// Also the central response dispatch for the command-ack layer: every
  /// (batch) response completes its pending ack here, before listeners get
  /// the message - including error statuses; late acks for timed out
  /// requests are dropped inside the completion calls.
  Stream<Message> watchOBSStream() async* {
    final stream = this.activeSession?.socketStream;
    if (stream == null) return;

    await for (final event in stream) {
      final fullJSON = json.decode(event) as Map<String, dynamic>;
      final op = fullJSON['op'];
      if (op == WebSocketOpCode.Event.identifier) {
        yield BaseEvent(fullJSON);
      } else if (op == WebSocketOpCode.RequestResponse.identifier) {
        final response = BaseResponse(fullJSON);
        NetworkHelper.completeRequestAck(response);
        yield response;
      } else if (op == WebSocketOpCode.RequestBatchResponse.identifier) {
        final batchResponse = BaseBatchResponse(fullJSON);
        NetworkHelper.completeBatchRequestAck(batchResponse);
        yield batchResponse;
      }
    }
  }

  /// NetworkStore-owned pump for session-level events (e.g. ExitStarted).
  /// Cancels any previous pump first so reconnect does not stack listeners.
  ///
  /// [onDone]: the socket dropped - fail all pending acks at once so
  /// awaiting callers resolve (aggregated surfacing) instead of timing out.
  void handleStream() {
    _cancelMessagePump();
    _messagePumpSubscription = this.watchOBSStream().listen((message) {
      if (message is BaseEvent) {
        _handleEvent(message);
      }
    }, onDone: () => NetworkHelper.failAllPendingAcks());
  }
}
