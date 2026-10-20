import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:obs_blade/utils/youtube/stream_list/stream_list.pbgrpc.dart';
import 'package:obs_blade/utils/youtube/youtube_live_chat_service.dart';
import 'package:obs_blade/utils/youtube/youtube_live_chat_stream.dart';

/// The real streamer against an in-process gRPC server (plain HTTP/2 on
/// loopback): what "opened" means, how calls end, and that a connection
/// that goes silent fails the call (grpc's own keepalive would only
/// finish it gracefully and leave the call waiting).
class _ChatService extends V3DataLiveChatMessageServiceBase {
  Stream<LiveChatMessageListResponse> Function(
    ServiceCall call,
    LiveChatMessageListRequest request,
  )?
  handler;

  final List<Map<String, String>> metadata = [];
  final List<LiveChatMessageListRequest> requests = [];

  @override
  Stream<LiveChatMessageListResponse> streamList(
    ServiceCall call,
    LiveChatMessageListRequest request,
  ) {
    this.metadata.add(Map.of(call.clientMetadata ?? const {}));
    this.requests.add(request);
    return this.handler!(call, request);
  }
}

/// Forwards bytes both ways until [freeze] - then drops them without
/// closing anything, like a dead zone.
class _FreezingProxy {
  final ServerSocket _server;
  bool frozen = false;
  final List<Socket> _sockets = [];

  _FreezingProxy._(this._server);

  static Future<_FreezingProxy> to(int port) async {
    final proxy = _FreezingProxy._(
      await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
    );
    proxy._server.listen((client) async {
      final upstream = await Socket.connect(InternetAddress.loopbackIPv4, port);
      proxy._sockets.addAll([client, upstream]);
      client.listen((data) {
        if (!proxy.frozen) upstream.add(data);
      }, onError: (_) {});
      upstream.listen((data) {
        if (!proxy.frozen) client.add(data);
      }, onError: (_) {});
    });
    return proxy;
  }

  int get port => this._server.port;

  void freeze() => this.frozen = true;

  Future<void> close() async {
    for (final socket in this._sockets) {
      socket.destroy();
    }
    await this._server.close();
  }
}

LiveChatMessageListResponse response(String token, [List<String>? ids]) =>
    LiveChatMessageListResponse(
      nextPageToken: token,
      items: [
        for (final id in ids ?? const <String>[])
          LiveChatMessage(
            id: id,
            snippet: LiveChatMessageSnippet(
              type: LiveChatMessageSnippet_TypeWrapper_Type.TEXT_MESSAGE_EVENT,
              publishedAt: '2026-10-19T12:00:00Z',
              displayMessage: 'text $id',
              textMessageDetails: LiveChatTextMessageDetails(
                messageText: 'text $id',
              ),
            ),
          ),
      ],
    );

