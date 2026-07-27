import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';

/// Where the client was in the OBS WebSocket handshake when the attempt ended.
enum ConnectionStage {
  connecting,
  waitingHello,
  waitingIdentified,
  identified,
}

/// Outcome of [NetworkStore.setOBSWebSocket] — success or a specific failure.
class ConnectionAttemptResult {
  final WebSocketCloseCode closeCode;
  final ConnectionStage stage;
  final String? detail;

  const ConnectionAttemptResult({
    required this.closeCode,
    required this.stage,
    this.detail,
  });

  static const success = ConnectionAttemptResult(
    closeCode: WebSocketCloseCode.DontClose,
    stage: ConnectionStage.identified,
  );

  bool get isSuccess => closeCode == WebSocketCloseCode.DontClose;

  bool get isAuthenticationFailure =>
      closeCode == WebSocketCloseCode.AuthenticationFailed;

  /// Short message for overlays / form validation.
  String get userMessage {
    if (isSuccess) return 'Connected';

    switch (closeCode) {
      case WebSocketCloseCode.AuthenticationFailed:
        return 'Wrong password';
      case WebSocketCloseCode.UnsupportedRpcVersion:
        return 'OBS WebSocket version is not supported. Update OBS Studio.';
      case WebSocketCloseCode.SessionInvalidated:
        return 'Session was kicked from OBS. Reconnect manually.';
      case WebSocketCloseCode.MessageDecodeError:
      case WebSocketCloseCode.MissingDataField:
      case WebSocketCloseCode.InvalidDataFieldType:
      case WebSocketCloseCode.InvalidDataFieldValue:
      case WebSocketCloseCode.UnknownOpCode:
        return 'OBS rejected the handshake. Check OBS WebSocket is enabled (v5).';
      case WebSocketCloseCode.NotIdentified:
      case WebSocketCloseCode.AlreadyIdentified:
        return 'Handshake out of order. Try again.';
      case WebSocketCloseCode.UnsupportedFeature:
        return 'OBS does not support a required WebSocket feature.';
      case WebSocketCloseCode.UnknownReason:
        return _timeoutOrUnknownMessage;
      case WebSocketCloseCode.DontClose:
        return 'Connected';
      case WebSocketCloseCode.HandshakeTimeout:
        return _timeoutOrUnknownMessage;
    }
  }

  String get _timeoutOrUnknownMessage {
    switch (stage) {
      case ConnectionStage.connecting:
        return 'Could not reach OBS. Check IP, port, Wi‑Fi, and firewall.';
      case ConnectionStage.waitingHello:
        return 'Connected but OBS did not greet in time. Is WebSocket enabled?';
      case ConnectionStage.waitingIdentified:
        return 'OBS did not finish Identify in time. Check password and try again.';
      case ConnectionStage.identified:
        return detail ?? 'Couldn\'t connect to a WebSocket.';
    }
  }

  @override
  String toString() =>
      'ConnectionAttemptResult($closeCode, stage: $stage, detail: $detail)';
}
