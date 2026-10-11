// Live probe: what a real OBS answers for source colors (Sources dock ->
// Set Color) in the current program scene - GetVersion's availableRequests,
// GetSceneItemList, then GetSceneItemPrivateSettings per item (group
// children under the group's source name, like the app).
//
//   dart run tool/obs_local/source_colors_probe.dart [--host 127.0.0.1] [--port 4455] [--password <pw>] [--scene <name>]
//
// Prints the raw private settings so the app's parsing
// (lib/utils/scene_item_color.dart) can be checked against reality.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/io.dart';

const Duration kTimeout = Duration(seconds: 10);

Future<void> main(List<String> args) async {
  var host = '127.0.0.1';
  var port = 4455;
  var password = '';
  String? scene;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--host' && i + 1 < args.length) host = args[++i];
    if (args[i] == '--port' && i + 1 < args.length) {
      port = int.tryParse(args[++i]) ?? port;
    }
    if (args[i] == '--password' && i + 1 < args.length) password = args[++i];
    if (args[i] == '--scene' && i + 1 < args.length) scene = args[++i];
  }

  final channel = IOWebSocketChannel.connect(
    Uri.parse('ws://$host:$port'),
    connectTimeout: kTimeout,
  );
  await channel.ready.timeout(kTimeout);

  final messages = StreamController<Map<String, dynamic>>.broadcast();
  channel.stream.listen(
    (m) => messages.add(jsonDecode(m as String) as Map<String, dynamic>),
  );
  Future<Map<String, dynamic>> next(bool Function(Map<String, dynamic>) t) =>
      messages.stream.firstWhere(t).timeout(kTimeout);

  final helloFuture = next((m) => m['op'] == 0);
  final hello = (await helloFuture)['d'] as Map<String, dynamic>;
  final auth = hello['authentication'] as Map<String, dynamic>?;
  final identify = <String, dynamic>{'rpcVersion': hello['rpcVersion'] ?? 1};
  if (auth != null) {
    String b64(String s) => base64.encode(sha256.convert(utf8.encode(s)).bytes);
    identify['authentication'] = b64(
      '${b64('$password${auth['salt']}')}${auth['challenge']}',
    );
  }
  final identifiedFuture = next((m) => m['op'] == 2);
  channel.sink.add(jsonEncode({'op': 1, 'd': identify}));
  await identifiedFuture;

  var counter = 0;
  Future<Map<String, dynamic>> request(
    String type, [
    Map<String, dynamic>? data,
  ]) async {
    final id = 'p${counter++}';
    final answer = next((m) => m['op'] == 7 && m['d']['requestId'] == id);
    channel.sink.add(
      jsonEncode({
        'op': 6,
        'd': {'requestType': type, 'requestId': id, 'requestData': ?data},
      }),
    );
    return (await answer)['d'] as Map<String, dynamic>;
  }

  final version = (await request('GetVersion'))['responseData'] as Map;
  final available = (version['availableRequests'] as List).cast<String>();
  print(
    'OBS ${version['obsVersion']} / obs-websocket '
    '${version['obsWebSocketVersion']}',
  );
  print(
    'GetSceneItemPrivateSettings in availableRequests: '
    '${available.contains('GetSceneItemPrivateSettings')}',
  );

  scene ??=
      ((await request('GetCurrentProgramScene'))['responseData']
          as Map)['currentProgramSceneName'];
  print('Scene: $scene\n');

  Future<void> dump(String sceneName, {bool group = false}) async {
    final list = await request(
      group ? 'GetGroupSceneItemList' : 'GetSceneItemList',
      {'sceneName': sceneName},
    );
    final items = ((list['responseData'] as Map?)?['sceneItems'] as List?)
        ?.cast<Map>();
    if (items == null) {
      print('  $sceneName: ${list['requestStatus']}');
      return;
    }
    for (final item in items) {
      final answer = await request('GetSceneItemPrivateSettings', {
        'sceneName': sceneName,
        'sceneItemId': item['sceneItemId'],
      });
      print(
        '${group ? '    ' : '  '}#${item['sceneItemId']} '
        '"${item['sourceName']}" (${item['inputKind'] ?? item['sourceType']})'
        ' -> ${jsonEncode(answer['requestStatus'])} '
        '${jsonEncode(answer['responseData'])}',
      );
      if (item['isGroup'] == true) {
        await dump(item['sourceName'] as String, group: true);
      }
    }
  }

  await dump(scene!);
  await channel.sink.close();
  exit(0);
}
