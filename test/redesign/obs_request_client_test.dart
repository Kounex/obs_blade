import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/redesign/obs/obs_request_client.dart';
import 'package:obs_blade/types/classes/stream/responses/base.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/types/interfaces/message.dart';

BaseResponse reply(String id, RequestType type, {bool accepted = true}) =>
    BaseResponse.d({
      'requestId': id,
      'requestType': type.name,
      'requestStatus': {'result': accepted, 'code': accepted ? 100 : 600},
      'responseData': {'answer': 42},
    });

void main() {
  late StreamController<Message> incoming;
  late ObsRequestClient client;
  late List<(String, RequestType)> sent;

  setUp(() {
    incoming = StreamController<Message>.broadcast(sync: true);
    sent = [];
    client = ObsRequestClient(
      messages: incoming.stream,
      send: (id, type, data) => sent.add((id, type)),
      timeout: const Duration(milliseconds: 15),
    );
  });
  tearDown(() async {
    client.close();
    await incoming.close();
  });

  test('matches ID and type with concurrent out-of-order replies', () async {
    final first = client.request(RequestType.GetSceneList);
    final second = client.request(RequestType.GetStudioModeEnabled);
    final (idA, typeA) = sent.first;
    final (idB, typeB) = sent.last;
    incoming.add(reply(idA, typeB)); // same ID, wrong type: ignore
    incoming.add(reply('unrelated', typeA));
    incoming.add(reply(idB, typeB, accepted: false));
    incoming.add(reply(idA, typeA));
    expect((await second).outcome, ObsRequestOutcome.rejected);
    expect((await first).data['answer'], 42);
  });

  test('registers before an inline response can arrive', () async {
    client.close();
    client = ObsRequestClient(
      messages: incoming.stream,
      send: (id, type, data) => incoming.add(reply(id, type)),
    );
    expect((await client.request(RequestType.GetSceneList)).accepted, isTrue);
  });

  test('timeout has unknown outcome and does not resend', () async {
    final result = await client.request(RequestType.SetCurrentProgramScene);
    expect(result.outcome, ObsRequestOutcome.timedOut);
    expect(sent, hasLength(1));
    incoming.add(
      reply(sent.single.$1, sent.single.$2),
    ); // late reply is harmless
  });

  test(
    'transport close resolves all requests and prevents later writes',
    () async {
      final first = client.request(RequestType.SetCurrentProgramScene);
      final second = client.request(RequestType.GetSceneList);
      await incoming.close();
      expect((await first).outcome, ObsRequestOutcome.disconnected);
      expect((await second).outcome, ObsRequestOutcome.disconnected);
      expect(
        (await client.request(RequestType.GetSceneList)).outcome,
        ObsRequestOutcome.disconnected,
      );
      expect(sent, hasLength(2));
    },
  );

  test('transport errors settle pending requests', () async {
    final pending = client.request(RequestType.SetCurrentProgramScene);
    incoming.addError(StateError('connection lost'));
    expect((await pending).outcome, ObsRequestOutcome.disconnected);
  });

  test(
    'send exception retires transport instead of leaving busy state',
    () async {
      client.close();
      client = ObsRequestClient(
        messages: incoming.stream,
        send: (_, _, _) => throw StateError('closed'),
      );
      expect(
        (await client.request(RequestType.GetSceneList)).outcome,
        ObsRequestOutcome.disconnected,
      );
    },
  );
}
