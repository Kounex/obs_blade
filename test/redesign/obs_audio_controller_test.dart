import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/redesign/obs/obs_audio_controller.dart';
import 'package:obs_blade/redesign/obs/obs_request_client.dart';
import 'package:obs_blade/types/classes/stream/events/base.dart';
import 'package:obs_blade/types/classes/stream/responses/base.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/types/interfaces/message.dart';

typedef Request = (String, RequestType, Map<String, dynamic>);

void main() {
  late StreamController<Message> incoming;
  late ObsRequestClient client;
  late ObsAudioController audio;
  late List<Request> writes;
  late Map<String, double> volumes;
  late Set<String> muted;
  var failVolume = false;
  var holdVolume = false;

  void reply(
    Request request, {
    Map<String, dynamic> data = const {},
    int code = 100,
  }) {
    incoming.add(
      BaseResponse.d({
        'requestId': request.$1,
        'requestType': request.$2.name,
        'requestStatus': {'result': code == 100, 'code': code},
        'responseData': data,
      }),
    );
  }

  void event(String type, Map<String, dynamic> data) => incoming.add(
    BaseEvent({
      'op': 5,
      'd': {'eventType': type, 'eventData': data},
    }),
  );
  setUp(() {
    incoming = StreamController<Message>.broadcast(sync: true);
    writes = [];
    volumes = {'Desk mic': .7, 'Music': 1.4};
    muted = {};
    failVolume = false;
    holdVolume = false;
    client = ObsRequestClient(
      messages: incoming.stream,
      send: (id, type, data) {
        final request = (id, type, data);
        writes.add(request);
        final name = data['inputName'];
        switch (type) {
          case RequestType.GetInputList:
            reply(
              request,
              data: {
                'inputs': [
                  {'inputName': 'Desk mic'},
                  {'inputName': 'Music'},
                  {'inputName': 'Image'},
                ],
              },
            );
          case RequestType.GetInputMute:
            reply(
              request,
              code: name == 'Image' ? 604 : 100,
              data: {'inputMuted': muted.contains(name)},
            );
          case RequestType.GetInputVolume:
            if (holdVolume) break;
            reply(
              request,
              code: name == 'Image'
                  ? 604
                  : failVolume
                  ? 702
                  : 100,
              data: {'inputVolumeMul': volumes[name]},
            );
          default:
            break;
        }
      },
    );
    audio = ObsAudioController(client);
  });
  tearDown(() async {
    audio.dispose();
    client.close();
    await incoming.close();
  });

  test(
    'discovers audio by capability and preserves gain above unity',
    () async {
      await audio.refresh();
      expect(audio.controls.map((c) => c.name), ['Desk mic', 'Music']);
      expect(audio.controls.last.volume, 1.4);
      expect(audio.controls.every((c) => c.fresh), isTrue);
    },
  );

  test(
    'mute and volume scope to an input without blocking another input',
    () async {
      await audio.refresh();
      final mute = audio.setMuted('Desk mic', true);
      final muteRequest = writes.last;
      final volume = audio.setVolume('Music', .4);
      final volumeRequest = writes.last;
      expect(muteRequest.$3, {'inputName': 'Desk mic', 'inputMuted': true});
      expect(volumeRequest.$3, {'inputName': 'Music', 'inputVolumeMul': .4});
      expect(audio.controls.last.pendingVolume, .4);
      final count = writes.length;
      await audio.setVolume('Desk mic', .2); // same input is busy
      expect(writes.length, count);
      reply(volumeRequest);
      reply(muteRequest);
      await Future.wait([mute, volume]);
      expect(
        audio.controls.first.muted,
        isFalse,
      ); // acknowledgement isn't state
      expect(audio.controls.last.volume, 1.4);
      expect(audio.controls.every((c) => !c.busy), isTrue);
    },
  );

  test('external state updates the matching input and never another', () async {
    await audio.refresh();
    event('InputMuteStateChanged', {
      'inputName': 'Desk mic',
      'inputMuted': true,
    });
    event('InputVolumeChanged', {'inputName': 'Music', 'inputVolumeMul': .25});
    expect(audio.controls.first.muted, isTrue);
    expect(audio.controls.first.volume, .7);
    expect(audio.controls.last.volume, .25);
  });

  test('newer events survive an older discovery snapshot', () async {
    await audio.refresh();
    holdVolume = true;
    final refresh = audio.refresh();
    await Future<void>.delayed(Duration.zero);
    event('InputMuteStateChanged', {
      'inputName': 'Desk mic',
      'inputMuted': true,
    });
    event('InputVolumeChanged', {'inputName': 'Music', 'inputVolumeMul': .25});
    for (final request
        in writes
            .where((r) => r.$2 == RequestType.GetInputVolume)
            .toList()
            .reversed
            .take(3)) {
      reply(request, data: {'inputVolumeMul': .9});
    }
    await refresh;
    expect(audio.controls.first.muted, isTrue);
    expect(audio.controls.first.volume, .9);
    expect(audio.controls.last.volume, .25);
  });

  test(
    'read failures retain unavailable rows instead of inventing zero volume',
    () async {
      await audio.refresh();
      failVolume = true;
      await audio.refresh();
      expect(audio.controls, hasLength(2));
      expect(audio.controls.first.volume, .7);
      expect(audio.controls.every((c) => !c.fresh && !c.canChange), isTrue);
      expect(audio.problem, isNotNull);
    },
  );

  test('rejection leaves observed state and clears queued level', () async {
    await audio.refresh();
    final command = audio.setVolume('Desk mic', .2);
    reply(writes.last, code: 702);
    await command;
    expect(audio.controls.first.volume, .7);
    expect(audio.controls.first.error, contains('rejected'));
    expect(audio.controls.first.pendingVolume, isNull);
  });

  test('invalid levels and unknown inputs never produce a request', () async {
    await audio.refresh();
    final count = writes.length;
    await audio.setVolume('Desk mic', double.nan);
    await audio.setVolume('Desk mic', -1);
    await audio.setVolume('Desk mic', 21);
    await audio.setMuted('Missing', true);
    expect(writes.length, count);
  });

  test('collection change invalidates in-flight input commands', () async {
    await audio.refresh();
    final command = audio.setMuted('Desk mic', true);
    final request = writes.last;
    event('CurrentSceneCollectionChanging', <String, dynamic>{});
    expect(audio.controls, isEmpty);
    final count = writes.length;
    await audio.setMuted('Desk mic', false);
    reply(request);
    await command;
    expect(writes.length, count);
    expect(audio.controls, isEmpty);
  });
}
