import 'package:mobx/mobx.dart';

import '../../models/connection.dart';
import '../../utils/remote/remote_relay_client.dart';

/// A newer OBS Blade Remote for a paired PC, from the relay's bridge info
/// (`update_available` / `update_required`).
class RemoteBridgeUpdate {
  /// `standalone` (the OBS Blade Remote app) or `plugin`
  final String kind;

  /// What the PC runs now
  final String current;

  /// The newest release ('' when the relay doesn't know it - only with
  /// [required])
  final String latest;

  /// The relay refuses this version (remote access stopped working)
  final bool required;

  const RemoteBridgeUpdate({
    required this.kind,
    required this.current,
    required this.latest,
    required this.required,
  });

  bool get isPlugin => this.kind == 'plugin';

  /// "the OBS Blade Remote plugin" / "OBS Blade Remote" - plugin and app
  /// share one pairing, their versions can differ
  String get name =>
      this.isPlugin ? 'the OBS Blade Remote plugin' : 'OBS Blade Remote';

  /// The key a prompt is remembered under: one per release
  String get promptKey => this.latest.isEmpty ? 'required' : this.latest;

  static RemoteBridgeUpdate? of(RemoteBridgeInfo info) {
    if (!info.updateRequired &&
        !(info.updateAvailable && info.latestVersion.isNotEmpty)) {
      return null;
    }
    return RemoteBridgeUpdate(
      kind: info.kind,
      current: info.version,
      latest: info.latestVersion,
      required: info.updateRequired,
    );
  }
}

/// The last bridge info per paired PC (bridge id), app-wide: the Remote
/// Access sheet's store lives only as long as the sheet, while the
/// dashboard's globe and the connect prompt need it too. Whoever reads
/// the relay's bridge info records it here, so an update the PC got
/// clears everywhere at the next read.
class RemoteBridgeUpdates {
  final ObservableMap<String, RemoteBridgeInfo> _infos =
      ObservableMap<String, RemoteBridgeInfo>();

  void record(RemoteBridgeInfo info) =>
      runInAction(() => this._infos[info.id] = info);

  /// Observable: an Observer reading it follows new records
  RemoteBridgeUpdate? updateFor(Connection connection) {
    if (!connection.hasRemote) return null;
    final RemoteBridgeInfo? info = this._infos[connection.relayBridgeId];
    return info == null ? null : RemoteBridgeUpdate.of(info);
  }
}
