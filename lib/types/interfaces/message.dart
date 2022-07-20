/// The Message interface is used as the abstraction layer for the
/// messages which we receive from the OBS connection (currently via
/// the WebSocket). Makes it easier to handle those messages with this
/// abstraction since it allows me to name this instance instead of
/// writing duplicate code (right now for Response and Event)
abstract class Message {
  /// The RAW JSON object received through the WebSocket
  late Map<String, dynamic> jsonRAW;

  /// Will hold the 'responseData' / 'eventData' map directly
  /// from the [jsonRAW] - will make it easier to access later
  late Map<String, dynamic> json;
}
