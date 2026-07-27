// ws_smoke.dart — OBS WebSocket v5 handshake smoke probe for local E2E
// testing (docs/local-obs-e2e.md).
//
// Run from the repo root:
//   dart run tool/obs_local/ws_smoke.dart [--host 127.0.0.1] [--port 4455] [--password 123456]
//
// Connects to OBS, performs Hello → Identify → Identified with the same
// semantics as the app (authentication only when Hello challenges for it,
// see lib/utils/authentication_helper.dart), then issues GetVersion,
// GetSceneList and GetInputList to prove the protocol path end to end.
//
// Exit code 0 on success, 1 on failure (reason printed to stderr).

// ignore_for_file: avoid_print — this is a CLI tool; stdout is the product.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/io.dart';

const Duration kTimeout = Duration(seconds: 10);

// OBS WebSocket close codes worth naming — current obs-websocket 5.x
// numbering, matching the app's WebSocketCloseCode enum
// (lib/types/enums/web_socket_codes/web_socket_close_code.dart).
const Map<int, String> kCloseCodes = {
  4000: 'UnknownReason',
  4002: 'MessageDecodeError',
  4003: 'MissingDataField',
  4004: 'InvalidDataFieldType',
  4005: 'InvalidDataFieldValue',
  4006: 'UnknownOpCode',
  4007: 'NotIdentified',
  4008: 'AlreadyIdentified',
  4009: 'AuthenticationFailed',
  4010: 'UnsupportedRpcVersion',
  4011: 'SessionInvalidated',
  4012: 'UnsupportedFeature',
};

Never fail(String message, {int? closeCode, String? closeReason}) {
  final suffix = closeCode != null
      ? ' (close $closeCode: ${kCloseCodes[closeCode] ?? 'unknown'}'
          '${closeReason != null ? ', "$closeReason"' : ''})'
      : '';
  stderr.writeln('SMOKE FAIL: $message$suffix');
  exit(1);
}

/// Same algorithm as AuthenticationHelper.createAuthenticationString:
/// SHA256(password+salt) → b64, then SHA256(secret+challenge) → b64.
String createAuthenticationString(
  String password,
  String salt,
  String challenge,
) {
  final secret =
      base64.encode(sha256.convert(utf8.encode('$password$salt')).bytes);
  return base64
      .encode(sha256.convert(utf8.encode('$secret$challenge')).bytes);
}

/// Single-subscription pump over the socket stream: buffers every decoded
/// message and hands them out in order, so sequential `next(...)` calls never
/// miss frames that arrive between awaits.
class MessagePump {
  MessagePump(Stream<dynamic> stream, void Function() onClosed)
      : _onClosed = onClosed {
    stream.listen(
      (m) => _add(jsonDecode(m as String) as Map<String, dynamic>),
      onDone: () {
        _closed = true;
        _onClosed();
        _notify();
      },
      onError: (Object e) {
        _error = e;
        _notify();
      },
    );
  }

  final Queue<Map<String, dynamic>> _queue = Queue();
  final List<Completer<void>> _waiters = [];
  final void Function() _onClosed;
  bool _closed = false;
  Object? _error;

  bool get closed => _closed;
  Object? get error => _error;

  void _add(Map<String, dynamic> m) {
    _queue.add(m);
    _notify();
  }

  void _notify() {
    for (final w in _waiters) {
      if (!w.isCompleted) w.complete();
    }
    _waiters.clear();
  }

  /// Next message matching [test], scanned in arrival order. Unmatched
  /// messages are consumed and dropped (events etc. are irrelevant here).
  Future<Map<String, dynamic>> next(
    bool Function(Map<String, dynamic>) test,
  ) async {
    final deadline = DateTime.now().add(kTimeout);
    while (true) {
      while (_queue.isNotEmpty) {
        final m = _queue.removeFirst();
        if (test(m)) return m;
      }
      if (_error != null) fail('socket error: $_error');
      if (_closed) return <String, dynamic>{};
      final remaining = deadline.difference(DateTime.now());
      if (remaining.isNegative) return <String, dynamic>{};
      final waiter = Completer<void>();
      _waiters.add(waiter);
      await waiter.future.timeout(remaining, onTimeout: () {});
    }
  }
}

