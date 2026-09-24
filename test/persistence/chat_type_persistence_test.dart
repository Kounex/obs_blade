import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce/src/binary/binary_reader_impl.dart';
import 'package:hive_ce/src/binary/binary_writer_impl.dart';
import 'package:obs_blade/models/enums/chat_type.dart';

ChatType roundTrip(ChatType type) {
  final writer = BinaryWriterImpl(Hive);
  ChatTypeAdapter().write(writer, type);
  return ChatTypeAdapter().read(BinaryReaderImpl(writer.toBytes(), Hive));
}

void main() {
  group('ChatType persistence', () {
    test('every value round-trips through its adapter byte', () {
      for (final type in ChatType.values) {
        expect(roundTrip(type), type);
      }
    });

    test('existing ordinals never move (append-only)', () {
      final bytes = {
        for (final type in ChatType.values)
          type: (BinaryWriterImpl(
            Hive,
          )..let((w) => ChatTypeAdapter().write(w, type))).toBytes().single,
      };
      expect(bytes, {
        ChatType.Twitch: 0,
        ChatType.YouTube: 1,
        ChatType.Owncast: 2,
        ChatType.Kick: 3,
        ChatType.Combined: 4,
      });
    });

    test('an unknown byte (a newer build) reads as Twitch', () {
      final writer = BinaryWriterImpl(Hive)..writeByte(99);
      expect(
        ChatTypeAdapter().read(BinaryReaderImpl(writer.toBytes(), Hive)),
        ChatType.Twitch,
      );
    });

    test('Combined is the only native-only type', () {
      expect(
        [
          for (final type in ChatType.values)
            if (isNativeOnly(type)) type,
        ],
        [ChatType.Combined],
      );
    });
  });
}

extension<T> on T {
  T let(void Function(T) block) {
    block(this);
    return this;
  }
}
