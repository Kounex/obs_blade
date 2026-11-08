import '../../utils/remote/remote_relay_client.dart';

/// What the relay says about a paired PC - the saved card's view of
/// remote access (not persisted; refreshed with the reachability check).
enum RemoteReach {
  /// The bridge is online and OBS answers: Connect works from anywhere
  obsRunning,

  /// The bridge is online, OBS isn't running (a standalone can start it)
  obsNotRunning,

  /// The bridge is online, but can't reach OBS (WebSocket server off,
  /// password changed)
  obsUnreachable,

  /// The bridge isn't connected to the relay
  pcOffline;

  static RemoteReach of(RemoteBridgeInfo info) {
    if (!info.online) return RemoteReach.pcOffline;
    return switch (info.obsState) {
      'running' => RemoteReach.obsRunning,
      'closed' || 'crashed' || '' => RemoteReach.obsNotRunning,
      _ => RemoteReach.obsUnreachable,
    };
  }

  /// The card's status pill while the PC answers but OBS doesn't (amber);
  /// null where the pill says Online / Offline. Short: a longer pill cut
  /// the PC's name ("OBS not running" -> "GAMING...", 2026-11-08)
  String? get pillLabel => switch (this) {
    RemoteReach.obsNotRunning => 'OBS closed',
    RemoteReach.obsUnreachable => 'OBS blocked',
    RemoteReach.obsRunning || RemoteReach.pcOffline => null,
  };

  /// Suffix of the card's "Remote access" line - only what the pill
  /// doesn't say already
  String? get cardProblem => switch (this) {
    RemoteReach.obsUnreachable => 'check WebSocket',
    RemoteReach.pcOffline => 'PC offline',
    _ => null,
  };
}
