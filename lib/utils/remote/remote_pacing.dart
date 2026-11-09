/// Over the relay the scene preview runs at most this often. Back to back
/// (as on the LAN) it took a whole mobile line: replies and the
/// websocket's pong queued behind screenshots, the socket closed every
/// ~30 s and each reconnect reloaded the dashboard on top (dogfood
/// 2026-11-09). 4 frames/s still reads as live and saves mobile data.
const Duration kRemotePreviewInterval = Duration(milliseconds: 250);

/// How long the preview loop waits before its next screenshot: nothing on
/// the LAN, the rest of [kRemotePreviewInterval] since the last request
/// over the relay.
Duration previewPause({
  required bool viaRemote,
  required DateTime? requestedAt,
  DateTime? now,
}) {
  if (!viaRemote || requestedAt == null) return Duration.zero;
  final Duration rest =
      kRemotePreviewInterval - (now ?? DateTime.now()).difference(requestedAt);
  return rest.isNegative ? Duration.zero : rest;
}
