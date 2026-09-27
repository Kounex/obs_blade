// obs_demo.dart — puts a local OBS into the "store screenshot" demo state
// (tool/store_screenshots/README.md) and back.
//
// Run from the repo root on the macOS machine that runs OBS:
//   dart run tool/store_screenshots/obs_demo.dart setup     # profile + scene collection
//   dart run tool/store_screenshots/obs_demo.dart live      # start stream + record
//   dart run tool/store_screenshots/obs_demo.dart offline   # stop stream + record
//   dart run tool/store_screenshots/obs_demo.dart teardown  # stop, restore the user's profile/collection
//
// `setup` never edits the user's own profile or scene collection: it creates
// (or reuses) a dedicated "OBS Blade Store Demo" profile + scene collection,
// remembering the previous ones in build/store_screenshots/obs_restore.json
// for `teardown`. The stream target is a local RTMP sink (capture.sh runs an
// `ffmpeg -listen` receiver), so "live" never reaches a real service.
//
// Media comes from prepare_media.sh (build/store_screenshots/media/).
// Options: --host 127.0.0.1 --port 4455 --password <pw> (default: read from
// the local obs-websocket config).

// ignore_for_file: avoid_print — this is a CLI tool; stdout is the product.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/io.dart';

const String kDemoName = 'OBS Blade Store Demo';
const String kRtmpServer = 'rtmp://127.0.0.1:1935/live';
const String kRtmpKey = 'demo';
const Duration kTimeout = Duration(seconds: 15);

late final String repoRoot;
late final String mediaDir;
late final String restoreFile;

class Obs {
  Obs(this._channel) {
    _channel.stream.listen(
      (raw) {
        final m = jsonDecode(raw as String) as Map<String, dynamic>;
        if (m['op'] == 7) {
          final d = m['d'] as Map<String, dynamic>;
          _pending.remove(d['requestId'])?.complete(d);
        } else {
          _handshake.add(m);
        }
      },
      onDone: () {
        for (final c in _pending.values) {
          if (!c.isCompleted) c.completeError('socket closed');
        }
      },
    );
  }

  final IOWebSocketChannel _channel;
  final Map<String, Completer<Map<String, dynamic>>> _pending = {};
  final StreamController<Map<String, dynamic>> _handshake =
      StreamController.broadcast();
  int _id = 0;

  static Future<Obs> connect(String host, int port, String password) async {
    final channel = IOWebSocketChannel.connect(
      Uri.parse('ws://$host:$port'),
      connectTimeout: kTimeout,
    );
    await channel.ready.timeout(kTimeout);
    final obs = Obs(channel);
    final hello = await obs._handshake.stream
        .firstWhere((m) => m['op'] == 0)
        .timeout(kTimeout);
    final helloD = hello['d'] as Map<String, dynamic>;
    final identify = <String, dynamic>{'rpcVersion': 1};
    final auth = helloD['authentication'] as Map<String, dynamic>?;
    if (auth != null) {
      final secret = base64.encode(
        sha256.convert(utf8.encode('$password${auth['salt']}')).bytes,
      );
      identify['authentication'] = base64.encode(
        sha256.convert(utf8.encode('$secret${auth['challenge']}')).bytes,
      );
    }
    final identified = obs._handshake.stream
        .firstWhere((m) => m['op'] == 2)
        .timeout(kTimeout);
    channel.sink.add(jsonEncode({'op': 1, 'd': identify}));
    await identified;
    return obs;
  }

  /// Sends a request; returns responseData. Throws on failure unless
  /// [allowFail] (then returns null).
  Future<Map<String, dynamic>?> call(
    String type, [
    Map<String, dynamic>? data,
    bool allowFail = false,
  ]) async {
    final id = 'r${_id++}';
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    _channel.sink.add(
      jsonEncode({
        'op': 6,
        'd': {'requestType': type, 'requestId': id, 'requestData': ?data},
      }),
    );
    final d = await completer.future.timeout(kTimeout);
    final status = d['requestStatus'] as Map<String, dynamic>;
    if (status['result'] != true) {
      if (allowFail) return null;
      throw 'OBS $type failed: ${status['code']} ${status['comment'] ?? ''}';
    }
    return (d['responseData'] as Map<String, dynamic>?) ?? {};
  }

  Future<void> close() => _channel.sink.close();
}