void main() {
  late Server server;
  late _ChatService service;

  setUp(() async {
    service = _ChatService();
    server = Server.create(services: [service]);
    await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
  });

  tearDown(() => server.shutdown());

  YouTubeLiveChatStreamer streamer({
    int? port,
    Duration? openGrace,
    Duration? callTimeout,
  }) => YouTubeLiveChatStreamer(
    host: '127.0.0.1',
    port: port ?? server.port!,
    secure: false,
    pingInterval: const Duration(milliseconds: 100),
    pingTimeout: const Duration(milliseconds: 300),
    openGrace: openGrace ?? YouTubeLiveChatStreamer.kOpenGrace,
    callTimeout: callTimeout ?? YouTubeLiveChatStreamer.kCallTimeout,
  );

  /// Collects one call: pages, the error, whether it opened
  Future<({List<YouTubeLiveChatPage> pages, Object? error, bool opened})> run(
    Stream<YouTubeLiveChatPage> Function(void Function() onOpen) open,
  ) async {
    var opened = false;
    final pages = <YouTubeLiveChatPage>[];
    Object? error;
    await open(() => opened = true)
        .handleError((Object e) => error = e)
        .forEach(pages.add)
        .timeout(const Duration(seconds: 10));
    return (pages: pages, error: error, opened: opened);
  }

  test('pages arrive in order, the call opens, the server closing it ends '
      'the stream; key and token go out', () async {
    service.handler = (call, request) async* {
      yield response('t1', ['a', 'b']);
      yield response('t2', ['c']);
    };

    final result = await run(
      (onOpen) => streamer().stream(
        'chat-1',
        'resume-token',
        apiKey: 'key-1',
        onOpen: onOpen,
      ),
    );

    expect(result.error, isNull);
    expect(result.opened, isTrue);
    expect(result.pages.map((p) => p.nextPageToken), ['t1', 't2']);
    expect(result.pages.first.messages.map((m) => m.id), ['a', 'b']);
    expect(service.metadata.single['x-goog-api-key'], 'key-1');
    expect(service.requests.single.liveChatId, 'chat-1');
    expect(service.requests.single.pageToken, 'resume-token');
    expect(service.requests.single.part, ['id', 'snippet', 'authorDetails']);
  });

  test('a refused call (Trailers-Only error) never opens - not billed, '
      'the poll explains it', () async {
    service.handler = (call, request) =>
        Stream.error(const GrpcError.permissionDenied('no'));

    final result = await run(
      (onOpen) => streamer().stream('chat-1', null, onOpen: onOpen),
    );

    expect(result.opened, isFalse);
    expect(result.error, isA<YouTubeStreamFallbackException>());
  });

  test(
    'Google\'s refusal (headers first, then the error) never opens',
    () async {
      service.handler = (call, request) async* {
        call.sendHeaders();
        await Future<void>.delayed(const Duration(milliseconds: 10));
        throw const GrpcError.invalidArgument('API key not valid');
      };

      final result = await run(
        (onOpen) => streamer().stream('chat-1', null, onOpen: onOpen),
      );

      expect(result.opened, isFalse);
      expect(result.error, isA<YouTubeStreamFallbackException>());
    },
  );

  test('a quiet chat: no headers until the empty closing answer - the call '
      'opens after the grace while it runs, and ends cleanly', () async {
    final release = Completer<void>();
    service.handler = (call, request) async* {
      await release.future;
      yield response('t2');
    };

    var opened = false;
    final done = Completer<void>();
    final pages = <YouTubeLiveChatPage>[];
    streamer(openGrace: const Duration(milliseconds: 200))
        .stream('chat-1', 't1', onOpen: () => opened = true)
        .listen(pages.add, onDone: done.complete);

    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(opened, isTrue);
    expect(pages, isEmpty);

    release.complete();
    await done.future.timeout(const Duration(seconds: 5));
    expect(pages.single.nextPageToken, 't2');
  });

  test('a call still open past the timeout (Google ends them ~10 s in) is '
      'dropped - reconnect, not a frozen "connected"', () async {
    service.handler = (call, request) async* {
      yield response('t1', ['a']);
      await Future<void>.delayed(const Duration(minutes: 5));
    };

    final result = await run(
      (onOpen) => streamer(
        callTimeout: const Duration(milliseconds: 500),
      ).stream('chat-1', null, onOpen: onOpen),
    );

    expect(result.opened, isTrue);
    expect(result.pages, hasLength(1));
    expect(result.error, isA<YouTubeStreamDroppedException>());
  });

  test('a clean end before the grace opens the call too', () async {
    service.handler = (call, request) async* {};

    final result = await run(
      (onOpen) => streamer().stream('chat-1', 't1', onOpen: onOpen),
    );

    expect(result.error, isNull);
    expect(result.opened, isTrue);
  });

  test(
    'FAILED_PRECONDITION after rows: the chat ended (or was disabled)',
    () async {
      service.handler = (call, request) async* {
        yield response('t1', ['a']);
        throw const GrpcError.failedPrecondition('LIVE_CHAT_ENDED');
      };

      final result = await run(
        (onOpen) => streamer().stream('chat-1', null, onOpen: onOpen),
      );

      expect(result.opened, isTrue);
      expect(result.pages, hasLength(1));
      expect(result.error, isA<YouTubeChatEndedException>());
    },
  );

  test('nothing listening: dropped, never opened', () async {
    final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = closed.port;
    await closed.close();

    final result = await run(
      (onOpen) => streamer(port: port).stream('chat-1', null, onOpen: onOpen),
    );

    expect(result.opened, isFalse);
    expect(result.error, isA<YouTubeStreamDroppedException>());
  });

  test('cancelling the subscription closes the call on the server', () async {
    final cancelled = Completer<void>();
    service.handler = (call, request) async* {
      yield response('t1', ['a']);
      while (!call.isCanceled) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      cancelled.complete();
    };

    final first = Completer<void>();
    final subscription = streamer()
        .stream('chat-1', null)
        .listen((_) => first.isCompleted ? null : first.complete());
    await first.future.timeout(const Duration(seconds: 5));
    await subscription.cancel();

    await cancelled.future.timeout(const Duration(seconds: 5));
  });

  test('a connection that goes silent mid-call fails the call (dropped) '
      'instead of hanging', () async {
    final proxy = await _FreezingProxy.to(server.port!);
    addTearDown(proxy.close);
    service.handler = (call, request) async* {
      yield response('t1', ['a']);

      /// A quiet chat: the call stays open, nothing more to send
      await Future<void>.delayed(const Duration(minutes: 5));
    };

    final pages = <YouTubeLiveChatPage>[];
    final error = Completer<Object>();
    final subscription = streamer(port: proxy.port)
        .stream('chat-1', null)
        .listen((page) {
          pages.add(page);
          proxy.freeze();
        }, onError: (Object e) => error.complete(e));
    addTearDown(subscription.cancel);

    final failure = await error.future.timeout(const Duration(seconds: 5));
    expect(pages, hasLength(1));
    expect(failure, isA<YouTubeStreamDroppedException>());
  });
}
