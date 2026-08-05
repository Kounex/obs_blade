import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_message_service.dart';

void main() {
  test('posts broadcaster/sender/message and parses a sent result', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(
        request.url.toString(),
        'https://api.twitch.tv/helix/chat/messages',
      );
      expect(request.headers['Authorization'], 'Bearer token-1');
      expect(request.headers['Client-Id'], kTwitchClientId);
      expect(request.headers['Content-Type'], 'application/json');
      expect(json.decode(request.body), {
        'broadcaster_id': 'user-1',
        'sender_id': 'user-1',
        'message': 'hello chat',
      });
      return http.Response(
        json.encode({
          'data': [
            {'message_id': 'msg-1', 'is_sent': true, 'drop_reason': null},
          ],
        }),
        200,
      );
    });

    final result = await TwitchMessageService(client: client)
        .sendChatMessage(
      accessToken: 'token-1',
      userId: 'user-1',
      message: 'hello chat',
    );

    expect(result.isSent, isTrue);
    expect(result.messageId, 'msg-1');
    expect(result.dropReason, isNull);
  });

  test('parses a dropped result with its reason', () async {
    final client = MockClient(
      (request) async => http.Response(
        json.encode({
          'data': [
            {
              'message_id': '',
              'is_sent': false,
              'drop_reason': 'automod_blocked',
            },
          ],
        }),
        200,
      ),
    );

    final result = await TwitchMessageService(client: client)
        .sendChatMessage(
      accessToken: 'token-1',
      userId: 'user-1',
      message: 'spam',
    );

    expect(result.isSent, isFalse);
    expect(result.dropReason, 'automod_blocked');
  });

  test('throws TwitchAuthException with status on non-200', () {
    final client = MockClient((request) async => http.Response('nope', 401));

    expect(
      TwitchMessageService(client: client).sendChatMessage(
        accessToken: 'token-1',
        userId: 'user-1',
        message: 'hi',
      ),
      throwsA(
        isA<TwitchAuthException>()
            .having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
  });
}
