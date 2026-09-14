import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/types/enums/request_batch_type.dart';
import 'package:obs_blade/types/enums/web_socket_codes/request_batch_execution_type.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_op_code.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';

import '../models/connection.dart';
import '../models/enums/log_level.dart';
import '../types/classes/obs_request_ack.dart';
import '../types/classes/stream/batch_responses/base.dart';
import '../types/classes/stream/responses/base.dart';
import '../types/enums/request_type.dart';
import '../types/exceptions/network.dart';
import 'general_helper.dart';

/// Class which represents the result of a connection scan. Scans will create
/// [Connection] objects which will be wrapped with this class to also include
/// an optional error to handle after receiving the results
class ConnectionScan {
  Connection connection;
  Object? error;

  ConnectionScan(this.connection, [this.error]);
}

class RequestBatchObject {
  String uuid;
  RequestType type;
  Map<String, dynamic>? body;

  RequestBatchObject(this.type, [this.body]) : uuid = const Uuid().v4();
}

/// A request which has been sent and is waiting for its ack (RequestResponse)
/// from OBS - see [NetworkHelper.makeRequest]
class _PendingRequestAck {
  final RequestType? requestType;
  final Completer<ObsRequestAck> completer = Completer();
  Timer? timeoutTimer;

  _PendingRequestAck(this.requestType);
}

/// Batch equivalent of [_PendingRequestAck]
class _PendingBatchAck {
  final Completer<ObsBatchAck> completer = Completer();
  Timer? timeoutTimer;
}

class NetworkHelper {
  static Map<String, Map<String, dynamic>?> _requestBodyByUUID = {};
  static Map<String, List<RequestBatchObject>> _requestBatchByUUID = {};
  static Map<String, _PendingRequestAck> _pendingRequestByUUID = {};
  static Map<String, _PendingBatchAck> _pendingBatchByUUID = {};

  /// How long an acked request ([makeRequest] / [makeBatchRequest]) waits
  /// for OBS to answer before it counts as failed (hard timeout). Generous
  /// on purpose - slow-but-eventually-successful acks must not surface as
  /// failures. Tests lower this to keep the suite fast.
  static Duration requestAckTimeout = const Duration(seconds: 10);

  /// Amount of request / batch acks still waiting for an answer - test hook
  /// to assert pending-map hygiene (late acks, timeouts, disconnects must
  /// not leak entries)
  static int get pendingAckCount =>
      _pendingRequestByUUID.length + _pendingBatchByUUID.length;

  /// Establish and return an instance of [IOWebSocketChannel] based on the
  /// information inside a connection (IP and port). Currently using a
  /// [pingInterval] of 3 seconds which will check if the WebSocket connection
  /// is still alive in a 3 seconds interval - this will result in being able
  /// to check for [closeStatus] or [closeResult] whether the connection is
  /// alive or not. Mainly used in [DashboardStore] where a [Timer] is periodically
  /// checking this to be able to reconnect if possible or navigate back to
  /// [HomeView] otherwise.
  ///
  /// [connectTimeout] bounds the TCP/WebSocket upgrade. The channel is returned
  /// immediately; await [IOWebSocketChannel.ready] (and treat failure as
  /// unreachable) before assuming the peer is OBS.
  static IOWebSocketChannel establishWebSocket(
    Connection connection, {
    Duration pingInterval = const Duration(seconds: 3),
    Duration? connectTimeout,
  }) {
    NetworkHelper._requestBodyByUUID = {};
    NetworkHelper._requestBatchByUUID = {};

    /// A new socket means the previous one (if any) is gone - requests still
    /// waiting for their ack on it will never be answered
    NetworkHelper.failAllPendingAcks();

    return IOWebSocketChannel.connect(
      NetworkHelper.websocketUri(connection),
      pingInterval: pingInterval,
      connectTimeout: connectTimeout,
    );
  }

  /// Builds a WebSocket [Uri] for OBS.
  ///
  /// - Plain IP / hostname (typical LAN): `ws://host:port` (default port 4455).
  /// - Domain mode may store a scheme in [Connection.host] (`ws://…` / `wss://…`);
  ///   that scheme is kept and [Connection.port] is applied when set.
  static Uri websocketUri(Connection connection) {
    final rawHost = connection.host.trim();
    final port = connection.port;

    if (rawHost.contains('://')) {
      final parsed = Uri.parse(rawHost);
      if (port != null && port > 0) {
        return parsed.replace(port: port);
      }
      return parsed;
    }

    return Uri(scheme: 'ws', host: rawHost, port: port ?? 4455);
  }

