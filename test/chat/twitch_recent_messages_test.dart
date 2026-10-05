import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/views/chat_history.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/classes/twitch/chat_system_notice.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/twitch/twitch_eventsub_service.dart';
import 'package:obs_blade/utils/twitch/twitch_recent_messages_service.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';

/// Real line captured from recent-messages.robotty.de (2026-09-24),
/// trimmed of irrelevant tags.
const _realLine =
    '@subscriber=1;returning-chatter=0;emotes;badge-info=subscriber/26;'
    'flags;id=12a58873-3de3-4e12-bba3-abb11d8bec9f;historical=1;'
    'badges=subscriber/24,speedons-6/1;mod=0;display-name=w_i_n_g_o;'
    'user-id=1074422914;first-msg=0;room-id=71092938;'
    'tmi-sent-ts=1790196434556;color=#00FF7F '
    ':w_i_n_g_o!w_i_n_g_o@w_i_n_g_o.tmi.twitch.tv PRIVMSG #xqc :BAND';

String _line(
  String id, {
  String room = 'user-1',
  String text = 'hi',
  String emotes = '',
  String extra = '',
  int? sentTs,
}) =>
    '@badges=;color=;display-name=Viewer;emotes=$emotes;id=$id;'
    'room-id=$room;user-id=9;tmi-sent-ts=${sentTs ?? 1790196434556}$extra '
    ':viewer!viewer@viewer.tmi.twitch.tv PRIVMSG #kounex :$text';

