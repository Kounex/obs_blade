import 'package:obs_blade/types/enums/web_socket_codes/base.dart';

enum WebSocketOpCode implements BaseWebSocketCode {
  /// The initial message sent by obs-websocket to newly connected clients.
  Hello,

  /// The message sent by a newly connected client to obs-websocket in response to a Hello.
  Identify,

  /// The response sent by obs-websocket to a client after it has successfully identified with obs-websocket.
  Identified,

  /// The message sent by an already-identified client to update identification parameters.
  Reidentify,

  /// The message sent by obs-websocket containing an event payload.
  Event,

  /// The message sent by a client to obs-websocket to perform a request.
  Request,

  /// The message sent by obs-websocket in response to a particular request from a client.
  RequestResponse,

  /// The message sent by a client to obs-websocket to perform a batch of requests.
  RequestBatch,

  /// The message sent by obs-websocket in response to a particular batch of requests from a client.
  RequestBatchResponse;

  @override
  int get identifier => {
        WebSocketOpCode.Hello: 0,
        WebSocketOpCode.Identify: 1,
        WebSocketOpCode.Identified: 2,
        WebSocketOpCode.Reidentify: 3,
        WebSocketOpCode.Event: 5,
        WebSocketOpCode.Request: 6,
        WebSocketOpCode.RequestResponse: 7,
        WebSocketOpCode.RequestBatch: 8,
        WebSocketOpCode.RequestBatchResponse: 9,
      }[this]!;

  @override
  String get message => {
        WebSocketOpCode.Hello:
            'The initial message sent by obs-websocket to newly connected clients.',
        WebSocketOpCode.Identify:
            'The message sent by a newly connected client to obs-websocket in response to a Hello.',
        WebSocketOpCode.Identified:
            'The response sent by obs-websocket to a client after it has successfully identified with obs-websocket.',
        WebSocketOpCode.Reidentify:
            'The message sent by an already-identified client to update identification parameters.',
        WebSocketOpCode.Event:
            'The message sent by obs-websocket containing an event payload.',
        WebSocketOpCode.Request:
            'The message sent by a client to obs-websocket to perform a request.',
        WebSocketOpCode.RequestResponse:
            'The message sent by obs-websocket in response to a particular request from a client.',
        WebSocketOpCode.RequestBatch:
            'The message sent by a client to obs-websocket to perform a batch of requests.',
        WebSocketOpCode.RequestBatchResponse:
            'The message sent by obs-websocket in response to a particular batch of requests from a client.',
      }[this]!;
}