  /// Initiating an autodiscover process with an isolate function to make this
  /// kind of resource hungry operation threaded. Basically initiating a [Socket]
  /// connection to each IP in the corresponding IP range and see if timeout
  /// is triggered (therefore [SocketException] is thrown) or if not, there is
  /// an application (most likely OBS in this case) which listens on this port
  static Future<List<Connection>> getAvailableOBSIPs(int port) async {
    if ((await Connectivity().checkConnectivity()).contains(
      ConnectivityResult.wifi,
    )) {
      NetworkStore networkStore = GetIt.instance<NetworkStore>();
      NetworkInfo info = NetworkInfo();
      networkStore.ip = await info.getWifiIP();

      GeneralHelper.advLog('Autodiscover base IP: ${networkStore.ip}');

      /// Check if the subnet mask is non "default" since it will
      /// change the amount of possible clients and the general client
      /// ip address range. 255.255.0.0 would already lead to roughly
      /// 65k ip address to check which is not feasable. We set
      /// [nonDefaultSubnetMask] which will indicate that we actually
      /// have a case of non default subnet mask for this autodiscover
      /// process so I can adjust the information to the user
      networkStore.subnetMask = await info.getWifiSubmask();
      networkStore.nonDefaultSubnetMask =
          networkStore.subnetMask != '255.255.255.0';

      if (networkStore.ip != null) {
        /// Completer used to manully deal with Future. [Completer] enables us to
        /// call the [complete] funciton which will finalise the Future of
        /// [Completer.future] so we can await this
        Completer<List<ConnectionScan?>> completer = Completer();
        ReceivePort receivePort = ReceivePort();

        /// "Spawning" the [Isolate] (thread) to deal with multiple [Socket]
        /// connection tries.
        Isolate.spawn<Map<String, dynamic>>(_isolateFullScanIPs, {
          'sendPort': receivePort.sendPort,
          'ip': networkStore.ip,
          'port': port,
          'timeout': const Duration(milliseconds: 5000),
        });

        receivePort.listen((availableConnections) {
          receivePort.close();
          completer.complete(availableConnections);
        });

        return List.from(
          (await completer.future)
              .where(
                (connectionScan) =>
                    connectionScan != null && connectionScan.error == null,
              )
              .map((connectionScan) => connectionScan!.connection),
        );
      }
      throw NoNetworkException();
    }
    throw NotInWLANException();
  }

  static Future<List<Connection>> checkConnectionAvailabilities(
    List<Connection> connections,
  ) async {
    Completer<List<ConnectionScan?>> completer = Completer();
    ReceivePort receivePort = ReceivePort();

    Isolate.spawn<Map<String, dynamic>>(_isolateFullScanConnections, {
      'sendPort': receivePort.sendPort,
      'hosts': connections.map((connection) => connection.host).toList(),
      'ports': connections.map((connection) => connection.port).toList(),
      'isDomains': connections
          .map((connection) => connection.isDomain)
          .toList(),
      'timeout': const Duration(milliseconds: 5000),
    });

    receivePort.listen((availableConnections) {
      receivePort.close();
      completer.complete(availableConnections);
    });

    List<ConnectionScan> connectionScans = List.from(
      (await completer.future).where(
        (connectionScan) => connectionScan != null,
      ),
    );

    connectionScans
        .where((connectionScan) => connectionScan.error != null)
        .forEach(
          (connectionScan) => GeneralHelper.advLog(
            'Reachable check for your saved connection ${connectionScan.connection.host}${connectionScan.connection.port != null ? (":${connectionScan.connection.port}") : ""} failed: ${connectionScan.error}',
            level: LogLevel.Error,
            includeInLogs: true,
          ),
        );

    return List.from(
      connectionScans
          .where((connectionScan) => connectionScan.error == null)
          .map((connectionScan) => connectionScan.connection),
    );
  }