String readLocalPassword() {
  final home = Platform.environment['HOME'] ?? '';
  final file = File(
    '$home/Library/Application Support/obs-studio/plugin_config/obs-websocket/config.json',
  );
  if (!file.existsSync()) return '';
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return (json['server_password'] as String?) ?? '';
}

Future<void> main(List<String> args) async {
  repoRoot = Directory.current.path;
  mediaDir = '$repoRoot/build/store_screenshots/media';
  restoreFile = '$repoRoot/build/store_screenshots/obs_restore.json';

  var host = '127.0.0.1';
  var port = 4455;
  String? password;
  final commands = <String>[];
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--host':
        host = args[++i];
      case '--port':
        port = int.parse(args[++i]);
      case '--password':
        password = args[++i];
      default:
        commands.add(args[i]);
    }
  }
  if (commands.isEmpty) {
    stderr.writeln('usage: obs_demo.dart setup|live|offline|teardown');
    exit(2);
  }

  final obs = await Obs.connect(host, port, password ?? readLocalPassword());
  try {
    for (final command in commands) {
      switch (command) {
        case 'setup':
          await setup(obs);
        case 'live':
          await live(obs);
        case 'offline':
          await offline(obs);
        case 'teardown':
          await teardown(obs);
        default:
          throw 'unknown command $command';
      }
    }
  } finally {
    await obs.close();
  }
}

Future<void> setup(Obs obs) async {
  if (!File('$mediaDir/gameplay.png').existsSync()) {
    throw 'media missing - run tool/store_screenshots/prepare_media.sh first';
  }

  // Remember what the user had (only the first time — a re-run while the
  // demo is active must not overwrite the real originals).
  final profiles = (await obs.call('GetProfileList'))!;
  final collections = (await obs.call('GetSceneCollectionList'))!;
  final restore = File(restoreFile);
  if (!restore.existsSync()) {
    restore.parent.createSync(recursive: true);
    restore.writeAsStringSync(
      jsonEncode({
        'profile': profiles['currentProfileName'],
        'collection': collections['currentSceneCollectionName'],
      }),
    );
  }

  // Profile: local RTMP sink, 1080p60, recordings into build/.
  if ((profiles['profiles'] as List).contains(kDemoName)) {
    await obs.call('SetCurrentProfile', {'profileName': kDemoName});
  } else {
    await obs.call('CreateProfile', {'profileName': kDemoName});
  }
  await Future<void>.delayed(const Duration(seconds: 1));
  await obs.call('SetStreamServiceSettings', {
    'streamServiceType': 'rtmp_custom',
    'streamServiceSettings': {'server': kRtmpServer, 'key': kRtmpKey},
  });
  await obs.call('SetVideoSettings', {
    'baseWidth': 1920,
    'baseHeight': 1080,
    'outputWidth': 1920,
    'outputHeight': 1080,
    'fpsNumerator': 60,
    'fpsDenominator': 1,
  });
  final recDir = Directory('$repoRoot/build/store_screenshots/recordings')
    ..createSync(recursive: true);
  await obs.call('SetRecordDirectory', {'recordDirectory': recDir.path});

  // Scene collection: switch (or create), then clear it for a clean rebuild.
  if ((collections['sceneCollections'] as List).contains(kDemoName)) {
    await obs.call('SetCurrentSceneCollection', {
      'sceneCollectionName': kDemoName,
    });
  } else {
    await obs.call('CreateSceneCollection', {'sceneCollectionName': kDemoName});
  }
  await Future<void>.delayed(const Duration(seconds: 2));
  await obs.call('SetStudioModeEnabled', {'studioModeEnabled': false});

  const temp = '__store_demo_tmp__';
  await obs.call('CreateScene', {'sceneName': temp}, true);
  await obs.call('SetCurrentProgramScene', {'sceneName': temp});
  final scenes = (await obs.call('GetSceneList'))!['scenes'] as List;
  for (final s in scenes) {
    final name = (s as Map)['sceneName'] as String;
    if (name != temp) await obs.call('RemoveScene', {'sceneName': name});
  }
  final inputs = (await obs.call('GetInputList'))!['inputs'] as List;
  for (final i in inputs) {
    await obs.call('RemoveInput', {'inputName': (i as Map)['inputName']}, true);
  }

  // Inputs are created inside their first scene; later scenes reference them.
  Future<void> scene(String name) =>
      obs.call('CreateScene', {'sceneName': name});
  Future<int> image(String scene, String name, String file) async =>
      (await obs.call('CreateInput', {
            'sceneName': scene,
            'inputName': name,
            'inputKind': 'image_source',
            'inputSettings': {'file': '$mediaDir/$file'},
          }))!['sceneItemId']
          as int;
  Future<int> audio(String scene, String name, String file, double db) async {
    final id =
        (await obs.call('CreateInput', {
              'sceneName': scene,
              'inputName': name,
              'inputKind': 'ffmpeg_source',
              'inputSettings': {
                'local_file': '$mediaDir/$file',
                'looping': true,
                'restart_on_activate': false,
                'close_when_inactive': false,
              },
            }))!['sceneItemId']
            as int;
    await obs.call('SetInputVolume', {'inputName': name, 'inputVolumeDb': db});
    // Monitor off, so nothing plays out loud on the machine.
    await obs.call('SetInputAudioMonitorType', {
      'inputName': name,
      'monitorType': 'OBS_MONITORING_TYPE_NONE',
    });
    return id;
  }

  Future<int> add(String scene, String source) async =>
      (await obs.call('CreateSceneItem', {
            'sceneName': scene,
            'sourceName': source,
          }))!['sceneItemId']
          as int;
  Future<void> place(String scene, int id, double x, double y, double s) =>
      obs.call('SetSceneItemTransform', {
        'sceneName': scene,
        'sceneItemId': id,
        'sceneItemTransform': {
          'positionX': x,
          'positionY': y,
          'scaleX': s,
          'scaleY': s,
        },
      });

  // The app lists scenes in reverse creation order: create the last
  // button first so the dashboard reads Intro ... Outro.
  await scene('Outro');
  await image('Outro', 'Outro Screen', 'ending.png');
  await audio('Outro', 'Music', 'music.wav', -14);
  for (final (name, input, file) in [
    ('Break', 'Break Screen', 'intermission.png'),
    ('BRB', 'BRB Screen', 'brb.png'),
  ]) {
    await scene(name);
    await image(name, input, file);
    await add(name, 'Music');
  }

  await scene('Game');
  await image('Game', 'Game Capture', 'gameplay.png');
  final cam = await image('Game', 'Webcam', 'facecam.png');
  await place('Game', cam, 1466, 620, 420 / 1280);
  await image('Game', 'Overlay', 'overlay.png');
  await audio('Game', 'Game Audio', 'game.wav', -10);
  await audio('Game', 'Mic', 'mic.wav', -6);
  await add('Game', 'Music');

  await scene('Talk');
  final chatCam = await add('Talk', 'Webcam');
  await place('Talk', chatCam, 0, 0, 1.5);
  await add('Talk', 'Mic');
  await add('Talk', 'Music');

  await scene('Intro');
  await image('Intro', 'Starting Screen', 'starting.png');
  await add('Intro', 'Music');

  await obs.call('SetCurrentProgramScene', {'sceneName': 'Game'});
  await obs.call('RemoveScene', {'sceneName': temp});
  print('setup: "$kDemoName" profile + scene collection ready (Gameplay live)');
}

