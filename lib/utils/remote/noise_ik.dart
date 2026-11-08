import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';

/// End-to-end encryption between the app and the bridge next to OBS
/// (Pro remote access): the relay forwards frames it can't read.
///
/// `Noise_IK_25519_ChaChaPoly_SHA256` (noiseprotocol.org, rev. 34), the
/// app as initiator: it knows the bridge's static key from pairing (sent
/// through OBS, never via the relay). Mirrors `desktop/core/src/e2e.rs`
/// (snow); checked against the published cacophony test vector.
const String kNoiseProtocolName = 'Noise_IK_25519_ChaChaPoly_SHA256';

/// Binds every session to this protocol (both sides use it).
final Uint8List kRemotePrologue = Uint8List.fromList(
  utf8.encode('obs-blade-remote/1'),
);

/// Noise's limit for one message
const int kNoiseMaxMessage = 65535;
const int _tagLength = 16;
const int _keyLength = 32;

/// Message bytes per frame: the limit minus the AEAD tag and the fin byte
const int kE2eMaxChunk = kNoiseMaxMessage - _tagLength - 1;

/// One reassembled message from the bridge (big source screenshots)
const int _maxInbound = 32 * 1024 * 1024;

final DartX25519 _x25519 = DartX25519();
final DartChacha20 _aead = DartChacha20.poly1305Aead();
const DartSha256 _sha256 = DartSha256();
final DartHmac _hmac = DartHmac(const DartSha256());

/// A handshake or frame that doesn't verify: wrong key, tampering,
/// broken chunking. The session can't continue.
class NoiseException implements Exception {
  final String message;

  const NoiseException(this.message);

  @override
  String toString() => 'NoiseException: $message';
}

/// An X25519 key pair (raw 32-byte keys).
class NoiseKeyPair {
  final Uint8List privateKey;
  final Uint8List publicKey;

  const NoiseKeyPair._(this.privateKey, this.publicKey);

  static Future<NoiseKeyPair> generate() {
    final Random random = Random.secure();
    return fromPrivate(
      Uint8List.fromList(List.generate(_keyLength, (_) => random.nextInt(256))),
    );
  }

  static Future<NoiseKeyPair> fromPrivate(List<int> privateKey) async {
    if (privateKey.length != _keyLength) {
      throw const NoiseException('a key is 32 bytes');
    }
    final SimpleKeyPairData pair =
        await _x25519.newKeyPairFromSeed(privateKey) as SimpleKeyPairData;
    return NoiseKeyPair._(
      Uint8List.fromList(privateKey),
      Uint8List.fromList((await pair.extractPublicKey()).bytes),
    );
  }

  Future<SimpleKeyPairData> _data() async =>
      await _x25519.newKeyPairFromSeed(this.privateKey) as SimpleKeyPairData;
}

Future<Uint8List> _dh(NoiseKeyPair local, List<int> remotePublic) async {
  if (remotePublic.length != _keyLength) {
    throw const NoiseException('a key is 32 bytes');
  }
  final SecretKey shared = _x25519.sharedSecretSync(
    keyPairData: await local._data(),
    remotePublicKey: SimplePublicKey(remotePublic, type: KeyPairType.x25519),
  );
  return Uint8List.fromList(await shared.extractBytes());
}

Uint8List _hash(List<int> data) =>
    Uint8List.fromList(_sha256.hashSync(data).bytes);

Uint8List _hmacOf(List<int> key, List<int> data) => Uint8List.fromList(
  _hmac
      .calculateMacSync(
        data,
        secretKeyData: SecretKeyData(key),
        nonce: const [],
      )
      .bytes,
);

/// Noise's HKDF with two outputs
(Uint8List, Uint8List) _hkdf2(List<int> chainingKey, List<int> input) {
  final Uint8List temp = _hmacOf(chainingKey, input);
  final Uint8List first = _hmacOf(temp, const [1]);
  final Uint8List second = _hmacOf(temp, [...first, 2]);
  return (first, second);
}

/// A key and its message counter (Noise CipherState)
class _CipherState {
  Uint8List? _key;
  int _nonce = 0;

  _CipherState([this._key]);

  bool get hasKey => _key != null;

  void initializeKey(Uint8List key) {
    _key = key;
    _nonce = 0;
  }

  /// 32 bits of zeros, then the counter as 64-bit little-endian
  Uint8List _nonceBytes() {
    final ByteData nonce = ByteData(12);
    nonce.setUint64(4, _nonce, Endian.little);
    return nonce.buffer.asUint8List();
  }