  static void _isolateFullScanIPs(Map<String, dynamic> arguments) async {
    SendPort sendPort = arguments['sendPort'];
    String ip = arguments['ip'];
    int port = arguments['port'];
    Duration timeout = arguments['timeout'];

    List<Future<ConnectionScan?>> availableConnections = [];
    String cutIP = (ip.split('.')..removeLast()).join('.');

    for (int k = 0; k < 256; k++) {
      availableConnections.add(
        _singleScan({
          'address': '$cutIP.${k.toString()}',
          'port': port,
          'timeout': timeout,
        }),
      );
    }

    /// It's important to start and collect all scans (which return a [Future]
    /// in a list and then make use of [Future.wait] so all those scans
    /// run in parallel and we just wait until all are finished. Otherwise it
    /// will run in sequence and it will take approximately:
    ///
    ///   (amount available IP's) * (timeout duration)
    ///
    /// until the scan is done - way too long. In (kinda) parallel, even though more
    /// resource hungry (thats why it's in an [Isolate]), it will be finished around
    /// timeout duration!
    sendPort.send(await Future.wait(availableConnections));
  }

  static void _isolateFullScanConnections(
    Map<String, dynamic> arguments,
  ) async {
    SendPort sendPort = arguments['sendPort'];
    List<String> hosts = List.from(arguments['hosts']);
    List<int?> ports = List.from(arguments['ports']);
    List<bool?> isDomains = List.from(arguments['isDomains']);
    Duration timeout = arguments['timeout'];

    List<Future<ConnectionScan?>> availableConnections = [];

    for (int i = 0; i < hosts.length; i++) {
      availableConnections.add(
        _singleScan({
          'address': hosts[i],
          'port': ports[i],
          'isDomain': isDomains[i],
          'timeout': timeout,
        }),
      );
    }

    sendPort.send(await Future.wait(availableConnections));
  }

  static Future<ConnectionScan?> _singleScan(
    Map<String, dynamic> arguments,
  ) async {
    String address = arguments['address'];
    int? port = arguments['port'];
    bool? isDomain = arguments['isDomain'];
    ConnectionScan connectionScan = ConnectionScan(
      Connection(address, port, null, isDomain),
    );
    Duration timeout = arguments['timeout'];
    SendPort? sendPort = arguments['sendPort'];

    if (isDomain == null || !isDomain) {
      Socket? socket;
      try {
        /// We try to establish a [Socket] connection for every IP of
        /// available IP ranges for the device. If an attempt hits the timeout,
        /// an exception is thrown and the IP address tested is not added
        /// to the list. If no timeout and therefore exception occurs, it means
        /// that there is a device listeneing on the IP:port combination (in this
        /// case very likely OBS WebSocket) and we will add it to the list
        socket = await Socket.connect(address, port ?? 4455, timeout: timeout);
        sendPort?.send(connectionScan);
        socket.destroy();
        return connectionScan;
      } catch (e) {
        // An exception means timeout which is okay
      } finally {
        socket?.destroy();
      }
      sendPort?.send(null);
      return null;
    }

    try {
      IOWebSocketChannel channel = NetworkHelper.establishWebSocket(
        connectionScan.connection,
        pingInterval: const Duration(milliseconds: 500),
        connectTimeout: timeout,
      );

      int? res = await Future.delayed(timeout, () => channel.closeCode);

      channel.sink.close();

      if (res != null) {
        sendPort?.send(connectionScan);
        return connectionScan;
      }
    } catch (e) {
      connectionScan.error = e;

      sendPort?.send(connectionScan);
      return connectionScan;
    }

    sendPort?.send(null);
    return null;
  }

  static Map<String, dynamic>? getRequestBodyForUUID(String uuid) =>
      NetworkHelper._requestBodyByUUID.remove(uuid);

  static Iterable<RequestBatchObject>? getRequestBatchBodyForUUID(
    String uuid,
  ) => NetworkHelper._requestBatchByUUID.remove(uuid);

