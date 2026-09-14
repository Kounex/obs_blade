import 'obs_request_ack.dart';

/// A user-surfaceable "OBS command failed" notice - set on
/// [DashboardStore.commandFailureNotice] and consumed by the dashboard
/// toast. A new instance is created for every surfaced failure so MobX
/// reactions fire even when the message repeats.
class CommandFailureNotice {
  /// User-facing summary (already deduped / aggregated upstream)
  final String message;

  /// The ack that caused this notice
  final ObsRequestAck ack;

  final DateTime at = DateTime.now();

  CommandFailureNotice({required this.message, required this.ack});
}
