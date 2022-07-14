/// The Message interface is used as the abstraction layer for the
/// messages which we receive from the OBS connection (currently via
/// the WebSocket). Makes it easier to handle those messages with this
/// abstraction since it allows me to name this instance instead of
/// writing duplicate code (right now for Response and Event)
abstract class Message {
  /// Whether the new WebSocket protocol is being used, determines
  /// how to access the different jsons depending on the used
  /// protocol internally
  late bool newProtocol;

  /// The RAW JSON object received through the WebSocket
  late Map<String, dynamic> jsonRAW;

  /// Will be the RAW JSON object for the old protocol, but the
  /// new protocol will hold the actual data here to make property
  /// accessing unified between the b oth protocols
  late Map<String, dynamic> json;
}
