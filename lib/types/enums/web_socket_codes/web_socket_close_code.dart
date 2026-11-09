import 'package:obs_blade/types/enums/web_socket_codes/base.dart';

enum WebSocketCloseCode implements BaseWebSocketCode {
  /// For internal use only to tell the request handler not to perform any close action.
  DontClose,

  /// Unknown reason, should never be used.
  UnknownReason,

  /// The server was unable to decode the incoming websocket message.
  MessageDecodeError,

  /// A data field is required but missing from the payload.
  MissingDataField,

  /// A data field's value type is invalid.
  InvalidDataFieldType,

  /// A data field's value is invalid.
  InvalidDataFieldValue,

  /// The specified op was invalid or missing.
  UnknownOpCode,

  /// The client sent a websocket message without first sending Identify message.
  NotIdentified,

  /// The client sent an Identify message while already identified.
  ///
  ///Note: Once a client has identified, only Reidentify may be used to change session parameters.
  AlreadyIdentified,

  /// The authentication attempt (via Identify) failed.
  AuthenticationFailed,

  /// The server detected the usage of an old version of the obs-websocket RPC protocol.
  UnsupportedRpcVersion,

  /// The websocket session has been invalidated by the obs-websocket server.
  ///
  /// Note: This is the code used by the Kick button in the UI Session List. If you receive this code, you must not automatically reconnect.
  SessionInvalidated,

  /// A requested feature is not supported due to hardware/software limitations.
  UnsupportedFeature,

  /// App-internal: handshake did not finish before the client timeout.
  HandshakeTimeout,

  /// Remote relay (`tool/remote_relay/protocol.py`, 4900+ so they never
  /// collide with obs-websocket's 4000-4012): no bridge connected.
  RemoteBridgeOffline,

  /// Remote relay: the bridge is up, OBS isn't running.
  RemoteObsNotRunning,

  /// Remote relay: OBS runs but its WebSocket server is off or refused the bridge.
  RemoteObsUnreachable,

  /// Remote relay: Pro entitlement missing or lapsed.
  RemoteProRequired,

  /// Remote relay: this device's pairing was removed.
  RemoteUnpaired,

  /// Remote relay: the bridge on the PC is older than the relay accepts.
  RemoteBridgeOutdated,

  /// Remote relay: this device connected again elsewhere.
  RemoteSessionReplaced,

  /// Remote relay: the bridge already carries its maximum of sessions.
  RemoteTooManySessions,

  /// Remote relay: the bridge dropped mid-session.
  RemoteBridgeGone,

  /// Remote relay: Pro couldn't be verified right now.
  RemoteVerifyUnavailable,

  /// Remote relay: too many attempts.
  RemoteRateLimited,

  /// End-to-end encryption failed: the PC's key didn't verify (set by the
  /// app) or the bridge couldn't read this device's handshake / frames.
  RemoteE2eFailed,

  /// Set by the app: nothing arrived through the relay for a while (the
  /// dashboard asks for stats every second) - the line is gone.
  RemoteSilent;

  @override
  int get identifier => const {
    WebSocketCloseCode.DontClose: 0,
    WebSocketCloseCode.UnknownReason: 4000,
    WebSocketCloseCode.MessageDecodeError: 4002,
    WebSocketCloseCode.MissingDataField: 4003,
    WebSocketCloseCode.InvalidDataFieldType: 4004,
    WebSocketCloseCode.InvalidDataFieldValue: 4005,
    WebSocketCloseCode.UnknownOpCode: 4006,
    WebSocketCloseCode.NotIdentified: 4007,
    WebSocketCloseCode.AlreadyIdentified: 4008,
    WebSocketCloseCode.AuthenticationFailed: 4009,
    WebSocketCloseCode.UnsupportedRpcVersion: 4010,
    WebSocketCloseCode.SessionInvalidated: 4011,
    WebSocketCloseCode.UnsupportedFeature: 4012,
    WebSocketCloseCode.HandshakeTimeout: 4999,
    WebSocketCloseCode.RemoteBridgeOffline: 4900,
    WebSocketCloseCode.RemoteObsNotRunning: 4901,
    WebSocketCloseCode.RemoteObsUnreachable: 4902,
    WebSocketCloseCode.RemoteProRequired: 4903,
    WebSocketCloseCode.RemoteUnpaired: 4904,
    WebSocketCloseCode.RemoteBridgeOutdated: 4905,
    WebSocketCloseCode.RemoteSessionReplaced: 4906,
    WebSocketCloseCode.RemoteTooManySessions: 4907,
    WebSocketCloseCode.RemoteBridgeGone: 4908,
    WebSocketCloseCode.RemoteVerifyUnavailable: 4909,
    WebSocketCloseCode.RemoteRateLimited: 4910,
    WebSocketCloseCode.RemoteE2eFailed: 4911,
    WebSocketCloseCode.RemoteSilent: 4998,
  }[this]!;

