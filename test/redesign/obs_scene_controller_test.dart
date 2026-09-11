import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/redesign/obs/obs_request_client.dart';
import 'package:obs_blade/redesign/obs/obs_scene_controller.dart';
import 'package:obs_blade/types/classes/stream/events/base.dart';
import 'package:obs_blade/types/classes/stream/responses/base.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/types/interfaces/message.dart';

typedef Request = (String, RequestType, Map<String, dynamic>);

void main() {
  late StreamController<Message> incoming;
  late ObsRequestClient client;
  late ObsSceneController controller;
  late List<Request> requests;
  var studio = true;

  void respond(Request request, {Map<String, dynamic>? data, bool ok = true}) {
    incoming.add(
      BaseResponse.d({
        'requestId': request.$1,
        'requestType': request.$2.name,
        'requestStatus': {'result': ok, 'code': ok ? 100 : 600},
        'responseData': data ?? {},
      }),
    );
  }

  Map<String, dynamic> sceneData() => {
    'scenes': [
      {'sceneName': 'Camera', 'sceneIndex': 2},
      {'sceneName': 'Break', 'sceneIndex': 1},
      {'sceneName': 'Desktop', 'sceneIndex': 0},
    ],
    'currentProgramSceneName': 'Camera',
    'currentPreviewSceneName': studio ? 'Break' : null,
  };

  void respondReads() {
    for (final request in requests.toList()) {
      if (request.$2 == RequestType.GetSceneList) {
        respond(request, data: sceneData());
      } else if (request.$2 == RequestType.GetStudioModeEnabled) {
        respond(request, data: {'studioModeEnabled': studio});
      }
    }
  }

  void event(String type, [Map<String, dynamic> data = const {}]) {
    incoming.add(
      BaseEvent({
        'op': 5,
        'd': {'eventType': type, 'eventData': data, 'eventIntent': 1},
      }),
    );
  }

  Future<void> tick() => Future<void>.delayed(Duration.zero);
  Future<void> ready() async {
    final refresh = controller.refresh();
    respondReads();
    await refresh;
    requests.clear();
  }

  setUp(() {
    studio = true;
    incoming = StreamController<Message>.broadcast(sync: true);
    requests = [];
    client = ObsRequestClient(
      messages: incoming.stream,
      send: (id, type, data) => requests.add((id, type, data)),
    );
    controller = ObsSceneController(client);
  });
  tearDown(() async {
    controller.dispose();
    client.close();
    await incoming.close();
  });

  test(
    'scene display order follows OBS indices, independent of response order',
    () async {
      final refresh = controller.refresh();
      final data = sceneData();
      data['scenes'] = (data['scenes'] as List).reversed.toList();
      respond(requests.first, data: data);
      respond(requests.last, data: {'studioModeEnabled': true});
      await refresh;
      expect(controller.scenes, ['Camera', 'Break', 'Desktop']);
    },
  );

  test('inspection is local and cannot overwrite confirmed output', () async {
    await ready();
    controller.inspect('Desktop');
    expect(controller.inspected, 'Desktop');
    expect(controller.program, 'Camera');
    expect(controller.preview, 'Break');
    expect(requests, isEmpty);
    controller.inspect('missing');
    expect(controller.inspected, 'Desktop');
  });

  test(
    'acknowledgement alone never changes preview; target is captured',
    () async {
      await ready();
      final command = controller.previewScene('Desktop');
      controller.inspect('Camera');
      expect(requests.single.$3, {'sceneName': 'Desktop'});
      respond(requests.single);
      await tick();
      expect(controller.preview, 'Break');
      expect(controller.commandPending, isTrue);
      event('CurrentPreviewSceneChanged', {'sceneName': 'Desktop'});
      respondReads(); // stale read must not undo newer event
      await command;
      expect(controller.preview, 'Desktop');
      expect(controller.commandPending, isFalse);
    },
  );

  test(
    'Take uses the studio transition and serializes scene-output actions',
    () async {
      await ready();
      final command = controller.take();
      expect(requests.single.$2, RequestType.TriggerStudioModeTransition);
      expect(requests.single.$3, isEmpty);
      await controller.previewScene('Desktop');
      await controller.sendScene('Desktop');
      expect(requests, hasLength(1));
      respond(requests.single);
      await tick();
      respondReads();
      await command;
      expect(controller.program, 'Camera'); // no fabricated success
    },
  );

  test(
    'direct mode sends a scene and cannot accidentally trigger Take',
    () async {
      studio = false;
      await ready();
      await controller.take();
      await controller.previewScene('Desktop');
      expect(requests, isEmpty);
      final command = controller.sendScene('Desktop');
      expect(requests.single.$2, RequestType.SetCurrentProgramScene);
      expect(requests.single.$3, {'sceneName': 'Desktop'});
      respond(requests.single, ok: false);
      await tick();
      respondReads();
      await command;
      expect(controller.program, 'Camera');
      expect(controller.feedback, contains('rejected'));
    },
  );

  test(
    'events received during initial reads win for each output field',
    () async {
      final refresh = controller.refresh();
      event('CurrentProgramSceneChanged', {'sceneName': 'Desktop'});
      event('CurrentPreviewSceneChanged', {'sceneName': 'Camera'});
      respondReads();
      await refresh;
      expect(controller.program, 'Desktop');
      expect(controller.preview, 'Camera');
      expect(controller.phase, ObsScenePhase.ready);
    },
  );

  test(
    'collection change retires old reads and prevents stale targets',
    () async {
      await ready();
      final command = controller.previewScene('Desktop');
      final oldCommand = requests.single;
      event('CurrentSceneCollectionChanging');
      expect(controller.canCommand, isFalse);
      expect(controller.scenes, isEmpty);
      event('SceneListChanged');
      await controller.refresh();
      expect(
        requests,
        hasLength(1),
      ); // no reads inside collection-change window
      respond(oldCommand);
      await command;
      expect(requests, hasLength(1)); // old ack cannot start a new read
      event('CurrentSceneCollectionChanged');
      respondReads();
      await tick();
      expect(controller.phase, ObsScenePhase.ready);
      expect(controller.inspected, 'Camera');
    },
  );

  test(
    'disconnect settles pending action and keeps only last-known state',
    () async {
      await ready();
      final command = controller.take();
      client.close();
      await command;
      await tick();
      expect(controller.phase, ObsScenePhase.offline);
      expect(controller.commandPending, isFalse);
      expect(controller.canCommand, isFalse);
      expect(controller.program, 'Camera');
    },
  );

  test(
    'malformed or failed snapshot disables controls without partial commit',
    () async {
      final refresh = controller.refresh();
      respond(requests.first, data: {'scenes': []});
      respond(requests.last, data: {'studioModeEnabled': true});
      await refresh;
      expect(controller.phase, ObsScenePhase.unavailable);
      expect(controller.canCommand, isFalse);
      expect(controller.program, isNull);
    },
  );

  test('dispose during refresh cannot notify or publish old values', () async {
    final refresh = controller.refresh();
    controller.dispose();
    respondReads();
    await refresh;
    expect(controller.program, isNull);
    // Replace the disposed instance for the common teardown.
    controller = ObsSceneController(client);
  });
}
