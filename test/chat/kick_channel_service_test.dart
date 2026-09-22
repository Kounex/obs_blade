import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/utils/kick/kick_channel_service.dart';

void main() {
  test('resolveChannel sends a non-browser User-Agent', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v2/channels/deenthegreat');
      expect(request.headers['user-agent'], kKickUserAgent);
      expect(
        request.headers['user-agent']!.toLowerCase(),
        isNot(contains('mozilla')),
      );
      return http.Response(
        json.encode({
          'id': 1,
          'user_id': 2,
          'slug': 'deenthegreat',
          'chatroom': {'id': 9},
        }),
        200,
      );
    });

    final info = await KickChannelService(
      client: client,
    ).resolveChannel('deenthegreat');

    expect(info?.chatroomId, 9);
    expect(info?.slug, 'deenthegreat');
  });
}
