import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:obs_blade/models/connection.dart';

/// Loopback fake OBS WebSocket v5 peer for command-ack protocol tests.
///
/// Speaks just enough of the real handshake (Hello → Identify → Identified)
/// for [NetworkStore.setOBSWebSocket] to connect, then answers Request (op 6)
/// and RequestBatch (op 8) messages with deterministic behaviour:
///
/// - default: immediate success ack (optional [responseData] per type)
/// - [rejections]: explicit `result: false` ack with a code/comment
/// - [droppedRequestTypes]: the ack is never sent (client must time out)
/// - [ackDelay]: postpone every ack (late-ack / slow-peer scenarios)
/// - [closeSockets]: kill the connection mid-flight (disconnect scenarios)
///
/// Everything the client sent is recorded in [requests] / [batches] so tests
/// can assert on re-reads (e.g. the matching `Get*` after a failed mutation).
class FakeObsPeer {
  FakeObsPeer._(this._server) {
    _server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      sockets.add(socket);
      socket.add(
        jsonEncode({
          'op': 0,
          'd': {'obsWebSocketVersion': '5.5.2', 'rpcVersion': 1},
        }),
      );
      socket.listen(
        (raw) => _handlePacket(socket, jsonDecode(raw as String)),
        onDone: () => sockets.remove(socket),
      );
    });
  }

  final HttpServer _server;
  final List<WebSocket> sockets = [];

  /// Every Request `d` payload the client sent (in arrival order)
  final List<Map<String, dynamic>> requests = [];

  /// Every RequestBatch `d` payload the client sent (in arrival order)
  final List<Map<String, dynamic>> batches = [];

  /// requestType → status code to reject with (comment: [rejectionComment])
  final Map<String, int> rejections = {};

  /// requestTypes whose ack is never sent
  final Set<String> droppedRequestTypes = {};

  /// Optional delay applied before any ack is sent
  Duration? ackDelay;

  /// requestType → responseData merged into the success ack
  final Map<String, Map<String, dynamic>> responseData = {};

  /// When false, Identify is never answered (handshake stall scenarios)
  bool identify = true;

  String rejectionComment = 'synthetic rejection';

  static Future<FakeObsPeer> start() async =>
      FakeObsPeer._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  Connection get connection => Connection('localhost', _server.port);

  int get port => _server.port;

  void _handlePacket(WebSocket socket, Map<String, dynamic> packet) {
    switch (packet['op']) {
      case 1: // Identify
        if (identify) {
          socket.add(
            jsonEncode({
              'op': 2,
              'd': {'negotiatedRpcVersion': 1},
            }),
          );
        }
        break;
      case 6: // Request
        final data = packet['d'] as Map<String, dynamic>;
        requests.add(data);
        _ackRequest(socket, data);
        break;
      case 8: // RequestBatch
        final data = packet['d'] as Map<String, dynamic>;
        batches.add(data);
        _ackBatch(socket, data);
        break;
    }
  }

  Future<void> _ackRequest(WebSocket socket, Map<String, dynamic> data) async {
    final type = data['requestType'] as String;
    if (droppedRequestTypes.contains(type)) return;
    if (ackDelay != null) await Future<void>.delayed(ackDelay!);
    if (socket.closeCode != null) return;

    final rejectionCode = rejections[type];
    _safeAdd(
      socket,
      jsonEncode({
        'op': 7,
        'd': {
          'requestType': type,
          'requestId': data['requestId'],
          'requestStatus': rejectionCode != null
              ? {
                  'result': false,
                  'code': rejectionCode,
                  'comment': rejectionComment,
                }
              : {'result': true, 'code': 100},
          'responseData': responseData[type] ?? <String, dynamic>{},
        },
      }),
    );
  }

  /// Adding races with teardown closes - a dead peer socket must never fail
  /// the test with an unhandled error
  void _safeAdd(WebSocket socket, String payload) {
    try {
      socket.add(payload);
    } catch (_) {}
  }

  Future<void> _ackBatch(WebSocket socket, Map<String, dynamic> data) async {
    final batchRequests = List<Map<String, dynamic>>.from(
      data['requests'] as List,
    );
    if (batchRequests.any(
      (entry) => droppedRequestTypes.contains(entry['requestType']),
    )) {
      return;
    }
    if (ackDelay != null) await Future<void>.delayed(ackDelay!);
    if (socket.closeCode != null) return;

    _safeAdd(
      socket,
      jsonEncode({
        'op': 9,
        'd': {
          'requestId': data['requestId'],
          'results': [
            for (final entry in batchRequests)
              {
                'requestType': entry['requestType'],
                'requestId': entry['requestId'],
                'requestStatus':
                    rejections[entry['requestType'] as String] != null
                    ? {
                        'result': false,
                        'code': rejections[entry['requestType'] as String],
                        'comment': rejectionComment,
                      }
                    : {'result': true, 'code': 100},
                'responseData':
                    responseData[entry['requestType'] as String] ??
                    <String, dynamic>{},
              },
          ],
        },
      }),
    );
  }

  /// Emits an event (op 5) to every connected socket
  void event(String eventType, Map<String, dynamic> eventData) {
    for (final socket in sockets) {
      _safeAdd(
        socket,
        jsonEncode({
          'op': 5,
          'd': {
            'eventType': eventType,
            'eventIntent': 0,
            'eventData': eventData,
          },
        }),
      );
    }
  }

  /// Kills every open socket without answering anything first
  Future<void> closeSockets() async {
    for (final socket in List.of(sockets)) {
      await socket.close();
    }
  }

  Future<void> close() async {
    await closeSockets();
    await _server.close(force: true);
  }
}
