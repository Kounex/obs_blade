import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/stores/views/home.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/remote_reach.dart';
import 'package:obs_blade/utils/build_flavor.dart';
import 'package:obs_blade/utils/network_helper.dart';
import 'package:obs_blade/utils/remote/remote_connect.dart';

class ReachableBuilder extends StatefulWidget {
  final Widget Function(List<Connection> savedConnections)
  savedConnectionsBuilder;

  /// Asks the relay about paired connections; defaults to the live one
  /// (none in the FOSS build)
  final RemoteConnectEnvironment? remote;

  const ReachableBuilder({
    super.key,
    required this.savedConnectionsBuilder,
    this.remote,
  });

  @override
  State<ReachableBuilder> createState() => _ReachableBuilderState();
}

class _ReachableBuilderState extends State<ReachableBuilder> {
  late List<Connection> _savedConnections;
  final List<ReactionDisposer> _disposers = [];

  /// Endpoint per saved connection (by Hive key) as of the last check -
  /// tells [didUpdateWidget] whether a box change needs a new check
  Map<dynamic, String> _checkedEndpoints = {};

  late final RemoteConnectEnvironment? _remote =
      this.widget.remote ?? (kFoss ? null : RemoteConnectEnvironment.live());

  /// Bumped per check so a slower, older check can't overwrite a newer one
  int _checkGeneration = 0;

  static String _endpoint(Connection connection) =>
      '${connection.host}|${connection.port}|${connection.isDomain}';

  static List<Connection> _readBox() =>
      Hive.box<Connection>(HiveKeys.SavedConnections.name).values.toList();

  @override
  void initState() {
    super.initState();

    _savedConnections = _readBox();

    _checkReachableStatus();

    _disposers.add(
      reaction<bool>((_) => GetIt.instance<HomeStore>().doRefresh, (_) {
        _checkReachableStatus();
      }),
    );
  }

  /// The parent [HiveBuilder] rebuilds on every box change (add, delete,
  /// edit, "Last used" stamp) - the list has to follow it, and only a new
  /// or changed endpoint needs a new check
  @override
  void didUpdateWidget(covariant ReachableBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    _savedConnections = _readBox();

    final endpointsChanged = _savedConnections.any(
      (connection) =>
          _checkedEndpoints[connection.key] != _endpoint(connection),
    );

    if (endpointsChanged) {
      /// The build following this call picks up the reset dots
      _checkReachableStatus(rebuild: false);
    } else {
      _sort();
    }
  }

  void _sort() {
    _savedConnections.sort(
      (c1, c2) => c1.reachable != c2.reachable
          ? (c1.reachable ?? false)
                ? -1
                : 1
          : (c1.name ?? c1.host).compareTo(c2.name ?? c2.host),
    );
  }

  void _checkReachableStatus({bool rebuild = true}) async {
    final generation = ++_checkGeneration;
    final connections = List<Connection>.of(_savedConnections);

    for (var connection in connections) {
      connection.reachable = null;
      connection.remoteReach = null;
    }
    _checkedEndpoints = {
      for (var connection in connections) connection.key: _endpoint(connection),
    };

    if (rebuild && this.mounted) {
      setState(() {});
    }

    /// Paired connections also ask the relay, alongside the LAN check: a
    /// PC away from this network is still "Online" when Connect would
    /// reach it through the relay (dogfood 2026-11-08: the card said
    /// Offline while Connect worked on 5G)
    final RemoteConnectEnvironment? remote = _remote;
    final Map<Connection, Future<RemoteReach?>> remoteChecks = {
      if (remote != null)
        for (var connection in connections)
          if (connection.hasRemote) connection: remote.reach(connection),
    };

    List<Connection> availableConnections =
        await NetworkHelper.checkConnectionAvailabilities(connections);
    final Map<Connection, RemoteReach?> reaches = {
      for (var entry in remoteChecks.entries) entry.key: await entry.value,
    };

    if (generation != _checkGeneration) return;

    for (var connection in connections) {
      final bool onLan = availableConnections.any(
        (availableConnection) =>
            availableConnection.host == connection.host &&
            availableConnection.port == connection.port &&
            availableConnection.isDomain == connection.isDomain,
      );
      connection.remoteReach = reaches[connection];
      connection.reachable =
          onLan || connection.remoteReach == RemoteReach.obsRunning;
    }
    _sort();

    if (this.mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    for (var d in _disposers) {
      d();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      this.widget.savedConnectionsBuilder(_savedConnections);
}
