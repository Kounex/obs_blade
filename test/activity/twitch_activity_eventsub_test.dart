import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_notification.dart';
import 'package:obs_blade/utils/twitch/twitch_eventsub_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _Channel extends Fake implements WebSocketChannel {
  final StreamController<dynamic> incoming = StreamController<dynamic>();

  @override
  Stream<dynamic> get stream => this.incoming.stream;

  @override
  WebSocketSink get sink => _Sink(this);
}

class _Sink extends Fake implements WebSocketSink {
  final _Channel channel;

  _Sink(this.channel);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    await this.channel.incoming.close();
  }
}

String _welcome() => json.encode({
  'metadata': {
    'message_id': 'w1',
    'message_type': 'session_welcome',
    'message_timestamp': '2026-10-02T20:00:00.000Z',
  },
  'payload': {
    'session': {'id': 'session-1', 'status': 'connected'},
  },
});

String _notice(String type, Map<String, Object?> event, {String id = 'n1'}) =>
    json.encode({
      'metadata': {
        'message_id': id,
        'message_type': 'notification',
        'message_timestamp': '2026-10-02T20:00:01.000Z',
        'subscription_type': type,
        'subscription_version': '1',
      },
      'payload': {
        'subscription': {'type': type},
        'event': event,
      },
    });

Map<String, Object?> _chatNotice(String broadcaster) => {
  'broadcaster_user_id': broadcaster,
  'broadcaster_user_login': 'b',
  'broadcaster_user_name': 'B',
  'chatter_user_id': '99',
  'chatter_user_login': 'fan',
  'chatter_user_name': 'Fan',
  'chatter_is_anonymous': false,
  'color': '',
  'badges': <Object?>[],
  'system_message': 'Fan subscribed',
  'message_id': 'chat-$broadcaster',
  'message': {'text': '', 'fragments': <Object?>[]},
  'notice_type': 'sub',
  'sub': {'sub_tier': '1000', 'is_prime': false, 'duration_months': 1},
};

void main() {
  late List<_Channel> channels;
  late List<Map<String, dynamic>> posts;
  late List<String> deletes;
  late List<(String, String)> activity;
  late List<ChatNotificationEvent> chatNotices;

  TwitchEventSubService build() {
    final client = MockClient((request) async {
      if (request.method == 'DELETE') {
        deletes.add(request.url.queryParameters['id']!);
        return http.Response('', 204);
      }
      posts.add(json.decode(request.body) as Map<String, dynamic>);
      return http.Response(
        json.encode({
          'data': [
            {'id': 'sub-${posts.length}'},
          ],
        }),
        202,
      );
    });
    return TwitchEventSubService(
        onChatMessage: (_) {},
        onChatNotification: chatNotices.add,
        onStateChanged: (_) {},
        onRevoked: (_) {},
        client: client,
        channelFactory: (uri) {
          final channel = _Channel();
          channels.add(channel);
          return channel;
        },
        sleep: (_) async {},
      )
      ..onActivity = ((type, event, messageId, sentAt) =>
          activity.add((type, messageId)))
      ..activityTypes = {'channel.follow', 'channel.cheer'};
  }

  setUp(() {
    channels = [];
    posts = [];
    deletes = [];
    activity = [];
    chatNotices = [];
  });

  List<Map<String, dynamic>> postsOf(String type) =>
      posts.where((post) => post['type'] == type).toList();

  test(
    'own channel viewed: activity subs, no extra notification sub',
    () async {
      final service = build();
      await service.connect(
        accessToken: 't',
        userId: 'me',
        broadcasterId: 'me',
      );
      channels.single.incoming.add(_welcome());
      await pumpEventQueue();

      final follow = postsOf('channel.follow').single;
      expect(follow['version'], '2');
      expect(follow['condition'], {
        'broadcaster_user_id': 'me',
        'moderator_user_id': 'me',
      });
      final cheer = postsOf('channel.cheer').single;
      expect(cheer['condition'], {'broadcaster_user_id': 'me'});

      /// Only the channel-scoped one (409 for a duplicate condition)
      expect(postsOf('channel.chat.notification'), hasLength(1));
      expect(
        postsOf('channel.channel_points_custom_reward_redemption.add'),
        isEmpty,
      );
      await service.dispose();
    },
  );

  test(
    'another channel viewed: own notices reach the feed, not that chat',
    () async {
      final service = build();
      await service.connect(
        accessToken: 't',
        userId: 'me',
        broadcasterId: 'friend',
      );
      channels.single.incoming.add(_welcome());
      await pumpEventQueue();

      final notificationSubs = postsOf('channel.chat.notification');
      expect(notificationSubs, hasLength(2));
      expect(notificationSubs.last['condition'], {
        'broadcaster_user_id': 'me',
        'user_id': 'me',
      });

      channels.single.incoming.add(
        _notice('channel.chat.notification', _chatNotice('me'), id: 'own'),
      );
      channels.single.incoming.add(
        _notice(
          'channel.chat.notification',
          _chatNotice('friend'),
          id: 'other',
        ),
      );
      await pumpEventQueue();
      expect(activity, [('channel.chat.notification', 'own')]);
      expect(chatNotices.map((n) => n.broadcasterUserId), ['friend']);
      await service.dispose();
    },
  );

  test(
    'switching back to the own channel drops the own-scoped sub first',
    () async {
      final service = build();
      await service.connect(
        accessToken: 't',
        userId: 'me',
        broadcasterId: 'friend',
      );
      channels.single.incoming.add(_welcome());
      await pumpEventQueue();
      final ownScopedId =
          'sub-${posts.indexOf(postsOf('channel.chat.notification').last) + 1}';
      posts.clear();

      await service.switchChannel('me');
      expect(deletes, contains(ownScopedId));
      expect(postsOf('channel.chat.notification'), hasLength(1));
      expect(
        postsOf(
          'channel.chat.notification',
        ).single['condition']['broadcaster_user_id'],
        'me',
      );

      /// Activity subs are own-channel: never re-created by a switch
      expect(postsOf('channel.follow'), isEmpty);

      posts.clear();
      await service.switchChannel('friend');
      expect(postsOf('channel.chat.notification'), hasLength(2));
      await service.dispose();
    },
  );

  test('activity deliveries pass through with their message id', () async {
    final service = build();
    await service.connect(accessToken: 't', userId: 'me', broadcasterId: 'me');
    channels.single.incoming.add(_welcome());
    await pumpEventQueue();
    channels.single.incoming.add(
      _notice('channel.cheer', {
        'broadcaster_user_id': 'me',
        'is_anonymous': false,
        'user_id': '9',
        'user_name': 'Fan',
        'bits': 100,
        'message': 'Cheer100',
      }, id: 'cheer-msg'),
    );
    await pumpEventQueue();
    expect(activity, [('channel.cheer', 'cheer-msg')]);
    await service.dispose();
  });

  test('dispose deletes the activity subs too', () async {
    final service = build();
    await service.connect(
      accessToken: 't',
      userId: 'me',
      broadcasterId: 'friend',
    );
    channels.single.incoming.add(_welcome());
    await pumpEventQueue();
    final created = posts.length;
    await service.dispose();
    expect(deletes.toSet(), {for (var i = 1; i <= created; i++) 'sub-$i'});
  });
}
