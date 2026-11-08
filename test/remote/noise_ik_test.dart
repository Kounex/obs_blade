import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/remote/noise_ik.dart';

Uint8List _hex(String hex) => Uint8List.fromList([
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
]);

String _toHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

Future<(NoiseTransport, NoiseTransport)> _pair() async {
  final bridge = await NoiseKeyPair.generate();
  final phone = await NoiseKeyPair.generate();
  final initiator = NoiseIKInitiator(
    localStatic: phone,
    remoteStatic: bridge.publicKey,
  );
  final responder = NoiseIKResponder(localStatic: bridge);
  await responder.readMessage1(await initiator.writeMessage1());
  expect(responder.remoteStatic, phone.publicKey);
  final (message2, bridgeSide) = await responder.writeMessage2();
  final (_, phoneSide) = await initiator.readMessage2(message2);
  return (phoneSide, bridgeSide);
}

void main() {
  /// The published cacophony vector for exactly this protocol
  /// (github.com/haskell-cryptography/cacophony, vectors/cacophony.txt):
  /// both roles must produce its bytes - the bridge uses snow, which is
  /// checked against the same vectors.
  test('matches the cacophony test vector, both roles', () async {
    final v =
        jsonDecode(
              File(
                'test/remote/fixtures/noise_ik_cacophony.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    expect(v['protocol_name'], kNoiseProtocolName);
    final messages = (v['messages'] as List).cast<Map<String, dynamic>>();

    final initiator = NoiseIKInitiator(
      localStatic: await NoiseKeyPair.fromPrivate(_hex(v['init_static'])),
      remoteStatic: _hex(v['init_remote_static']),
      prologue: _hex(v['init_prologue']),
      ephemeral: await NoiseKeyPair.fromPrivate(_hex(v['init_ephemeral'])),
    );
    final responder = NoiseIKResponder(
      localStatic: await NoiseKeyPair.fromPrivate(_hex(v['resp_static'])),
      prologue: _hex(v['resp_prologue']),
      ephemeral: await NoiseKeyPair.fromPrivate(_hex(v['resp_ephemeral'])),
    );

    final message1 = await initiator.writeMessage1(
      _hex(messages[0]['payload']),
    );
    expect(_toHex(message1), messages[0]['ciphertext']);
    expect(
      _toHex(await responder.readMessage1(message1)),
      messages[0]['payload'],
    );

    final (message2, responderTransport) = await responder.writeMessage2(
      _hex(messages[1]['payload']),
    );
    expect(_toHex(message2), messages[1]['ciphertext']);
    final (payload2, initiatorTransport) = await initiator.readMessage2(
      message2,
    );
    expect(_toHex(payload2), messages[1]['payload']);
    expect(_toHex(initiatorTransport.handshakeHash), v['handshake_hash']);
    expect(_toHex(responderTransport.handshakeHash), v['handshake_hash']);

    // Transport messages alternate, the initiator first.
    for (var i = 2; i < messages.length; i++) {
      final fromInitiator = i.isEven;
      final sender = fromInitiator ? initiatorTransport : responderTransport;
      final receiver = fromInitiator ? responderTransport : initiatorTransport;
      final frame = sender.encrypt(_hex(messages[i]['payload']));
      expect(_toHex(frame), messages[i]['ciphertext'], reason: 'message $i');
      expect(_toHex(receiver.decrypt(frame)), messages[i]['payload']);
    }
  });

  test(
    'a message of any size crosses as frames within the Noise limit',
    () async {
      final (phone, bridge) = await _pair();
      for (final size in [0, 10, kE2eMaxChunk, kE2eMaxChunk + 1, 200000]) {
        final message = Uint8List.fromList(List.generate(size, (i) => i % 251));
        final frames = phone.seal(message);
        expect(frames.length, size == 0 ? 1 : (size / kE2eMaxChunk).ceil());
        expect(frames.every((f) => f.length <= kNoiseMaxMessage), isTrue);
        Uint8List? got;
        for (final frame in frames) {
          expect(got, isNull, reason: 'complete before its last frame');
          got = bridge.open(frame);
        }
        expect(got, message);
        final back = bridge.seal(message).map(phone.open).toList().last;
        expect(back, message);
      }
    },
  );

  test(
    'a wrong bridge key, a tampered or reordered frame never opens',
    () async {
      final phone = await NoiseKeyPair.generate();
      final bridge = await NoiseKeyPair.generate();
      final impostor = await NoiseKeyPair.generate();
      // The phone pinned [bridge]; [impostor] (e.g. the relay) answers.
      final initiator = NoiseIKInitiator(
        localStatic: phone,
        remoteStatic: bridge.publicKey,
      );
      final message1 = await initiator.writeMessage1();
      await expectLater(
        NoiseIKResponder(localStatic: impostor).readMessage1(message1),
        throwsA(isA<NoiseException>()),
      );

      var (sender, receiver) = await _pair();
      final frames = sender.seal(Uint8List(3 * kE2eMaxChunk));
      final tampered = Uint8List.fromList(frames[0])..[5] ^= 1;
      expect(() => receiver.open(tampered), throwsA(isA<NoiseException>()));

      (sender, receiver) = await _pair();
      final ordered = sender.seal(Uint8List(3 * kE2eMaxChunk));
      expect(() => receiver.open(ordered[1]), throwsA(isA<NoiseException>()));
    },
  );
}