  Uint8List encrypt(List<int> ad, List<int> plaintext) {
    final Uint8List? key = _key;
    if (key == null) return Uint8List.fromList(plaintext);
    final SecretBox box = _aead.encryptSync(
      plaintext,
      secretKey: SecretKeyData(key),
      nonce: _nonceBytes(),
      aad: ad,
    );
    _nonce++;
    return Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);
  }

  Uint8List decrypt(List<int> ad, List<int> ciphertext) {
    final Uint8List? key = _key;
    if (key == null) return Uint8List.fromList(ciphertext);
    if (ciphertext.length < _tagLength) {
      throw const NoiseException('frame too short');
    }
    final int split = ciphertext.length - _tagLength;
    try {
      final List<int> plain = _aead.decryptSync(
        SecretBox(
          ciphertext.sublist(0, split),
          nonce: _nonceBytes(),
          mac: Mac(ciphertext.sublist(split)),
        ),
        secretKey: SecretKeyData(key),
        aad: ad,
      );
      _nonce++;
      return Uint8List.fromList(plain);
    } on SecretBoxAuthenticationError {
      throw const NoiseException('frame did not verify');
    }
  }
}

/// Noise SymmetricState
class _Symmetric {
  late Uint8List _chainingKey;
  late Uint8List _hashState;
  final _CipherState _cipher = _CipherState();

  _Symmetric(List<int> prologue) {
    final List<int> name = utf8.encode(kNoiseProtocolName);
    _hashState = name.length <= 32
        ? (Uint8List(32)..setRange(0, name.length, name))
        : _hash(name);
    _chainingKey = Uint8List.fromList(_hashState);
    mixHash(prologue);
  }

  Uint8List get handshakeHash => Uint8List.fromList(_hashState);

  void mixHash(List<int> data) => _hashState = _hash([..._hashState, ...data]);

  void mixKey(List<int> input) {
    final (chainingKey, key) = _hkdf2(_chainingKey, input);
    _chainingKey = chainingKey;
    _cipher.initializeKey(key);
  }

  Uint8List encryptAndHash(List<int> plaintext) {
    final Uint8List ciphertext = _cipher.encrypt(_hashState, plaintext);
    mixHash(ciphertext);
    return ciphertext;
  }

  Uint8List decryptAndHash(List<int> ciphertext) {
    final Uint8List plaintext = _cipher.decrypt(_hashState, ciphertext);
    mixHash(ciphertext);
    return plaintext;
  }

  /// (initiator -> responder, responder -> initiator)
  (_CipherState, _CipherState) split() {
    final (first, second) = _hkdf2(_chainingKey, const []);
    return (_CipherState(first), _CipherState(second));
  }
}

/// The app's side of the handshake: message 1 out, message 2 in.
class NoiseIKInitiator {
  final NoiseKeyPair _static;
  final Uint8List _remoteStatic;
  final NoiseKeyPair? _fixedEphemeral;
  final _Symmetric _symmetric;
  NoiseKeyPair? _ephemeral;

  /// [ephemeral] only for test vectors
  NoiseIKInitiator({
    required NoiseKeyPair localStatic,
    required List<int> remoteStatic,
    List<int>? prologue,
    NoiseKeyPair? ephemeral,
  }) : _static = localStatic,
       _remoteStatic = Uint8List.fromList(remoteStatic),
       _fixedEphemeral = ephemeral,
       _symmetric = _Symmetric(prologue ?? kRemotePrologue) {
    _symmetric.mixHash(_remoteStatic); // pre-message: <- s
  }

  /// -> e, es, s, ss
  Future<Uint8List> writeMessage1([List<int> payload = const []]) async {
    final NoiseKeyPair e = _fixedEphemeral ?? await NoiseKeyPair.generate();
    _ephemeral = e;
    _symmetric.mixHash(e.publicKey);
    _symmetric.mixKey(await _dh(e, _remoteStatic));
    final Uint8List encryptedStatic = _symmetric.encryptAndHash(
      _static.publicKey,
    );
    _symmetric.mixKey(await _dh(_static, _remoteStatic));
    final Uint8List encryptedPayload = _symmetric.encryptAndHash(payload);
    return Uint8List.fromList([
      ...e.publicKey,
      ...encryptedStatic,
      ...encryptedPayload,
    ]);
  }

  /// <- e, ee, se; returns the payload and the session's transport.
  Future<(Uint8List, NoiseTransport)> readMessage2(List<int> message) async {
    final NoiseKeyPair? e = _ephemeral;
    if (e == null) throw StateError('writeMessage1 first');
    if (message.length < _keyLength + _tagLength) {
      throw const NoiseException('handshake message too short');
    }
    final List<int> remoteEphemeral = message.sublist(0, _keyLength);
    _symmetric.mixHash(remoteEphemeral);
    _symmetric.mixKey(await _dh(e, remoteEphemeral));
    _symmetric.mixKey(await _dh(_static, remoteEphemeral));
    final Uint8List payload = _symmetric.decryptAndHash(
      message.sublist(_keyLength),
    );
    final (toResponder, toInitiator) = _symmetric.split();
    return (
      payload,
      NoiseTransport._(
        send: toResponder,
        receive: toInitiator,
        handshakeHash: _symmetric.handshakeHash,
      ),
    );
  }
}

