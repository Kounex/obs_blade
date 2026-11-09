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
///
/// Liveness: nothing arriving for [silenceLimit] ends it with
/// [WebSocketCloseCode.RemoteSilent]. The relay socket runs without
/// dart:io's ping - that one closes when a pong is 15 s late even while
/// data flows, and on a busy mobile line pongs queue behind screenshots
/// (sessions closed every ~30 s, dogfood 2026-11-09). The dashboard asks
/// for stats every second, so a live session always delivers.
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

  static const Duration defaultSilenceLimit = Duration(seconds: 20);
  final Duration silenceLimit;
  final Stopwatch _sinceFrame = Stopwatch();
  Timer? _watchdog;

  RemoteE2eChannel(
    this._inner, {
    required NoiseKeyPair appKey,
    required List<int> bridgeKey,
    this.silenceLimit = defaultSilenceLimit,
  }) : _initiator = NoiseIKInitiator(
         localStatic: appKey,
         remoteStatic: bridgeKey,
       ) {
    _inner.stream.listen(
      (frame) {
        /// Arrival, not processing: a busy app isn't a dead line
        _sinceFrame.reset();
        _chain = _chain.then((_) => _receive(frame));
      },
      onError: (Object error, StackTrace stack) {
        if (!_incoming.isClosed) _incoming.addError(error, stack);
      },
      onDone: () {
        _watchdog?.cancel();
        _chain = _chain.then((_) {
          if (!_incoming.isClosed) _incoming.close();
        });
      },
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
        _sinceFrame
          ..reset()
          ..start();
        final Duration tick = silenceLimit ~/ 4;
        _watchdog = Timer.periodic(tick, (_) {
          if (_sinceFrame.elapsed >= silenceLimit) {
            _end(
              WebSocketCloseCode.RemoteSilent.identifier,
              'nothing arrived for ${silenceLimit.inSeconds} s',
            );
          }
        });
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

  void _fail(String reason) =>
      _end(WebSocketCloseCode.RemoteE2eFailed.identifier, reason);

  void _end(int code, String reason) {
    if (_failedCode != null) return;
    _watchdog?.cancel();
    _failedCode = code;
    _failedReason = reason;
    _inner.sink.close(code, code == 4911 ? 'e2e' : 'silent');
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
  Future close([int? closeCode, String? closeReason]) {
    _channel._watchdog?.cancel();
    return _channel._inner.sink.close(closeCode, closeReason);
  }
}
