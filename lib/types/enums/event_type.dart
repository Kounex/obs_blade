enum EventType {
  StreamStarted,
  StreamStopping,
  StreamStatus,
  ScenesChanged,
  SwitchScenes,
}

extension EvenTypeFunctions on EventType {
  String get text => const {
        EventType.StreamStarted: 'StreamStarted',
        EventType.StreamStopping: 'StreamStopping',
        EventType.StreamStatus: 'StreamStatus',
        EventType.ScenesChanged: 'ScenesChanged',
        EventType.SwitchScenes: 'SwitchScenes',
      }[this];
}
