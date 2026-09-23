import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/utils/twitch/twitch_recent_messages_service.dart';

/// Suite-wide defaults (picked up by `flutter test` for every file under
/// `test/`): no test may reach the real network through a default-built
/// service. Tests that exercise a service inject their own client.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TwitchRecentMessagesService.debugDefaultClient = MockClient(
    (_) async => http.Response('{"messages":[],"error":null}', 200),
  );
  await testMain();
}
