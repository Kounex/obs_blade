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

  /// Suffix of the card's "Remote access" line - only for what keeps
  /// Connect from working; the pill already says "Online"
  String? get cardProblem => switch (this) {
    RemoteReach.obsRunning => null,
    RemoteReach.obsNotRunning => 'OBS not running',
    RemoteReach.obsUnreachable => 'OBS not reachable',
    RemoteReach.pcOffline => 'PC offline',
  };
}
