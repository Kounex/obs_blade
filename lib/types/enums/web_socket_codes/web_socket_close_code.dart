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
  UnsupportedFeature;

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
      }[this]!;

  @override
  String get message => const {
        WebSocketCloseCode.DontClose:
            'For internal use only to tell the request handler not to perform any close action.',
        WebSocketCloseCode.UnknownReason:
            'Unknown reason, should never be used.',
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
      }[this]!;
}