void main() {
  group('parseIrcPrivmsgToChatMessage', () {
    test('real robotty line → ChatMessageEvent', () {
      final event = parseIrcPrivmsgToChatMessage(_realLine)!;
      expect(event.messageId, '12a58873-3de3-4e12-bba3-abb11d8bec9f');
      expect(event.broadcasterUserId, '71092938');
      expect(event.chatterUserId, '1074422914');
      expect(event.chatterUserLogin, 'w_i_n_g_o');
      expect(event.chatterUserName, 'w_i_n_g_o');
      expect(event.color, '#00FF7F');
      expect(event.message.text, 'BAND');
      expect(event.isHistorical, isTrue);
      expect(event.receivedAt, isNotNull);
      expect(event.badges.map((b) => '${b.setId}/${b.id}/${b.info}'), [
        'subscriber/24/26',
        'speedons-6/1/',
      ]);
    });

    test('emote ranges become emote fragments (code-point offsets)', () {
      final event = parseIrcPrivmsgToChatMessage(
        _line('e1', text: '😀 Kappa hi Kappa', emotes: '25:2-6,11-15'),
      )!;
      expect(event.message.fragments.map((f) => '${f.type}:${f.text}'), [
        'text:😀 ',
        'emote:Kappa',
        'text: hi ',
        'emote:Kappa',
      ]);
      expect(event.message.fragments[1].emote!.id, '25');
    });

    test('@mentions become mention fragments', () {
      final event = parseIrcPrivmsgToChatMessage(
        _line('m1', text: 'hey @Kounex! mail@example.com'),
      )!;
      expect(event.message.fragments.map((f) => '${f.type}:${f.text}'), [
        'text:hey ',
        'mention:@Kounex',
        'text:! mail@example.com',
      ]);
      expect(event.message.fragments[1].mention!.userLogin, 'kounex');
    });

    test('/me actions unwrap; escaped tags unescape; replies map', () {
      final event = parseIrcPrivmsgToChatMessage(
        _line(
          'r1',
          text: '\u0001ACTION waves\u0001',
          extra:
              ';reply-parent-msg-id=p1;reply-parent-msg-body=hello\\sthere'
              ';reply-parent-user-login=streamer'
              ';reply-parent-display-name=Streamer',
        ),
      )!;
      expect(event.message.text, 'waves');
      expect(event.reply!.parentMessageId, 'p1');
      expect(event.reply!.parentMessageBody, 'hello there');
      expect(event.reply!.parentUserName, 'Streamer');
    });

    test('non-PRIVMSG lines are skipped', () {
      expect(
        parseIrcPrivmsgToChatMessage(
          '@room-id=1;target-user-id=2;tmi-sent-ts=1 '
          ':tmi.twitch.tv CLEARCHAT #xqc someone',
        ),
        isNull,
      );
      expect(parseIrcPrivmsgToChatMessage('PING :tmi.twitch.tv'), isNull);
    });

    test('unescapeIrcTagValue', () {
      expect(unescapeIrcTagValue(r'a\sb\:c\\d'), r'a b;c\d');
    });
  });

  group('TwitchRecentMessagesService', () {
    test('asks for moderated rows hidden and parses PRIVMSGs', () async {
      Uri? requested;
      final service = TwitchRecentMessagesService(
        client: MockClient((request) async {
          requested = request.url;
          return http.Response(
            json.encode({
              'messages': [
                _line('a'),
                '@x=1 :tmi.twitch.tv CLEARCHAT #kounex',
                _line('b'),
              ],
              'error': null,
            }),
            200,
          );
        }),
      );
      final events = await service.fetch('kounex', limit: 50);

      expect(events.map((e) => e.messageId), ['a', 'b']);
      expect(requested!.path, '/api/v2/recent-messages/kounex');
      expect(requested!.queryParameters['limit'], '50');
      expect(requested!.queryParameters['hide_moderated_messages'], 'true');
    });

    test('non-200 throws', () async {
      final service = TwitchRecentMessagesService(
        client: MockClient((_) async => http.Response('{}', 400)),
      );
      await expectLater(service.fetch('x'), throwsException);
    });
  });

  group('TwitchChatStore history backfill', () {
    late Directory tempDir;
    late HiveTestHarness harness;
    late FakeTwitchEventSubService eventSub;
    late void Function(ChatMessageEvent) emitMessage;
    late void Function(TwitchEventSubState) emitState;
    late Completer<http.Response> historyGate;
    late List<String> requestedLogins;
    late TwitchChatStore store;

    TwitchChatStore newStore() => TwitchChatStore(
      authService: FakeTwitchAuthService(),
      ircSidecarFactory: (_) => FakeSilentIrcSidecar(),
      eventSubFactory: (onMessage, _, _, _, _, _, _, _, onState, _) {
        emitMessage = onMessage;
        emitState = onState;
        return eventSub;
      },
      badgeStoreResolver: () =>
          TwitchBadgeStore(service: FakeTwitchBadgeService()),
      isProResolver: () => true,
      recentMessagesService: TwitchRecentMessagesService(
        client: MockClient((request) {
          requestedLogins.add(request.url.pathSegments.last);
          return historyGate.future;
        }),
      ),
    );

    ChatMessageEvent live(String id) => ChatMessageEvent(
      broadcasterUserId: 'user-1',
      chatterUserId: '9',
      chatterUserLogin: 'viewer',
      chatterUserName: 'Viewer',
      messageId: id,
      message: ChatMessageText(text: id),
    );

    http.Response historyOf(List<String> ids) => http.Response(
      json.encode({
        'messages': [for (final id in ids) _line(id)],
        'error': null,
      }),
      200,
    );

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('twitch_history_test');
      harness = HiveTestHarness(tempDir);
      await harness.init();
      await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
      await Hive.openBox(HiveKeys.Settings.name);
      eventSub = FakeTwitchEventSubService();
      historyGate = Completer<http.Response>();
      requestedLogins = <String>[];
      store = newStore();
    });

    tearDown(() async {
      if (!historyGate.isCompleted) historyGate.complete(historyOf([]));
      await store.dispose();
      await harness.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    Future<void> settle() async {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('history lands above live rows, deduped, dimmed', () async {
      await store.startLogin();
      emitState(TwitchEventSubState.connected);
      emitMessage(live('live-1'));
      emitMessage(live('h3'));

      historyGate.complete(historyOf(['h1', 'h2', 'h3']));
      await settle();

      expect(requestedLogins, ['kounex']);
      expect(store.messages.map((m) => m.messageId), [
        'h1',
        'h2',
        'live-1',
        'h3',
      ]);
      expect(store.messages.first.isHistorical, isTrue);
      expect(
        store.messages.firstWhere((m) => m.messageId == 'h3').isHistorical,
        isFalse,
        reason: 'the live copy of a duplicate wins',
      );
    });

    test('history loads once per channel per session', () async {
      historyGate.complete(historyOf(['h1']));
      await store.startLogin();
      await settle();
      await store.connectChat();
      await settle();

      expect(requestedLogins, ['kounex']);
    });

    test('the settings toggle turns it off', () async {
      Hive.box(
        HiveKeys.Settings.name,
      ).put(SettingsKeys.TwitchChatLoadHistory.name, false);
      historyGate.complete(historyOf(['h1']));
      await store.startLogin();
      await settle();

      expect(requestedLogins, isEmpty);
      expect(store.messages, isEmpty);
    });

    test('a failed fetch is silent and retried on the next connect', () async {
      historyGate = Completer<http.Response>();
      unawaited(historyGate.future.catchError((_) => http.Response('', 500)));
      historyGate.completeError(const SocketException('offline'));
      await store.startLogin();
      await settle();
      expect(store.messages, isEmpty);
      expect(store.chatError, isNull);

      historyGate = Completer<http.Response>()..complete(historyOf(['h1']));
      await store.connectChat();
      await settle();
      expect(requestedLogins, ['kounex', 'kounex']);
      expect(store.messages.map((m) => m.messageId), ['h1']);
    });
  });

  group('TwitchChatStore resume catch-up', () {
    late Directory tempDir;
    late HiveTestHarness harness;
    late FakeTwitchEventSubService eventSub;
    late void Function(ChatMessageEvent) emitMessage;
    late void Function(TwitchEventSubState) emitState;
    late ChatHistoryStore history;
    late TwitchChatStore store;

    /// Every recent-messages request's `limit` (100 = join backfill,
    /// 800 = resume catch-up).
    late List<int> requestedLimits;

    /// Set to park the catch-up fetch mid-flight (live rows racing it).
    Completer<http.Response>? catchUpGate;

    /// Scripted catch-up rows when no gate parks the fetch.
    List<String> catchUpLines = const [];
    Object? catchUpThrows;

    final t0 = DateTime.fromMillisecondsSinceEpoch(1790196434556, isUtc: true);

    http.Response responseOf(List<String> lines) =>
        http.Response(json.encode({'messages': lines, 'error': null}), 200);

    TwitchChatStore newStore() => TwitchChatStore(
      authService: FakeTwitchAuthService(),
      ircSidecarFactory: (_) => FakeSilentIrcSidecar(),
      eventSubFactory: (onMessage, _, _, _, _, _, _, _, onState, _) {
        emitMessage = onMessage;
        emitState = onState;
        return eventSub;
      },
      badgeStoreResolver: () =>
          TwitchBadgeStore(service: FakeTwitchBadgeService()),
      isProResolver: () => true,
      chatHistoryResolver: () => history,
      recentMessagesService: TwitchRecentMessagesService(
        client: MockClient((request) {
          final limit = int.parse(request.url.queryParameters['limit']!);
          requestedLimits.add(limit);

          /// 100 = join backfill, 800 = resume catch-up.
          if (limit == 100) {
            return Future.value(responseOf(const []));
          }
          final gate = catchUpGate;
          if (gate != null) return gate.future;
          final throws = catchUpThrows;
          if (throws != null) return Future.error(throws);
          return Future.value(responseOf(catchUpLines));
        }),
      ),
    );

    ChatMessageEvent liveAt(String id, DateTime at) => ChatMessageEvent(
      broadcasterUserId: 'user-1',
      chatterUserId: '9',
      chatterUserLogin: 'viewer',
      chatterUserName: 'Viewer',
      messageId: id,
      message: ChatMessageText(text: id),
      receivedAt: at,
    );

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('twitch_resume_test');
      harness = HiveTestHarness(tempDir);
      await harness.init();
      await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
      await Hive.openBox(HiveKeys.Settings.name);
      eventSub = FakeTwitchEventSubService();
      history = ChatHistoryStore();
      requestedLimits = <int>[];
      catchUpGate = null;
      catchUpLines = const [];
      catchUpThrows = null;
      store = newStore();
    });

    tearDown(() async {
      if (catchUpGate != null && !catchUpGate!.isCompleted) {
        catchUpGate!.complete(responseOf(const []));
      }
      await store.dispose();
      await harness.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    Future<void> settle() async {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    /// Logged in, "connected", with the join backfill answered (empty).
    Future<void> startConnected() async {
      await store.startLogin();
      await settle();
      emitState(TwitchEventSubState.connected);
      await settle();
      requestedLimits.clear();
    }

    test('catch-up rows land sorted mid-buffer, deduped, not historical, '
        'silent for text-to-speech', () async {
      final heardLive = <String>[];
      store.liveMessages.listen((m) => heardLive.add(m.messageId));
      await startConnected();
      emitMessage(liveAt('pre-1', t0));
      emitMessage(liveAt('pre-2', t0.add(const Duration(seconds: 10))));

      catchUpGate = Completer<http.Response>();
      store.reconnectAfterResume();
      await settle();
      expect(requestedLimits, [800]); // 800 = resume catch-up

      /// A live row beats the fetch — the catch-up must slot in BEFORE
      /// it (mid-buffer insert, not append).
      emitMessage(liveAt('live-1', t0.add(const Duration(seconds: 20))));
      catchUpGate!.complete(
        responseOf([
          _line('pre-2', sentTs: t0.millisecondsSinceEpoch + 10000),
          _line('cu-1', sentTs: t0.millisecondsSinceEpoch + 12000),
          _line('cu-2', sentTs: t0.millisecondsSinceEpoch + 15000),
          _line('live-1', sentTs: t0.millisecondsSinceEpoch + 20000),
        ]),
      );
      await settle();

      expect(store.messages.map((m) => m.messageId), [
        'pre-1',
        'pre-2',
        'cu-1',
        'cu-2',
        'live-1',
      ]);
      expect(
        store.messages
            .where((m) => m.messageId.startsWith('cu-'))
            .every((m) => !m.isHistorical),
        isTrue,
      );

      /// Adjacency (2s): the window reached back — no gap marker.
      expect(store.resumeGapBoundaries, isEmpty);

      /// Text-to-speech listens to live arrivals only — the catch-up
      /// block must not be read aloud.
      expect(heardLive, ['pre-1', 'pre-2', 'live-1']);
    });

    test('the gap marker lands on the oldest catch-up row when the window '
        'did not reach back', () async {
      await startConnected();
      emitMessage(liveAt('pre-1', t0));

      catchUpLines = [
        _line('cu-1', sentTs: t0.millisecondsSinceEpoch + 600000),
        _line('cu-2', sentTs: t0.millisecondsSinceEpoch + 630000),
      ];
      store.reconnectAfterResume();
      await settle();

      expect(store.messages.map((m) => m.messageId), ['pre-1', 'cu-1', 'cu-2']);
      expect(store.resumeGapBoundaries, {'cu-1'});
    });

    test('no false gap marker when live rows bridge a truncated history '
        'window', () async {
      await startConnected();
      emitMessage(liveAt('pre-1', t0));

      catchUpGate = Completer<http.Response>();
      store.reconnectAfterResume();
      await settle();
      expect(requestedLimits, [800]); // 800 = resume catch-up

      /// Live rows arrive mid-fetch and bridge the window right up to the
      /// fetched row…
      emitMessage(liveAt('live-1', t0.add(const Duration(minutes: 1))));
      emitMessage(
        liveAt(
          'live-2',
          t0.add(const Duration(minutes: 3) - const Duration(seconds: 1)),
        ),
      );

      /// …but the fetch itself is truncated: its oldest row is minutes
      /// past the pre-resume tail. Against the stale tail this raised a
      /// false "missing" divider; against the actual predecessor
      /// (live-2, 1s away) it must not.
      catchUpGate!.complete(
        responseOf([_line('cu-1', sentTs: t0.millisecondsSinceEpoch + 180000)]),
      );
      await settle();

      expect(store.messages.map((m) => m.messageId), [
        'pre-1',
        'live-1',
        'live-2',
        'cu-1',
      ]);
      expect(store.resumeGapBoundaries, isEmpty);
    });

    test(
      'a /clear banner keeps its anchor row across the catch-up insert',
      () async {
        await startConnected();
        emitMessage(liveAt('pre-1', t0));
        emitMessage(liveAt('pre-2', t0.add(const Duration(seconds: 10))));
        store.applyChatClear();

        catchUpLines = [
          _line('cu-1', sentTs: t0.millisecondsSinceEpoch + 12000),
          _line('cu-2', sentTs: t0.millisecondsSinceEpoch + 15000),
        ];
        store.reconnectAfterResume();
        await settle();

        /// The insert shifts the position-derived seqs of the rows below it
        /// — the banner's afterSeq must move with its anchor instead of
        /// hopping down into the catch-up block.
        final timeline = store.messagesWithNotices();
        final bannerIndex = timeline.indexWhere(
          (item) =>
              item is ChatSystemNotice &&
              item.kind == ChatSystemNoticeKind.chatCleared,
        );
        expect(bannerIndex, greaterThan(0));
        expect(
          (timeline[bannerIndex - 1] as ChatMessageEvent).messageId,
          'pre-2',
          reason: 'the banner stays glued to the last pre-clear row',
        );
        expect(
          (timeline[bannerIndex + 1] as ChatMessageEvent).messageId,
          'cu-1',
          reason: 'and still sorts above the catch-up block',
        );
      },
    );

    test(
      'cap trim after the insert keeps feeding the session history',
      () async {
        await startConnected();
        for (var i = 0; i < 500; i++) {
          emitMessage(liveAt('p$i', t0.add(Duration(seconds: i))));
        }
        expect(store.messages, hasLength(500));

        catchUpLines = [
          for (var i = 0; i < 30; i++)
            _line(
              'cu-$i',
              sentTs: t0.millisecondsSinceEpoch + 500000 + i * 1000,
            ),
        ];
        store.reconnectAfterResume();
        await settle();

        expect(store.messages, hasLength(500));
        expect(store.messages.first.messageId, 'p30');
        expect(store.messages.last.messageId, 'cu-29');
        expect(history.length, 30);
        expect(
          history
              .historyFor(
                platform: ChatHistoryPlatform.twitch,
                channelKey: 'user-1',
                authorKey: '9',
              )
              .map((e) => (e.message as ChatMessageEvent).messageId),
          [for (var i = 0; i < 30; i++) 'p$i'],
        );
      },
    );

    test('a backing-off session reconnects immediately', () async {
      await startConnected();
      emitState(TwitchEventSubState.reconnecting);
      await settle();
      expect(store.chatConnection, TwitchChatConnectionState.reconnecting);
      eventSub.connectCalled = false;

      store.reconnectAfterResume();
      await settle();

      expect(eventSub.disposeCalled, isTrue);
      expect(eventSub.connectCalled, isTrue);
      expect(store.chatConnection, TwitchChatConnectionState.connecting);
    });

    test('a live session is not disturbed, the catch-up still runs', () async {
      await startConnected();
      eventSub.connectCalled = false;

      store.reconnectAfterResume();
      await settle();

      expect(eventSub.disposeCalled, isFalse);
      expect(eventSub.connectCalled, isFalse);
      expect(store.chatConnection, TwitchChatConnectionState.live);
      expect(requestedLimits, [800]); // 800 = resume catch-up
    });

    test('no chat session: the hook is a no-op', () async {
      store.reconnectAfterResume();
      await settle();
      expect(requestedLimits, isEmpty);
      expect(eventSub.connectCalled, isFalse);
    });

    test('the join-history setting also gates the catch-up', () async {
      Hive.box(
        HiveKeys.Settings.name,
      ).put(SettingsKeys.TwitchChatLoadHistory.name, false);
      await store.startLogin();
      await settle();
      emitState(TwitchEventSubState.connected);
      await settle();
      requestedLimits.clear();

      store.reconnectAfterResume();
      await settle();
      expect(requestedLimits, isEmpty);
    });

    test('a failed fetch is silent', () async {
      await startConnected();
      emitMessage(liveAt('pre-1', t0));
      catchUpThrows = const SocketException('offline');

      store.reconnectAfterResume();
      await settle();

      expect(store.messages.map((m) => m.messageId), ['pre-1']);
      expect(store.chatError, isNull);
      expect(store.resumeGapBoundaries, isEmpty);
    });
  });
}
