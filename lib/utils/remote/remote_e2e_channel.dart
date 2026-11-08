import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../types/enums/web_socket_codes/web_socket_close_code.dart';
import 'noise_ik.dart';

/// The relay socket with end-to-end encryption inside: to the rest of the
/// app it is a plain obs-websocket channel (text frames in and out), on
/// the wire every frame is an encrypted binary Noise message only the
/// paired bridge can read (`noise_ik.dart`, spec "End-to-end
/// encryption").
///
/// After the websocket upgrade ([ready]) it sends Noise message 1 and
/// holds outgoing messages until the bridge's message 2 verified. A
/// bridge key that doesn't verify, or a frame that doesn't decrypt, ends
/// the session with [WebSocketCloseCode.RemoteE2eFailed] as [closeCode].
class RemoteE2eChannel extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  final WebSocketChannel _inner;
  final NoiseIKInitiator _initiator;
  final StreamController<String> _incoming = StreamController<String>();
  late final _E2eSink _sink = _E2eSink(this);

  NoiseTransport? _transport;
  final List<String> _waiting = [];

  /// Frames are handled strictly in order (the handshake step is async)
  Future<void> _chain = Future<void>.value();
  int? _failedCode;
  String? _failedReason;

  RemoteE2eChannel(
    this._inner, {
    required NoiseKeyPair appKey,
    required List<int> bridgeKey,
  }) : _initiator = NoiseIKInitiator(
         localStatic: appKey,
         remoteStatic: bridgeKey,
       ) {
    _inner.stream.listen(
      (frame) => _chain = _chain.then((_) => _receive(frame)),
      onError: (Object error, StackTrace stack) {
        if (!_incoming.isClosed) _incoming.addError(error, stack);
      },
      onDone: () => _chain = _chain.then((_) {
        if (!_incoming.isClosed) _incoming.close();
      }),
    );
    _inner.ready.then((_) async {
      try {
        _inner.sink.add(await _initiator.writeMessage1());
      } catch (_) {
        _fail('handshake could not start');
      }
    }, onError: (_) {});
  }

  Future<void> _receive(dynamic frame) async {
    if (_failedCode != null) return;
    if (frame is! List<int>) {
      return _fail('readable frame from the relay');
    }
    try {
      final NoiseTransport? transport = _transport;
      if (transport == null) {
        final (_, established) = await _initiator.readMessage2(frame);
        _transport = established;
        for (final message in _waiting) {
          _send(message);
        }
        _waiting.clear();
        return;
      }
      final Uint8List? message = transport.open(frame);
      if (message != null && !_incoming.isClosed) {
        _incoming.add(utf8.decode(message));
      }
    } on NoiseException catch (e) {
      _fail(e.message);
    } on FormatException {
      _fail('frame was not text');
    }
  }

  void _send(String message) {
    for (final frame in _transport!.seal(utf8.encode(message))) {
      _inner.sink.add(frame);
    }
  }

  void _fail(String reason) {
    if (_failedCode != null) return;
    _failedCode = WebSocketCloseCode.RemoteE2eFailed.identifier;
    _failedReason = reason;
    _inner.sink.close(_failedCode, 'e2e');
  }

  @override
  Stream<String> get stream => _incoming.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  Future<void> get ready => _inner.ready;

  @override
  String? get protocol => _inner.protocol;

  @override
  int? get closeCode => _failedCode ?? _inner.closeCode;

  @override
  String? get closeReason => _failedReason ?? _inner.closeReason;
}

class _E2eSink extends DelegatingStreamSink<dynamic> implements WebSocketSink {
  final RemoteE2eChannel _channel;

  _E2eSink(this._channel) : super(_channel._inner.sink);

  @override
  void add(dynamic data) {
    if (data is! String) {
      throw ArgumentError('obs-websocket messages are text', 'data');
    }
    if (_channel._failedCode != null) return;
    if (_channel._transport == null) {
      _channel._waiting.add(data);
    } else {
      _channel._send(data);
    }
  }

  @override
  Future<void> addStream(Stream<dynamic> stream) async {
    await for (final data in stream) {
      this.add(data);
    }
  }

  @override
  Future close([int? closeCode, String? closeReason]) =>
      _channel._inner.sink.close(closeCode, closeReason);
}
