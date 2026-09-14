// ack_smoke.dart — command-ack layer probe for local E2E testing
// (docs/local-obs-e2e.md). Complements ws_smoke.dart (handshake + reads) by
// proving a real OBS answers acked mutations the way the app's command-ack
// layer (lib/utils/network_helper.dart) expects: op 7 RequestResponse and
// op 9 RequestBatchResponse with per-request requestStatus.
//
// Run from the repo root:
//   dart run tool/obs_local/ack_smoke.dart [--host 127.0.0.1] [--port 4455] [--password <obs-ws-password>]
//
// Probes, in order:
//   1. rejected mutation  — SetCurrentProgramScene with a bogus scene name
//      must come back requestStatus.result == false (the toast path)
//   2. successful mutation — program scene switched away and back (fallback:
//      input mute toggle) must come back result == true; OBS state is
//      restored afterwards
//   3. batch with mixed outcome — GetVersion + the bogus scene switch in one
//      RequestBatch (haltOnFailure: false) must carry per-request statuses
//      (success + rejection side by side)
// Timeout and connection-loss acks are covered by the fake-peer unit tests
// (test/websocket/command_ack_test.dart) — a real OBS answers everything.
//
// Exit code 0 on success, 1 on failure (reason printed to stderr).

// ignore_for_file: avoid_print — this is a CLI tool; stdout is the product.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/io.dart';

