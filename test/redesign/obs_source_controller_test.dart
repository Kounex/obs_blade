import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/redesign/obs/obs_request_client.dart';
import 'package:obs_blade/redesign/obs/obs_source_controller.dart';
import 'package:obs_blade/types/classes/stream/events/base.dart';
import 'package:obs_blade/types/classes/stream/responses/base.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/types/interfaces/message.dart';

void main() {
  late StreamController<Message> incoming;
  late ObsRequestClient client;
  late ObsSourceController sources;
  late List<(String, RequestType, Map<String, dynamic>)> writes;
  late Map<String, List<Map<String, dynamic>>> owners;
  void Function(RequestType)? beforeRead;

  Map<String, dynamic> item(
    int id,
    String name, {
    bool group = false,
    bool enabled = true,
  }) => {
    'sceneItemId': id,
    'sceneItemIndex': id,
    'sourceName': name,
    'isGroup': group,
    'sceneItemEnabled': enabled,
  };
  void reply(
    (String, RequestType, Map<String, dynamic>) request, {
    Map<String, dynamic> data = const {},
    bool ok = true,
  }) {
    incoming.add(
      BaseResponse.d({
        'requestId': request.$1,
        'requestType': request.$2.name,
        'requestStatus': {'result': ok, 'code': ok ? 100 : 600},
        'responseData': data,
      }),
    );
  }

  void event(String owner, int id, bool enabled) {
    incoming.add(
      BaseEvent({
        'op': 5,
        'd': {
          'eventType': 'SceneItemEnableStateChanged',
          'eventIntent': 128,
          'eventData': {
            'sceneName': owner,
            'sceneItemId': id,
            'sceneItemEnabled': enabled,
          },
        },
      }),
    );
  }

  setUp(() {
    incoming = StreamController<Message>.broadcast(sync: true);
    writes = [];
    beforeRead = null;
    owners = {
      'Main': [item(1, 'Overlay', group: true), item(2, 'Camera')],
      'Overlay': [item(2, 'Logo')],
      'Other': [item(2, 'Other camera')],
    };
    client = ObsRequestClient(
      messages: incoming.stream,
      send: (id, type, data) {
        final request = (id, type, data);
        writes.add(request);
        if (type == RequestType.GetSceneItemList ||
            type == RequestType.GetGroupSceneItemList) {
          beforeRead?.call(type);
          reply(request, data: {'sceneItems': owners[data['sceneName']]});
        }
      },
    );
    sources = ObsSourceController(client);
  });
  tearDown(() async {
    sources.dispose();
    client.close();
    await incoming.close();
  });

  test('group children retain owner and OBS item ordering', () async {
    await sources.selectScene('Main');
    expect(sources.controls.map((c) => c.name), ['Camera', 'Overlay', 'Logo']);
    final child = sources.controls.last;
    expect(child.target.owner, 'Overlay');
    expect(child.target.id, 2);
    expect(child.depth, 1);
    expect(writes.last.$2, RequestType.GetGroupSceneItemList);
  });

  test(
    'visibility command stays on original group after inspection changes',
    () async {
      await sources.selectScene('Main');
      final target = sources.controls.last.target;
      final command = sources.setEnabled(target, false);
      final write = writes.last;
      expect(write.$2, RequestType.SetSceneItemEnabled);
      expect(write.$3, {
        'sceneName': 'Overlay',
        'sceneItemId': 2,
        'sceneItemEnabled': false,
      });
      await sources.selectScene('Other');
      reply(write);
      await command;
      expect(sources.controls.single.name, 'Other camera');
      expect(sources.controls.single.enabled, isTrue);
    },
  );

  test(
    'a group snapshot supersedes events received before its own read',
    () async {
      beforeRead = (type) {
        if (type == RequestType.GetSceneItemList) event('Overlay', 2, false);
      };
      await sources.selectScene('Main');
      // A later child query supersedes an event from before that child query.
      expect(sources.controls.last.enabled, isTrue);
    },
  );

  test(
    'group echo only changes the matching owner despite repeated item IDs',
    () async {
      await sources.selectScene('Main');
      event('Overlay', 2, false);
      expect(sources.controls.first.enabled, isTrue);
      expect(sources.controls.last.enabled, isFalse);
      event('Other', 2, false);
      expect(sources.controls.first.enabled, isTrue);
    },
  );

  test(
    'acknowledgement does not invent visibility and repeated taps are scoped',
    () async {
      await sources.selectScene('Main');
      final target = sources.controls.last.target;
      final command = sources.setEnabled(target, false);
      final write = writes.last;
      final count = writes.length;
      await sources.setEnabled(target, false);
      expect(writes.length, count);
      expect(sources.controls.last.busy, isTrue);
      reply(write); // peer still reports enabled on readback
      await command;
      expect(sources.controls.last.enabled, isTrue);
      expect(sources.controls.last.busy, isFalse);
    },
  );

  test(
    'disabled group retains child flag while exposing effective hiding',
    () async {
      await sources.selectScene('Main');
      event('Main', 1, false);
      expect(sources.controls.last.enabled, isTrue);
      expect(sources.controls.last.hiddenByGroup, isTrue);
    },
  );

  test(
    'collection changes clear identities and disable pending source actions',
    () async {
      await sources.selectScene('Main');
      final target = sources.controls.last.target;
      final command = sources.setEnabled(target, false);
      final write = writes.last;
      incoming.add(
        BaseEvent({
          'op': 5,
          'd': {
            'eventType': 'CurrentSceneCollectionChanging',
            'eventData': <String, dynamic>{},
          },
        }),
      );
      final count = writes.length;
      await sources.setEnabled(target, true);
      expect(writes.length, count);
      expect(sources.controls, isEmpty);
      reply(write);
      await command;
      expect(sources.controls, isEmpty);
    },
  );
}
