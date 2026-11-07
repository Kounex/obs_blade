import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';

/// Where the client was in the OBS WebSocket handshake when the attempt ended.
enum ConnectionStage { connecting, waitingHello, waitingIdentified, identified }

/// Outcome of [NetworkStore.setOBSWebSocket] — success or a specific failure.
class ConnectionAttemptResult {
  final WebSocketCloseCode closeCode;
  final ConnectionStage stage;
  final String? detail;

  /// The attempt went through the remote relay (Pro)
  final bool viaRemote;

  /// The paired PC's name, for remote messages
  final String? remoteName;

  const ConnectionAttemptResult({
    required this.closeCode,
    required this.stage,
    this.detail,
    this.viaRemote = false,
    this.remoteName,
  });

  ConnectionAttemptResult withRemote(String? name) => ConnectionAttemptResult(
    closeCode: this.closeCode,
    stage: this.stage,
    detail: this.detail,
    viaRemote: true,
    remoteName: name,
  );

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
      case WebSocketCloseCode.RemoteBridgeOffline:
        return '$_pc is offline - OBS Blade Remote isn\'t connected there.';
      case WebSocketCloseCode.RemoteObsNotRunning:
        return 'OBS isn\'t running on $_pc.';
      case WebSocketCloseCode.RemoteObsUnreachable:
        return 'OBS on $_pc doesn\'t let OBS Blade Remote in. Turn on the WebSocket server in OBS.';
      case WebSocketCloseCode.RemoteProRequired:
        return 'Remote access is part of Pro.';
      case WebSocketCloseCode.RemoteUnpaired:
        return 'This device isn\'t paired with $_pc any more. Set up remote access again.';
      case WebSocketCloseCode.RemoteBridgeOutdated:
        return 'Update OBS Blade Remote on $_pc.';
      case WebSocketCloseCode.RemoteSessionReplaced:
        return 'This device connected again - the newer connection is live.';
      case WebSocketCloseCode.RemoteTooManySessions:
        return 'Too many devices are connected to $_pc right now. Try again.';
      case WebSocketCloseCode.RemoteBridgeGone:
        return 'Lost $_pc. Trying again may work.';
      case WebSocketCloseCode.RemoteVerifyUnavailable:
        return 'Couldn\'t check Pro right now. Try again in a moment.';
      case WebSocketCloseCode.RemoteRateLimited:
        return 'Too many attempts. Try again in a minute.';
    }
  }

  String get _pc {
    final name = this.remoteName?.trim();
    return name == null || name.isEmpty ? 'your PC' : name;
  }

  String get _timeoutOrUnknownMessage {
    switch (stage) {
      case ConnectionStage.connecting:
        return this.viaRemote
            ? 'Could not reach the remote relay. Check your internet connection.'
            : 'Could not reach OBS. Check IP, port, Wi‑Fi, and firewall.';
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
      'ConnectionAttemptResult($closeCode, stage: $stage, detail: $detail'
      '${this.viaRemote ? ', via remote' : ''})';
}