  /// Making a request to the OBS WebSocket to trigger a request being
  /// sent back through the stream so we every listener can act accordingly
  ///
  /// Returns the ack of the request (command-ack layer): the returned
  /// [Future] completes once OBS answers - with a rejection when
  /// `requestStatus.result` is false, with [ObsRequestFailureKind.timeout]
  /// after [requestAckTimeout] and with [ObsRequestFailureKind.connectionLost]
  /// when the connection drops first. Callers which don't care (polling
  /// reads, slider ticks, ...) can keep ignoring the result - fire-and-forget
  /// keeps working unchanged.
  static Future<ObsRequestAck> makeRequest(
    IOWebSocketChannel channel,
    RequestType request, [
    Map<String, dynamic>? fields,
    bool customContent = false,
  ]) {
    if (request != RequestType.GetSourceScreenshot) {
      GeneralHelper.advLog('Outgoing: $request');
    }

    String requestUUID = const Uuid().v4();

    /// If we send a request which has fields, we want to
    /// be able to know, once we receive the response, what
    /// information we sent initially (like input name etc.) since
    /// in the new protocol (>= 5.X) we don't get this information
    /// in the response anymore
    if (!customContent && fields != null && request.name.startsWith('Get')) {
      NetworkHelper._requestBodyByUUID[requestUUID] = fields;
    }

    final pending = _trackRequestAck(requestUUID, request);

    try {
      channel.sink.add(
        json.encode(
          _requestObject(
            customContent
                ? fields!
                : {
                    'requestType': request.name,
                    'requestId': requestUUID,
                    'requestData': {if (fields != null) ...fields},
                  },
          ),
        ),
      );
    } catch (e) {
      _completeAckOnSendFailure(
        requestUUID,
        pending,
        ObsRequestAck.connectionLost(request),
      );
    }

    return pending.completer.future;
  }

  /// Making use of the batch request capability to request information
  /// bundled together - useful since now the API divided information
  /// in several entities so we can choose what exactly we need
  ///
  /// Same ack semantics as [makeRequest]: the returned [Future] carries the
  /// per-request statuses of the batch (v5 batches answer with one status
  /// per entry) once OBS responds.
  static Future<ObsBatchAck> makeBatchRequest(
    IOWebSocketChannel channel,
    RequestBatchType batchRequest,
    List<RequestBatchObject> batch,
  ) {
    if (batchRequest != RequestBatchType.Stats) {
      GeneralHelper.advLog('Outgoing Batch: $batchRequest');
    }

    String requestUUID = const Uuid().v4();

    if (batchRequest.lookup) {
      NetworkHelper._requestBatchByUUID[requestUUID] = batch;
    }

    final pending = _trackBatchAck(requestUUID);

    try {
      channel.sink.add(json.encode(_requestBatchObject(requestUUID, batch)));
    } catch (e) {
      _completeAckOnSendFailure(
        requestUUID,
        pending,
        const ObsBatchAck.connectionLost(),
      );
    }

    return pending.completer.future;
  }

  static _PendingRequestAck _trackRequestAck(
    String requestUUID,
    RequestType? requestType,
  ) {
    final pending = _PendingRequestAck(requestType);
    NetworkHelper._pendingRequestByUUID[requestUUID] = pending;
    pending.timeoutTimer = Timer(NetworkHelper.requestAckTimeout, () {
      if (NetworkHelper._pendingRequestByUUID.remove(requestUUID) == null ||
          pending.completer.isCompleted) {
        return;
      }
      GeneralHelper.advLog(
        'Request timed out waiting for ack: $requestType',
        level: LogLevel.Warning,
        includeInLogs: true,
      );
      pending.completer.complete(ObsRequestAck.timeout(requestType));
    });
    return pending;
  }

  static _PendingBatchAck _trackBatchAck(String requestUUID) {
    final pending = _PendingBatchAck();
    NetworkHelper._pendingBatchByUUID[requestUUID] = pending;
    pending.timeoutTimer = Timer(NetworkHelper.requestAckTimeout, () {
      if (NetworkHelper._pendingBatchByUUID.remove(requestUUID) == null ||
          pending.completer.isCompleted) {
        return;
      }
      GeneralHelper.advLog(
        'Batch request timed out waiting for ack',
        level: LogLevel.Warning,
        includeInLogs: true,
      );
      pending.completer.complete(const ObsBatchAck.timeout());
    });
    return pending;
  }

  static void _completeAckOnSendFailure(
    String requestUUID,
    Object pending,
    Object ack,
  ) {
    if (pending is _PendingRequestAck) {
      if (NetworkHelper._pendingRequestByUUID.remove(requestUUID) == null) {
        return;
      }
      pending.timeoutTimer?.cancel();
      if (!pending.completer.isCompleted) {
        pending.completer.complete(ack as ObsRequestAck);
      }
    } else if (pending is _PendingBatchAck) {
      if (NetworkHelper._pendingBatchByUUID.remove(requestUUID) == null) {
        return;
      }
      pending.timeoutTimer?.cancel();
      if (!pending.completer.isCompleted) {
        pending.completer.complete(ack as ObsBatchAck);
      }
    }
  }