/// The bridge's side - here for tests and the fake bridge (the real one
/// is snow in `desktop/core`).
class NoiseIKResponder {
  final NoiseKeyPair _static;
  final NoiseKeyPair? _fixedEphemeral;
  final _Symmetric _symmetric;
  Uint8List? _remoteEphemeral;
  Uint8List? remoteStatic;

  NoiseIKResponder({
    required NoiseKeyPair localStatic,
    List<int>? prologue,
    NoiseKeyPair? ephemeral,
  }) : _static = localStatic,
       _fixedEphemeral = ephemeral,
       _symmetric = _Symmetric(prologue ?? kRemotePrologue) {
    _symmetric.mixHash(_static.publicKey);
  }

  Future<Uint8List> readMessage1(List<int> message) async {
    if (message.length < _keyLength + _keyLength + 2 * _tagLength) {
      throw const NoiseException('handshake message too short');
    }
    final List<int> re = message.sublist(0, _keyLength);
    _remoteEphemeral = Uint8List.fromList(re);
    _symmetric.mixHash(re);
    _symmetric.mixKey(await _dh(_static, re));
    final int staticEnd = _keyLength + _keyLength + _tagLength;
    final Uint8List rs = _symmetric.decryptAndHash(
      message.sublist(_keyLength, staticEnd),
    );
    remoteStatic = rs;
    _symmetric.mixKey(await _dh(_static, rs));
    return _symmetric.decryptAndHash(message.sublist(staticEnd));
  }

  Future<(Uint8List, NoiseTransport)> writeMessage2([
    List<int> payload = const [],
  ]) async {
    final Uint8List? re = _remoteEphemeral;
    final Uint8List? rs = remoteStatic;
    if (re == null || rs == null) throw StateError('readMessage1 first');
    final NoiseKeyPair e = _fixedEphemeral ?? await NoiseKeyPair.generate();
    _symmetric.mixHash(e.publicKey);
    _symmetric.mixKey(await _dh(e, re));
    _symmetric.mixKey(await _dh(e, rs));
    final Uint8List encryptedPayload = _symmetric.encryptAndHash(payload);
    final (toResponder, toInitiator) = _symmetric.split();
    return (
      Uint8List.fromList([...e.publicKey, ...encryptedPayload]),
      NoiseTransport._(
        send: toInitiator,
        receive: toResponder,
        handshakeHash: _symmetric.handshakeHash,
      ),
    );
  }
}

/// A session after the handshake: one Noise message per frame, a message
/// of any size as chunks `[fin u8][bytes]`.
class NoiseTransport {
  final _CipherState _send;
  final _CipherState _receive;
  final Uint8List handshakeHash;
  final BytesBuilder _pending = BytesBuilder(copy: false);

  NoiseTransport._({
    required _CipherState send,
    required _CipherState receive,
    required this.handshakeHash,
  }) : _send = send,
       _receive = receive;

  /// One Noise transport message (test vectors use these directly)
  Uint8List encrypt(List<int> plaintext) {
    if (plaintext.length > kNoiseMaxMessage - _tagLength) {
      throw const NoiseException('message too long');
    }
    return _send.encrypt(const [], plaintext);
  }

  Uint8List decrypt(List<int> frame) {
    if (frame.length > kNoiseMaxMessage) {
      throw const NoiseException('frame too long');
    }
    return _receive.decrypt(const [], frame);
  }

  /// [message] -> its frames, in order
  List<Uint8List> seal(List<int> message) {
    final List<Uint8List> frames = [];
    int start = 0;
    do {
      final int end = min(start + kE2eMaxChunk, message.length);
      final bool last = end == message.length;
      frames.add(this.encrypt([last ? 1 : 0, ...message.sublist(start, end)]));
      start = end;
    } while (start < message.length);
    return frames;
  }

  /// One frame in; the whole message once its last chunk arrived
  Uint8List? open(List<int> frame) {
    final Uint8List plain = this.decrypt(frame);
    if (plain.isEmpty || plain[0] > 1) {
      throw const NoiseException('broken chunk');
    }
    if (_pending.length + plain.length - 1 > _maxInbound) {
      throw const NoiseException('message too long');
    }
    _pending.add(Uint8List.sublistView(plain, 1));
    return plain[0] == 1 ? _pending.takeBytes() : null;
  }
}
