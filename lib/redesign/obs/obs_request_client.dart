import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../types/classes/stream/responses/base.dart';
import '../../types/enums/request_type.dart';
import '../../types/interfaces/message.dart';

enum ObsRequestOutcome { accepted, rejected, timedOut, disconnected }

class ObsRequestResult {
  const ObsRequestResult(this.outcome, {this.data = const {}, this.code});

  final ObsRequestOutcome outcome;
  final Map<String, dynamic> data;
  final int? code;
  bool get accepted => outcome == ObsRequestOutcome.accepted;
}

typedef ObsRequestSender =
    void Function(String id, RequestType type, Map<String, dynamic> data);

/// Correlates replies on an already identified session. Never owns the socket,
/// retries a mutation, or interprets an acknowledgement as confirmed UI state.
class ObsRequestClient {
  ObsRequestClient({
    required Stream<Message> messages,
    required this.send,
    this.timeout = const Duration(seconds: 5),
  }) {
    _subscription = messages.listen(
      _receive,
      onError: (Object error, StackTrace stack) => close(),
      onDone: close,
    );
  }

  final ObsRequestSender send;
  final Duration timeout;
  late final StreamSubscription<Message> _subscription;
  final _events = StreamController<Message>.broadcast(sync: true);
  final _pending = <String, _PendingRequest>{};
  bool _closed = false;

  Stream<Message> get events => _events.stream;
  bool get isClosed => _closed;

  Future<ObsRequestResult> request(
    RequestType type, [
    Map<String, dynamic> data = const {},
  ]) {
    if (_closed) {
      return Future.value(
        const ObsRequestResult(ObsRequestOutcome.disconnected),
      );
    }
    final id = const Uuid().v4();
    final pending = _PendingRequest(type);
    _pending[id] = pending;
    pending.timer = Timer(timeout, () {
      _finish(id, const ObsRequestResult(ObsRequestOutcome.timedOut));
    });
    try {
      // Register before sending: a synchronous test transport may reply inline.
      send(id, type, Map.unmodifiable(data));
    } catch (_) {
      // A send failure retires the transport. Delivery cannot be assumed absent.
      close();
    }
    return pending.completer.future;
  }

  void _receive(Message message) {
    if (_closed) return;
    if (message is BaseResponse) {
      final pending = _pending[message.uuid];
      if (pending != null &&
          message.jsonRAW['d']['requestType'] == pending.type.name) {
        final status = message.status;
        _finish(
          message.uuid,
          ObsRequestResult(
            status.result
                ? ObsRequestOutcome.accepted
                : ObsRequestOutcome.rejected,
            data: Map.unmodifiable(message.json),
            code: status.code,
          ),
        );
      }
    } else {
      _events.add(message);
    }
  }

  void _finish(String id, ObsRequestResult result) {
    final pending = _pending.remove(id);
    if (pending == null) return;
    pending.timer?.cancel();
    pending.completer.complete(result);
  }

  void close() {
    if (_closed) return;
    _closed = true;
    for (final id in _pending.keys.toList()) {
      _finish(id, const ObsRequestResult(ObsRequestOutcome.disconnected));
    }
    unawaited(_subscription.cancel());
    unawaited(_events.close());
  }
}

class _PendingRequest {
  _PendingRequest(this.type);
  final RequestType type;
  final completer = Completer<ObsRequestResult>();
  Timer? timer;
}
