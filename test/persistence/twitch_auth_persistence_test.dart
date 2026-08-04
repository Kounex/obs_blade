import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';

import 'support/hive_test_harness.dart';

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('twitch_auth_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
  });

  tearDown(() async {
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('TwitchAuth persistence', () {
    test('round-trips through its box under the current key', () async {
      final box = await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
      final auth = TwitchAuth(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
        scopes: const ['user:read:chat'],
        userId: '1234',
        userLogin: 'kounex',
        userDisplayName: 'Kounex',
      );

      await box.put(TwitchAuth.kBoxKey, auth);
      final read = box.get(TwitchAuth.kBoxKey);

      expect(read?.accessToken, 'access-1');
      expect(read?.refreshToken, 'refresh-1');
      expect(read?.scopes, ['user:read:chat']);
      expect(read?.userLogin, 'kounex');
      expect(read?.userDisplayName, 'Kounex');
    });

    test('expiresWithin / isExpired honor the window', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final soon = TwitchAuth(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtMs: now + 60 * 1000,
        scopes: const [],
      );
      final later = TwitchAuth(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtMs: now + 3600 * 1000,
        scopes: const [],
      );
      final past = TwitchAuth(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtMs: now - 1000,
        scopes: const [],
      );

      expect(soon.expiresWithin(const Duration(minutes: 5)), isTrue);
      expect(later.expiresWithin(const Duration(minutes: 5)), isFalse);
      expect(soon.isExpired, isFalse);
      expect(past.isExpired, isTrue);
    });
  });
}