  /// Completes the pending ack for [response] - called by the central
  /// response dispatch for **every** RequestResponse, including error
  /// statuses. Unknown request ids (late acks for timed out requests,
  /// responses to requests sent before a reconnect) are dropped, never
  /// misrouted.
  static void completeRequestAck(BaseResponse response) {
    final pending = NetworkHelper._pendingRequestByUUID.remove(response.uuid);
    if (pending == null || pending.completer.isCompleted) return;

    pending.timeoutTimer?.cancel();

    final status = response.status;
    pending.completer.complete(
      status.result
          ? ObsRequestAck.success(pending.requestType)
          : ObsRequestAck.rejected(
              pending.requestType,
              status.code,
              status.comment,
            ),
    );
  }

  /// Batch equivalent of [completeRequestAck] - surfaces the per-request
  /// statuses the v5 batch response carries.
  static void completeBatchRequestAck(BaseBatchResponse batchResponse) {
    final pending = NetworkHelper._pendingBatchByUUID.remove(
      batchResponse.uuid,
    );
    if (pending == null || pending.completer.isCompleted) return;

    pending.timeoutTimer?.cancel();

    pending.completer.complete(
      ObsBatchAck(
        results: batchResponse.responses.map((response) {
          final status = response.status;
          RequestType? requestType;
          try {
            requestType = response.requestType;
          } catch (_) {
            /// Unknown request types (newer OBS API) must not break the ack
          }
          return status.result
              ? ObsRequestAck.success(requestType)
              : ObsRequestAck.rejected(
                  requestType,
                  status.code,
                  status.comment,
                );
        }).toList(),
      ),
    );
  }

  /// Fails every pending request / batch ack at once - called when the
  /// connection drops or the session is closed so awaiting callers resolve
  /// with [ObsRequestFailureKind.connectionLost] instead of hanging until
  /// their timeout. Awaiting call sites aggregate this into a single notice.
  static void failAllPendingAcks() {
    final pendingRequests = NetworkHelper._pendingRequestByUUID.values.toList();
    final pendingBatches = NetworkHelper._pendingBatchByUUID.values.toList();
    NetworkHelper._pendingRequestByUUID = {};
    NetworkHelper._pendingBatchByUUID = {};

    for (final pending in pendingRequests) {
      pending.timeoutTimer?.cancel();
      if (!pending.completer.isCompleted) {
        pending.completer.complete(
          ObsRequestAck.connectionLost(pending.requestType),
        );
      }
    }
    for (final pending in pendingBatches) {
      pending.timeoutTimer?.cancel();
      if (!pending.completer.isCompleted) {
        pending.completer.complete(const ObsBatchAck.connectionLost());
      }
    }

    if (pendingRequests.isNotEmpty || pendingBatches.isNotEmpty) {
      GeneralHelper.advLog(
        'Connection lost - failing ${pendingRequests.length + pendingBatches.length} pending request(s)',
        level: LogLevel.Warning,
        includeInLogs: true,
      );
    }
  }

  static Map<String, dynamic> _requestObject(
    Map<String, dynamic> body, [
    WebSocketOpCode op = WebSocketOpCode.Request,
  ]) => {'op': op.identifier, 'd': body};

  static Map<String, dynamic> _requestBatchObject(
    String uuid,
    Iterable<RequestBatchObject> batch, [
    bool haltOnFailure = false,
    RequestBatchExecutionType executionType =
        RequestBatchExecutionType.SerialRealtime,
  ]) => {
    'op': WebSocketOpCode.RequestBatch.identifier,
    'd': {
      'requestId': uuid,
      'haltOnFailure': haltOnFailure,
      'executionType': executionType.identifier,
      'requests': batch
          .map(
            (batchEntry) => _requestObject({
              'requestType': batchEntry.type.name,
              'requestId': batchEntry.uuid,
              'requestData': batchEntry.body,
            })['d'],
          )
          .toList(),
    },
  };
}