Future<void> main(List<String> args) async {
  var host = '127.0.0.1';
  var port = 4455;
  var password = '';
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--host' && i + 1 < args.length) host = args[++i];
    if (args[i] == '--port' && i + 1 < args.length) {
      port = int.tryParse(args[++i]) ?? port;
    }
    if (args[i] == '--password' && i + 1 < args.length) password = args[++i];
  }

  print('Connecting to ws://$host:$port …');
  final channel = IOWebSocketChannel.connect(
    Uri.parse('ws://$host:$port'),
    connectTimeout: kTimeout,
  );
  try {
    await channel.ready.timeout(kTimeout);
  } catch (e) {
    fail('could not connect: $e');
  }

  var closeCode = -1;
  var closeReason = '';
  final pump = MessagePump(
    channel.stream,
    () {
      closeCode = channel.closeCode ?? -1;
      closeReason = channel.closeReason ?? '';
    },
  );

  // --- Hello ---
  final hello = await pump.next((m) => m['op'] == 0);
  if (hello.isEmpty) {
    fail(
      'no Hello (op 0) within ${kTimeout.inSeconds}s — is this OBS?',
      closeCode: closeCode == -1 ? null : closeCode,
      closeReason: closeReason.isEmpty ? null : closeReason,
    );
  }
  final helloD = hello['d'] as Map<String, dynamic>;
  print('Hello: obs-websocket ${helloD['obsWebSocketVersion']}, '
      'rpcVersion ${helloD['rpcVersion']}');

  // --- Identify (auth only when challenged — mirrors the app) ---
  final auth = helloD['authentication'] as Map<String, dynamic>?;
  final identify = <String, dynamic>{
    'rpcVersion': helloD['rpcVersion'] ?? 1,
  };
  if (auth != null) {
    if (password.isEmpty) {
      fail('OBS requires authentication but no --password was given');
    }
    identify['authentication'] = createAuthenticationString(
      password,
      auth['salt'] as String,
      auth['challenge'] as String,
    );
    print('Identify: with authentication (Hello challenged)');
  } else {
    print('Identify: without authentication (no challenge in Hello)');
  }
  channel.sink.add(jsonEncode({'op': 1, 'd': identify}));

  // --- Identified ---
  final identified = await pump.next((m) => m['op'] == 2);
  if (identified.isEmpty) {
    fail(
      'no Identified (op 2) within ${kTimeout.inSeconds}s',
      closeCode: closeCode == -1 ? null : closeCode,
      closeReason: closeReason.isEmpty ? null : closeReason,
    );
  }
  print('Identified: negotiatedRpcVersion '
      '${(identified['d'] as Map)['negotiatedRpcVersion']}');

  // --- Requests ---
  Future<Map<String, dynamic>> request(String requestType) async {
    final requestId = 'smoke-$requestType';
    channel.sink.add(jsonEncode({
      'op': 6,
      'd': {'requestType': requestType, 'requestId': requestId},
    }));
    final response = await pump.next(
      (m) => m['op'] == 7 && (m['d'] as Map)['requestId'] == requestId,
    );
    if (response.isEmpty) {
      fail(
        'no RequestResponse for $requestType within ${kTimeout.inSeconds}s',
        closeCode: closeCode == -1 ? null : closeCode,
      closeReason: closeReason.isEmpty ? null : closeReason,
      );
    }
    final d = response['d'] as Map<String, dynamic>;
    final status = d['requestStatus'] as Map<String, dynamic>;
    if (status['result'] != true) {
      fail('$requestType rejected: ${status['code']} '
          '${status['comment'] ?? ''}');
    }
    return (d['responseData'] as Map<String, dynamic>?) ??
        <String, dynamic>{};
  }

  final version = await request('GetVersion');
  print('GetVersion: OBS ${version['obsVersion']}, '
      'obs-websocket ${version['obsWebSocketVersion']}, '
      'platform ${version['platform']}');

  final scenes = await request('GetSceneList');
  final sceneNames =
      (scenes['scenes'] as List).map((s) => (s as Map)['sceneName']);
  print('GetSceneList: current ${scenes['currentProgramSceneName']} '
      '| scenes: ${sceneNames.join(', ')}');

  final inputs = await request('GetInputList');
  final inputNames =
      (inputs['inputs'] as List).map((s) => (s as Map)['inputName']).toList();
  print('GetInputList: '
      '${inputNames.isEmpty ? '(none)' : inputNames.join(', ')}');

  await channel.sink.close();
  print('SMOKE OK');
  exit(0);
}