  @override
  String get message => const {
    WebSocketCloseCode.DontClose:
        'For internal use only to tell the request handler not to perform any close action.',
    WebSocketCloseCode.UnknownReason: 'Unknown reason, should never be used.',
    WebSocketCloseCode.MessageDecodeError:
        'The server was unable to decode the incoming websocket message.',
    WebSocketCloseCode.MissingDataField:
        'A data field is required but missing from the payload.',
    WebSocketCloseCode.InvalidDataFieldType:
        'A data field\'s value type is invalid.',
    WebSocketCloseCode.InvalidDataFieldValue:
        'A data field\'s value is invalid.',
    WebSocketCloseCode.UnknownOpCode:
        'The specified op was invalid or missing.',
    WebSocketCloseCode.NotIdentified:
        'The client sent a websocket message without first sending Identify message.',
    WebSocketCloseCode.AlreadyIdentified:
        'The client sent an Identify message while already identified.\n\nNote: Once a client has identified, only Reidentify may be used to change session parameters.',
    WebSocketCloseCode.AuthenticationFailed:
        'The authentication attempt (via Identify) failed.',
    WebSocketCloseCode.UnsupportedRpcVersion:
        'The server detected the usage of an old version of the obs-websocket RPC protocol.',
    WebSocketCloseCode.SessionInvalidated:
        'The websocket session has been invalidated by the obs-websocket server.\n\nNote: This is the code used by the Kick button in the UI Session List. If you receive this code, you must not automatically reconnect.',
    WebSocketCloseCode.UnsupportedFeature:
        'A requested feature is not supported due to hardware/software limitations.',
    WebSocketCloseCode.HandshakeTimeout:
        'The OBS WebSocket handshake did not complete before the client timeout.',
    WebSocketCloseCode.RemoteBridgeOffline:
        'Remote relay: no bridge is connected for this pairing.',
    WebSocketCloseCode.RemoteObsNotRunning:
        'Remote relay: the bridge is connected, OBS is not running.',
    WebSocketCloseCode.RemoteObsUnreachable:
        'Remote relay: OBS runs but its WebSocket server is off or refused the bridge.',
    WebSocketCloseCode.RemoteProRequired:
        'Remote relay: the Pro entitlement is missing or lapsed.',
    WebSocketCloseCode.RemoteUnpaired:
        'Remote relay: this device is not paired (any more).',
    WebSocketCloseCode.RemoteBridgeOutdated:
        'Remote relay: the bridge on the PC needs an update.',
    WebSocketCloseCode.RemoteSessionReplaced:
        'Remote relay: replaced by a newer connection of this device.',
    WebSocketCloseCode.RemoteTooManySessions:
        'Remote relay: the bridge carries its maximum of sessions.',
    WebSocketCloseCode.RemoteBridgeGone:
        'Remote relay: the bridge dropped mid-session.',
    WebSocketCloseCode.RemoteVerifyUnavailable:
        'Remote relay: Pro could not be verified right now.',
    WebSocketCloseCode.RemoteRateLimited:
        'Remote relay: too many attempts, rate limited.',
    WebSocketCloseCode.RemoteE2eFailed:
        'Remote access: the end-to-end encryption did not verify.',
    WebSocketCloseCode.RemoteSilent:
        'Remote access: nothing arrived through the relay for 20 seconds.',
  }[this]!;

  bool get isRemote =>
      (this.identifier >= 4900 && this.identifier <= 4911) ||
      this == WebSocketCloseCode.RemoteSilent;

  static WebSocketCloseCode fromIdentifier(int? code) {
    if (code == null) return WebSocketCloseCode.UnknownReason;
    return WebSocketCloseCode.values.firstWhere(
      (c) => c.identifier == code,
      orElse: () => WebSocketCloseCode.UnknownReason,
    );
  }
}
