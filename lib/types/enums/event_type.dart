enum EventType { ScenesChanged }

extension EvenTypeFunctions on EventType {
  String get text => const {EventType.ScenesChanged: 'ScenesChanged'}[this];
}
