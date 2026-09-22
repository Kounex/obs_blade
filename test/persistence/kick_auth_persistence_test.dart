import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/kick_auth.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';

import 'support/hive_test_harness.dart';

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kick_auth_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
  });

  tearDown(() async {
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('KickAuth persistence', () {
    test('round-trips through its box under the current key', () async {
      final box = await Hive.openBox<KickAuth>(HiveKeys.KickAuth.name);
      final auth = KickAuth(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
        scopes: const [
          'user:read',
          'chat:write',
          'moderation:ban',
          'moderation:chat_message:manage',
        ],
        userId: 4242,
        username: 'Kicker',
        profilePicture: 'https://pic.example/k.png',
      );

      await box.put(KickAuth.kBoxKey, auth);
      final read = box.get(KickAuth.kBoxKey);

      expect(read?.accessToken, 'access-1');
      expect(read?.refreshToken, 'refresh-1');
      expect(read?.scopes, contains('moderation:ban'));
      expect(read?.userId, 4242);
      expect(read?.username, 'Kicker');
      expect(read?.profilePicture, 'https://pic.example/k.png');
    });

    test('round-trips with the identity fields absent', () async {
      final box = await Hive.openBox<KickAuth>(HiveKeys.KickAuth.name);
      final auth = KickAuth(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
        scopes: const [],
      );

      await box.put(KickAuth.kBoxKey, auth);
      final read = box.get(KickAuth.kBoxKey);

      expect(read?.userId, isNull);
      expect(read?.username, isNull);
      expect(read?.profilePicture, isNull);
    });

    test('expiresWithin / isExpired honor the window', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final soon = KickAuth(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtMs: now + 60 * 1000,
        scopes: const [],
      );
      final later = KickAuth(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtMs: now + 3600 * 1000,
        scopes: const [],
      );
      final past = KickAuth(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtMs: now - 1000,
        scopes: const [],
      );

      expect(soon.expiresWithin(const Duration(minutes: 5)), isTrue);
      expect(later.expiresWithin(const Duration(minutes: 5)), isFalse);
      expect(past.isExpired, isTrue);
      expect(later.isExpired, isFalse);
    });
  });
}