import 'ws_smoke.dart'
    show MessagePump, createAuthenticationString, fail, kTimeout;

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
  final pump = MessagePump(channel.stream, () {
    closeCode = channel.closeCode ?? -1;
    closeReason = channel.closeReason ?? '';
  });

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

  // --- Identify (auth only when challenged — mirrors the app) ---
  final auth = helloD['authentication'] as Map<String, dynamic>?;
  final identify = <String, dynamic>{'rpcVersion': helloD['rpcVersion'] ?? 1};
  if (auth != null) {
    if (password.isEmpty) {
      fail('OBS requires authentication but no --password was given');
    }
    identify['authentication'] = createAuthenticationString(
      password,
      auth['salt'] as String,
      auth['challenge'] as String,
    );
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
  print('Identified: obs-websocket ${helloD['obsWebSocketVersion']}');

  var sequence = 0;

  /// Request without the all-or-nothing semantics of ws_smoke's request():
  /// returns the full response `d` so probes can assert on rejections.
  Future<Map<String, dynamic>> rawRequest(
    String requestType, {
    Map<String, dynamic>? requestData,
  }) async {
    final requestId = 'ack-smoke-${++sequence}-$requestType';
    channel.sink.add(
      jsonEncode({
        'op': 6,
        'd': {
          'requestType': requestType,
          'requestId': requestId,
          ?'requestData': requestData,
        },
      }),
    );
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
    return response['d'] as Map<String, dynamic>;
  }

  Map<String, dynamic> statusOf(Map<String, dynamic> responseD) =>
      responseD['requestStatus'] as Map<String, dynamic>;

  void expectSuccess(String what, Map<String, dynamic> responseD) {
    final status = statusOf(responseD);
    if (status['result'] != true) {
      fail(
        '$what unexpectedly rejected: ${status['code']} '
        '${status['comment'] ?? ''}',
      );
    }
  }

  // --- Setup reads ---
  final scenesResponse = await rawRequest('GetSceneList');
  expectSuccess('GetSceneList', scenesResponse);
  final scenesData = scenesResponse['responseData'] as Map<String, dynamic>;
  final sceneNames = (scenesData['scenes'] as List)
      .map((s) => (s as Map)['sceneName'] as String)
      .toList();
  final currentProgram = scenesData['currentProgramSceneName'] as String?;
  print('Scenes: ${sceneNames.join(', ')} (program: $currentProgram)');

  // --- Probe 1: rejected mutation (the toast path) ---
  final bogusScene =
      'ack-smoke-no-such-scene-${DateTime.now().millisecondsSinceEpoch}';
  final rejected = await rawRequest(
    'SetCurrentProgramScene',
    requestData: {'sceneName': bogusScene},
  );
  final rejectedStatus = statusOf(rejected);
  if (rejectedStatus['result'] == true) {
    fail(
      'SetCurrentProgramScene with a bogus scene name unexpectedly '
      'succeeded — cannot prove the rejection path',
    );
  }
  print(
    'Rejection probe: SetCurrentProgramScene($bogusScene) → result false, '
    'code ${rejectedStatus['code']}, "${rejectedStatus['comment'] ?? ''}"',
  );

  // --- Probe 2: successful mutation, OBS state restored afterwards ---
  if (sceneNames.length >= 2 && currentProgram != null) {
    final other = sceneNames.firstWhere((name) => name != currentProgram);
    expectSuccess(
      'SetCurrentProgramScene($other)',
      await rawRequest(
        'SetCurrentProgramScene',
        requestData: {'sceneName': other},
      ),
    );
    expectSuccess(
      'SetCurrentProgramScene($currentProgram) [restore]',
      await rawRequest(
        'SetCurrentProgramScene',
        requestData: {'sceneName': currentProgram},
      ),
    );
    final verify = await rawRequest('GetCurrentProgramScene');
    expectSuccess('GetCurrentProgramScene', verify);
    final restored =
        (verify['responseData']
            as Map<String, dynamic>)['currentProgramSceneName'];
    if (restored != currentProgram) {
      fail(
        'program scene not restored: expected $currentProgram, '
        'got $restored',
      );
    }
    print(
      'Success probe: program scene switched to $other and back to '
      '$restored',
    );
  } else {
    // Single-scene profile: toggle mute on the first input instead.
    final inputsResponse = await rawRequest('GetInputList');
    expectSuccess('GetInputList', inputsResponse);
    final inputNames =
        ((inputsResponse['responseData'] as Map<String, dynamic>)['inputs']
                as List)
            .map((i) => (i as Map)['inputName'] as String)
            .toList();
    if (inputNames.isEmpty) {
      print('Success probe: SKIPPED (profile has <2 scenes and no inputs)');
    } else {
      final input = inputNames.first;
      expectSuccess(
        'SetInputMute($input, true)',
        await rawRequest(
          'SetInputMute',
          requestData: {'inputName': input, 'inputMuted': true},
        ),
      );
      expectSuccess(
        'SetInputMute($input, false) [restore]',
        await rawRequest(
          'SetInputMute',
          requestData: {'inputName': input, 'inputMuted': false},
        ),
      );
      print('Success probe: input $input muted and unmuted');
    }
  }

  // --- Probe 3: batch with mixed per-request outcomes ---
  const batchId = 'ack-smoke-batch';
  channel.sink.add(
    jsonEncode({
      'op': 8,
      'd': {
        'requestId': batchId,
        'haltOnFailure': false,
        'requests': [
          {'requestType': 'GetVersion'},
          {
            'requestType': 'SetCurrentProgramScene',
            'requestData': {'sceneName': bogusScene},
          },
        ],
      },
    }),
  );
  final batch = await pump.next(
    (m) => m['op'] == 9 && (m['d'] as Map)['requestId'] == batchId,
  );
  if (batch.isEmpty) {
    fail(
      'no RequestBatchResponse within ${kTimeout.inSeconds}s',
      closeCode: closeCode == -1 ? null : closeCode,
      closeReason: closeReason.isEmpty ? null : closeReason,
    );
  }
  final results = ((batch['d'] as Map<String, dynamic>)['results'] as List)
      .cast<Map<String, dynamic>>();
  if (results.length != 2) {
    fail('batch returned ${results.length} results, expected 2');
  }
  final batchFirst = results[0]['requestStatus'] as Map<String, dynamic>;
  final batchSecond = results[1]['requestStatus'] as Map<String, dynamic>;
  if (batchFirst['result'] != true ||
      results[0]['requestType'] != 'GetVersion') {
    fail('batch entry 0 (GetVersion) not successful: $batchFirst');
  }
  if (batchSecond['result'] == true) {
    fail('batch entry 1 (bogus scene switch) unexpectedly succeeded');
  }
  print(
    'Batch probe: GetVersion ok + bogus scene switch rejected '
    '(code ${batchSecond['code']}) in one batch',
  );

  await channel.sink.close();
  print('ACK SMOKE OK');
  exit(0);
}
