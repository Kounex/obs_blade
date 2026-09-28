// obs_demo.dart — puts a local OBS into the "store screenshot" demo state
// (tool/store_screenshots/README.md) and back.
//
// Run from the repo root on the macOS machine that runs OBS:
//   dart run tool/store_screenshots/obs_demo.dart setup     # profile + scene collection
//   dart run tool/store_screenshots/obs_demo.dart setup --video  # same, moving sources
//   dart run tool/store_screenshots/obs_demo.dart live      # start stream + record
//   dart run tool/store_screenshots/obs_demo.dart offline   # stop stream + record
//   dart run tool/store_screenshots/obs_demo.dart teardown  # stop, restore the user's profile/collection
//
// `setup` never edits the user's own profile or scene collection: it creates
// (or reuses) a dedicated "OBS Blade Store Demo" profile + scene collection,
// remembering the previous ones (and Studio Mode, which is global) in
// build/store_screenshots/obs_restore.json for `teardown`. The stream target
// is a local RTMP sink (capture.sh runs an `ffmpeg -listen` receiver), so
// "live" never reaches a real service.
//
// Every command checks where OBS really is first: setup refuses an OBS that
// is live on another profile and re-reads the current profile/collection
// after each switch before it changes settings or removes anything; live
// needs the demo profile + collection streaming to the local sink; offline
// and teardown only stop outputs on the demo profile - never the user's own
// stream - so teardown is safe to run any time (twice, before setup, ...).
//
// Media comes from prepare_media.sh (build/store_screenshots/media/).
// `--video` (video mode, record.sh) swaps the Game Capture and Webcam stills
// for the looping gameplay/facecam clips (prepare_media.sh --video), so the
// app's scene preview moves on camera.
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
  var video = false;
  final commands = <String>[];
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--host':
        host = args[++i];
      case '--port':
        port = int.parse(args[++i]);
      case '--password':
        password = args[++i];
      case '--video':
        video = true;
      default:
        commands.add(args[i]);
    }
  }
  if (commands.isEmpty) {
    stderr.writeln(
      'usage: obs_demo.dart setup [--video]|live|offline|teardown',
    );
    exit(2);
  }

  final obs = await Obs.connect(host, port, password ?? readLocalPassword());
  try {
    for (final command in commands) {
      switch (command) {
        case 'setup':
          await setup(obs, video: video);
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

Future<void> setup(Obs obs, {bool video = false}) async {
  if (!File('$mediaDir/gameplay.png').existsSync()) {
    throw 'media missing - run tool/store_screenshots/prepare_media.sh first';
  }
  if (video &&
      !(File('$mediaDir/gameplay.mp4').existsSync() &&
          File('$mediaDir/facecam.mp4').existsSync())) {
    throw 'video loops missing - run '
        'tool/store_screenshots/prepare_media.sh --video first';
  }

  final profiles = (await obs.call('GetProfileList'))!;
  final collections = (await obs.call('GetSceneCollectionList'))!;
  final String profile = profiles['currentProfileName'] as String? ?? '';
  final String collection =
      collections['currentSceneCollectionName'] as String? ?? '';

  // Never take over an OBS that is live on the user's own profile.
  if (profile != kDemoName) {
    final active = await activeOutputs(obs);
    if (active.isNotEmpty) {
      throw 'setup: OBS is ${active.join(' + ')} on profile "$profile" - '
          'stop that first, setup never switches a live OBS';
    }
  }

  // Remember what the user had - unless the demo is active already (a
  // re-run: the file holds the real originals).
  final restore = File(restoreFile);
  if (profile != kDemoName && collection != kDemoName) {
    final studio = (await obs.call('GetStudioModeEnabled'))!;
    restore.parent.createSync(recursive: true);
    restore.writeAsStringSync(
      jsonEncode({
        'profile': profile,
        'collection': collection,
        'studioMode': studio['studioModeEnabled'] == true,
      }),
    );
  } else if (!restore.existsSync()) {
    print(
      'setup: OBS is on the demo already but $restoreFile is gone - '
      'teardown will leave it there',
    );
  }

  // Profile: local RTMP sink, 1080p60, OBS recordings into build/ (not
  // recordings/ - that is where record.sh puts the screen recordings).
  if (profile != kDemoName) {
    if ((profiles['profiles'] as List).contains(kDemoName)) {
      await obs.call('SetCurrentProfile', {'profileName': kDemoName});
    } else {
      await obs.call('CreateProfile', {'profileName': kDemoName});
    }
    await waitFor(
      'the switch to the "$kDemoName" profile',
      () async => (await current(obs)).profile == kDemoName,
    );
  }
  await Future<void>.delayed(const Duration(seconds: 1));
  // the calls below change the CURRENT profile's settings
  await requireDemo(obs, 'setup', collection: false);
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
  final recDir = Directory('$repoRoot/build/store_screenshots/obs_recordings')
    ..createSync(recursive: true);
  await obs.call('SetRecordDirectory', {'recordDirectory': recDir.path});

  // Scene collection: switch (or create), then clear it for a clean rebuild.
  if (collection != kDemoName) {
    if ((collections['sceneCollections'] as List).contains(kDemoName)) {
      await obs.call('SetCurrentSceneCollection', {
        'sceneCollectionName': kDemoName,
      });
    } else {
      await obs.call('CreateSceneCollection', {
        'sceneCollectionName': kDemoName,
      });
    }
    await waitFor(
      'the switch to the "$kDemoName" scene collection',
      () async => (await current(obs)).collection == kDemoName,
    );
  }
  await Future<void>.delayed(const Duration(seconds: 2));
  // everything below removes scenes and sources of the CURRENT collection
  await requireDemo(obs, 'setup');
  await obs.call('SetStudioModeEnabled', {'studioModeEnabled': false});

  const temp = '__store_demo_tmp__';
  await obs.call('CreateScene', {'sceneName': temp}, true);
  await obs.call('SetCurrentProgramScene', {'sceneName': temp});
  final scenes = (await obs.call('GetSceneList'))!['scenes'] as List;
  for (final s in scenes) {
    final name = (s as Map)['sceneName'] as String;
    if (name != temp) await obs.call('RemoveScene', {'sceneName': name});
  }
  await requireDemo(obs, 'setup');
  // OBS releases removed sources lazily - wait until they're really gone,
  // or recreating them (a re-run on the staged collection) collides
  for (var attempt = 0; attempt < 20; attempt++) {
    final inputs = (await obs.call('GetInputList'))!['inputs'] as List;
    if (inputs.isEmpty) break;
    for (final i in inputs) {
      await obs.call('RemoveInput', {
        'inputName': (i as Map)['inputName'],
      }, true);
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
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
  // A looping, silent video clip (video mode): never restarts, keeps
  // playing when its scene is not live - a seamless loop that just runs.
  Future<int> clip(String scene, String name, String file) async {
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
    await obs.call('SetInputAudioMonitorType', {
      'inputName': name,
      'monitorType': 'OBS_MONITORING_TYPE_NONE',
    });
    return id;
  }

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
  if (video) {
    // The clips are media inputs too, so the app's mixer lists them (in
    // creation order) - the real audio beds go first, right below Music
    await audio('Game', 'Game Audio', 'game.wav', -10);
    await audio('Game', 'Mic', 'mic.wav', -6);
    await clip('Game', 'Game Capture', 'gameplay.mp4');
  } else {
    await image('Game', 'Game Capture', 'gameplay.png');
  }
  final cam = video
      ? await clip('Game', 'Webcam', 'facecam.mp4')
      : await image('Game', 'Webcam', 'facecam.png');
  await place('Game', cam, 1466, 620, 420 / 1280);
  await image('Game', 'Overlay', 'overlay.png');
  if (!video) {
    await audio('Game', 'Game Audio', 'game.wav', -10);
    await audio('Game', 'Mic', 'mic.wav', -6);
  }
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
  print(
    'setup: "$kDemoName" profile + scene collection ready (Gameplay live'
    '${video ? ', moving sources' : ''})',
  );
}

Future<void> live(Obs obs) async {
  await requireDemo(obs, 'live');
  await requireLocalSink(obs, 'live');
  final stream = (await obs.call('GetStreamStatus'))!;
  if (stream['outputActive'] != true) await obs.call('StartStream');
  final record = (await obs.call('GetRecordStatus'))!;
  if (record['outputActive'] != true) await obs.call('StartRecord');
  print('live: streaming to $kRtmpServer + recording');
}

/// Stops stream + record - on the demo profile only (they go to the local
/// sink there); on any other profile they are the user's and stay as they
/// are. Returns whether it stopped anything.
Future<bool> offline(Obs obs) async {
  final String profile = (await current(obs)).profile;
  if (profile != kDemoName) {
    print(
      'offline: OBS is on profile "$profile", not the demo - '
      'its outputs stay as they are',
    );
    return false;
  }
  await obs.call('StopStream', null, true);
  await obs.call('StopRecord', null, true);
  await waitFor('stopping stream + record', () async {
    final stream = (await obs.call('GetStreamStatus'))!;
    final record = (await obs.call('GetRecordStatus'))!;
    return stream['outputActive'] != true && record['outputActive'] != true;
  }, seconds: 30);
  print('offline: stream + record stopped');
  return true;
}

/// Back to the user's own profile/collection and Studio Mode. Safe to run
/// any time: reads the restore file before touching OBS, only acts while
/// OBS is on the demo, never stops (or switches away from) the user's own
/// outputs.
Future<void> teardown(Obs obs) async {
  final restore = File(restoreFile);
  Map<String, dynamic>? saved;
  if (restore.existsSync()) {
    try {
      saved = jsonDecode(restore.readAsStringSync()) as Map<String, dynamic>;
    } on FormatException catch (e) {
      print('teardown: unreadable $restoreFile ($e)');
    }
  }
  final now = await current(obs);
  final onDemoProfile = now.profile == kDemoName;
  final onDemoCollection = now.collection == kDemoName;
  if (!onDemoProfile && !onDemoCollection) {
    print(
      'teardown: OBS is on profile "${now.profile}" / collection '
      '"${now.collection}", not the demo - nothing to do',
    );
    if (restore.existsSync()) restore.deleteSync(); // stale
    return;
  }
  if (onDemoProfile) {
    await offline(obs);
    await Future<void>.delayed(const Duration(seconds: 2));
  } else {
    final active = await activeOutputs(obs);
    if (active.isNotEmpty) {
      print(
        'teardown: OBS is ${active.join(' + ')} on profile "${now.profile}" '
        '- leaving it as it is',
      );
      return;
    }
  }
  if (saved == null) {
    print('teardown: no restore file - OBS stays on the demo');
    return;
  }
  final toCollection = saved['collection'] as String?;
  final toProfile = saved['profile'] as String?;
  if (onDemoCollection && toCollection != null && toCollection != kDemoName) {
    await obs.call('SetCurrentSceneCollection', {
      'sceneCollectionName': toCollection,
    });
    await waitFor(
      'the switch back to collection "$toCollection"',
      () async => (await current(obs)).collection == toCollection,
    );
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  if (onDemoProfile && toProfile != null && toProfile != kDemoName) {
    await obs.call('SetCurrentProfile', {'profileName': toProfile});
    await waitFor(
      'the switch back to profile "$toProfile"',
      () async => (await current(obs)).profile == toProfile,
    );
  }
  final studioMode = saved['studioMode'];
  if (studioMode is bool) {
    await obs.call('SetStudioModeEnabled', {'studioModeEnabled': studioMode});
  }
  restore.deleteSync();
  final recDir = Directory('$repoRoot/build/store_screenshots/obs_recordings');
  if (recDir.existsSync()) recDir.deleteSync(recursive: true);
  final back = await current(obs);
  print(
    'teardown: back on profile "${back.profile}" / '
    'collection "${back.collection}"'
    '${studioMode is bool ? ', Studio Mode ${studioMode ? 'on' : 'off'}' : ''}',
  );
}

// ------------------------------------------------------------ guards

Future<({String profile, String collection})> current(Obs obs) async {
  final profiles = (await obs.call('GetProfileList'))!;
  final collections = (await obs.call('GetSceneCollectionList'))!;
  return (
    profile: profiles['currentProfileName'] as String? ?? '',
    collection: collections['currentSceneCollectionName'] as String? ?? '',
  );
}

/// Throws unless OBS is on the demo profile (and, with [collection], the
/// demo scene collection) - checked right before every call that changes
/// profile settings, removes scenes/sources or starts outputs.
Future<void> requireDemo(
  Obs obs,
  String command, {
  bool collection = true,
}) async {
  final now = await current(obs);
  if (now.profile != kDemoName || (collection && now.collection != kDemoName)) {
    throw '$command: OBS is on profile "${now.profile}" / collection '
        '"${now.collection}", not "$kDemoName" - refusing to touch it';
  }
}

/// Throws unless the current profile streams to the local sink.
Future<void> requireLocalSink(Obs obs, String command) async {
  final service = (await obs.call('GetStreamServiceSettings'))!;
  final settings = service['streamServiceSettings'] as Map<String, dynamic>?;
  final server = settings?['server'] as String? ?? '';
  if (service['streamServiceType'] != 'rtmp_custom' ||
      Uri.tryParse(server)?.host != '127.0.0.1') {
    throw '$command: the stream goes to "$server" '
        '(${service['streamServiceType']}), not the local sink - refusing';
  }
}

/// Names of the outputs running right now (stream, record, replay buffer,
/// virtual camera; the last two fail when not configured - not running).
Future<List<String>> activeOutputs(Obs obs) async {
  final active = <String>[];
  for (final (request, name) in [
    ('GetStreamStatus', 'streaming'),
    ('GetRecordStatus', 'recording'),
    ('GetReplayBufferStatus', 'replay buffering'),
    ('GetVirtualCamStatus', 'virtual cam'),
  ]) {
    final status = await obs.call(request, null, true);
    if (status?['outputActive'] == true) active.add(name);
  }
  return active;
}

/// Polls [done] for up to [seconds]; throws naming [what] otherwise.
Future<void> waitFor(
  String what,
  Future<bool> Function() done, {
  int seconds = 10,
}) async {
  for (var i = 0; i < seconds * 4; i++) {
    if (await done()) return;
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  throw '$what did not take effect';
}
