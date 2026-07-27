/// Bitmask values for OBS WebSocket Identify `eventSubscriptions`.
///
/// See obs-websocket protocol `EventSubscription`.
class EventSubscription {
  static const int none = 0;
  static const int general = 1 << 0;
  static const int config = 1 << 1;
  static const int scenes = 1 << 2;
  static const int inputs = 1 << 3;
  static const int transitions = 1 << 4;
  static const int filters = 1 << 5;
  static const int outputs = 1 << 6;
  static const int sceneItems = 1 << 7;
  static const int mediaInputs = 1 << 8;
  static const int vendors = 1 << 9;
  static const int ui = 1 << 10;
  static const int canvases = 1 << 11;

  /// All non-high-volume categories (includes Canvases).
  static const int all = general |
      config |
      scenes |
      inputs |
      transitions |
      filters |
      outputs |
      sceneItems |
      mediaInputs |
      vendors |
      ui |
      canvases;

  /// High-volume: InputVolumeMeters (needed for live audio meters in the app).
  static const int inputVolumeMeters = 1 << 16;

  /// Default Identify subscription for OBS Blade.
  static const int appDefault = all | inputVolumeMeters;
}
