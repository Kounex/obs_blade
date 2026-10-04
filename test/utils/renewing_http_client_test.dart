import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/utils/renewing_http_client.dart';
import 'package:obs_blade/utils/youtube/youtube_live_chat_service.dart';

/// A client whose pooled connections iOS took away while the app was
/// suspended: every request fails the way Settings → Logs showed it
http.Client brokenPool() =>
    MockClient((_) async => throw http.ClientException('Write failed'));

void main() {
  test('a connection failure renews the client; the next request goes out '
      'on a fresh one', () async {
    var created = 0;
    final client = RenewingHttpClient(
      create: () => ++created == 1
          ? brokenPool()
          : MockClient((_) async => http.Response('ok', 200)),
    );
    expect(created, 1);

    await expectLater(
      client.get(Uri.parse('https://example.com')),
      throwsA(isA<http.ClientException>()),
    );
    expect(created, 2);
    final response = await client.get(Uri.parse('https://example.com'));
    expect(response.body, 'ok');
    expect(created, 2);
  });

  test(
    'an answer from the server (even an error status) keeps the client',
    () async {
      var created = 0;
      final client = RenewingHttpClient(
        create: () {
          created++;
          return MockClient((_) async => http.Response('nope', 503));
        },
      );
      final response = await client.get(Uri.parse('https://example.com'));
      expect(response.statusCode, 503);
      expect(created, 1);
    },
  );

  test('a socket error renews too; other errors don\'t', () async {
    var created = 0;
    var throwSocket = true;
    final client = RenewingHttpClient(
      create: () {
        created++;
        return MockClient(
          (_) async => throwSocket
              ? throw const SocketException('Broken pipe')
              : throw StateError('bug'),
        );
      },
    );
    await expectLater(
      client.get(Uri.parse('https://example.com')),
      throwsA(isA<SocketException>()),
    );
    expect(created, 2);
    throwSocket = false;
    await expectLater(
      client.get(Uri.parse('https://example.com')),
      throwsA(isA<StateError>()),
    );
    expect(created, 2);
  });

  test(
    'renewAll (app resume) gives every live client fresh connections',
    () async {
      var createdA = 0;
      var createdB = 0;
      final a = RenewingHttpClient(
        create: () {
          createdA++;
          return MockClient((_) async => http.Response('a', 200));
        },
      );
      final b = RenewingHttpClient(
        create: () {
          createdB++;
          return MockClient((_) async => http.Response('b', 200));
        },
      );
      RenewingHttpClient.renewAll();
      expect(createdA, 2);
      expect(createdB, 2);

      /// A closed client stays closed
      b.close();
      RenewingHttpClient.renewAll();
      expect(createdA, 3);
      expect(createdB, 2);
      expect((await a.get(Uri.parse('https://example.com'))).body, 'a');
    },
  );

  /// Review finding: IOClient.close() always forces - renewing must not
  /// abort a request still running (a send, a token poll, a refresh)
  test('renew / renewAll let a running request finish (real dart:io '
      'client against a local server)', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      request.response.write('slow ok');
      await request.response.close();
    });
    final url = Uri.parse('http://127.0.0.1:${server.port}/');
    final client = RenewingHttpClient();
    addTearDown(client.close);

    final running = client.get(url);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    client.renew();
    RenewingHttpClient.renewAll();
    expect((await running).body, 'slow ok');

    /// And the fresh client works
    expect((await client.get(url)).body, 'slow ok');
  });

  /// The reported case end to end: after the background stretch the poll
  /// failed with "Write failed" - and every retry with it, until restart
  test('YouTube chat poll: the retry after "Write failed" reads again, '
      'no restart needed', () async {
    var created = 0;
    final service = YouTubeLiveChatService(
      client: RenewingHttpClient(
        create: () => ++created == 1
            ? brokenPool()
            : MockClient(
                (_) async => http.Response(
                  jsonEncode({
                    'pollingIntervalMillis': 5000,
                    'nextPageToken': 'next',
                    'items': <Object>[],
                  }),
                  200,
                ),
              ),
      ),
    );

    await expectLater(
      service.listMessages('chat-1', null, apiKey: 'key'),
      throwsA(isA<http.ClientException>()),
    );
    final page = await service.listMessages('chat-1', null, apiKey: 'key');
    expect(page.nextPageToken, 'next');
  });
}
