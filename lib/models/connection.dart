import 'package:hive_ce/hive.dart';

import 'type_ids.dart';

part 'connection.g.dart';

@HiveType(typeId: TypeIDs.Connection)
class Connection extends HiveObject {
  @HiveField(0)
  String? name;

  @HiveField(1)
  String host;

  @HiveField(2)
  String? ssid;

  @HiveField(3)
  int? port;

  @HiveField(4)
  String? pw;

  @HiveField(5)
  bool? isDomain;

  /// Epoch ms of the last successful connect from a saved-connection card
  /// (drives the "Last used" stamp). Additive - legacy boxes decode as null.
  @HiveField(6)
  int? lastConnectedMs;

  /// Remote access (Pro, `docs/superpowers/specs/2026-11-07-remote-relay-design.md`):
  /// the bridge next to OBS this connection is paired with and this
  /// device's token for it. Additive - legacy boxes decode as null.
  @HiveField(7)
  String? relayBridgeId;

  @HiveField(8)
  String? relayAppToken;

  @HiveField(9)
  String? relayDeviceId;

  /// The PC's name as the bridge reports it (display only)
  @HiveField(10)
  String? relayBridgeName;

  /// `plugin` or `standalone` - only a standalone can start OBS
  @HiveField(11)
  String? relayBridgeKind;

  String? challenge;
  String? salt;
  bool? reachable;

  bool get hasRemote =>
      (this.relayBridgeId?.isNotEmpty ?? false) &&
      (this.relayAppToken?.isNotEmpty ?? false);

  void clearRemote() {
    this.relayBridgeId = null;
    this.relayAppToken = null;
    this.relayDeviceId = null;
    this.relayBridgeName = null;
    this.relayBridgeKind = null;
  }

  Connection(this.host, this.port, [this.pw, this.isDomain]);
}
