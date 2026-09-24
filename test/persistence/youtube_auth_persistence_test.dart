import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce/src/binary/binary_reader_impl.dart';
import 'package:hive_ce/src/binary/binary_writer_impl.dart';
import 'package:obs_blade/models/youtube_auth.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';

import 'support/hive_test_harness.dart';

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('youtube_auth_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
  });

  tearDown(() async {
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('YouTubeAuth persistence', () {
    test('round-trips through its box under the current key', () async {
      final box = await Hive.openBox<YouTubeAuth>(HiveKeys.YouTubeAuth.name);
      final auth = YouTubeAuth(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
        scopes: const ['https://www.googleapis.com/auth/youtube'],
        channelTitle: 'Kounex',
      );

      await box.put(YouTubeAuth.kBoxKey, auth);
      final read = box.get(YouTubeAuth.kBoxKey);

      expect(read?.accessToken, 'access-1');
      expect(read?.refreshToken, 'refresh-1');
      expect(read?.scopes, ['https://www.googleapis.com/auth/youtube']);
      expect(read?.channelTitle, 'Kounex');
    });

    test('round-trips the own channel id', () async {
      final box = await Hive.openBox<YouTubeAuth>(HiveKeys.YouTubeAuth.name);
      await box.put(
        YouTubeAuth.kBoxKey,
        YouTubeAuth(
          accessToken: 'a',
          refreshToken: 'r',
          expiresAtMs: 0,
          scopes: const [],
          channelTitle: 'My Channel',
          channelId: 'UCownchannel000000000000',
        ),
      );

      expect(
        box.get(YouTubeAuth.kBoxKey)?.channelId,
        'UCownchannel000000000000',
      );
    });

    test('a record written before channelId existed still reads', () {
      /// The exact 5-field frame older builds wrote (fields 0-4).
      final writer = BinaryWriterImpl(Hive);
      writer
        ..writeByte(5)
        ..writeByte(0)
        ..write('legacy-access')
        ..writeByte(1)
        ..write('legacy-refresh')
        ..writeByte(2)
        ..write(0)
        ..writeByte(3)
        ..write(<String>['https://www.googleapis.com/auth/youtube'])
        ..writeByte(4)
        ..write('My Channel');

      final read = YouTubeAuthAdapter().read(
        BinaryReaderImpl(writer.toBytes(), Hive),
      );

      expect(read.accessToken, 'legacy-access');
      expect(read.channelTitle, 'My Channel');
      expect(read.channelId, isNull);
    });

    test('expiresWithin / isExpired honor the window', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final soon = YouTubeAuth(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtMs: now + 60 * 1000,
        scopes: const [],
      );
      final later = YouTubeAuth(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtMs: now + 3600 * 1000,
        scopes: const [],
      );
      final past = YouTubeAuth(
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