Future<void> live(Obs obs) async {
  final stream = (await obs.call('GetStreamStatus'))!;
  if (stream['outputActive'] != true) await obs.call('StartStream');
  final record = (await obs.call('GetRecordStatus'))!;
  if (record['outputActive'] != true) await obs.call('StartRecord');
  print('live: streaming to $kRtmpServer + recording');
}

Future<void> offline(Obs obs) async {
  await obs.call('StopStream', null, true);
  await obs.call('StopRecord', null, true);
  print('offline: stream + record stopped');
}

Future<void> teardown(Obs obs) async {
  await offline(obs);
  final restore = File(restoreFile);
  if (!restore.existsSync()) {
    print('teardown: no restore file - nothing to switch back');
    return;
  }
  final saved = jsonDecode(restore.readAsStringSync()) as Map<String, dynamic>;
  await Future<void>.delayed(const Duration(seconds: 2));
  await obs.call('SetCurrentSceneCollection', {
    'sceneCollectionName': saved['collection'],
  });
  await Future<void>.delayed(const Duration(seconds: 2));
  await obs.call('SetCurrentProfile', {'profileName': saved['profile']});
  restore.deleteSync();
  final recDir = Directory('$repoRoot/build/store_screenshots/recordings');
  if (recDir.existsSync()) recDir.deleteSync(recursive: true);
  print(
    'teardown: back on profile "${saved['profile']}" / '
    'collection "${saved['collection']}"',
  );
}
