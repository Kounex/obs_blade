import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/stores/views/home.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/network_helper.dart';

class ReachableBuilder extends StatefulWidget {
  final Widget Function(List<Connection> savedConnections)
      savedConnectionsBuilder;

  const ReachableBuilder({
    Key? key,
    required this.savedConnectionsBuilder,
  }) : super(key: key);

  @override
  State<ReachableBuilder> createState() => _ReachableBuilderState();
}

class _ReachableBuilderState extends State<ReachableBuilder> {
  late List<Connection> _savedConnections;
  final List<ReactionDisposer> _disposers = [];

  @override
  void initState() {
    super.initState();

    _savedConnections =
        Hive.box<Connection>(HiveKeys.SavedConnections.name).values.toList();

    _checkReachableStatus();

    _disposers
        .add(reaction<bool>((_) => GetIt.instance<HomeStore>().doRefresh, (_) {
      _checkReachableStatus();
    }));
  }

  void _checkReachableStatus() async {
    for (var connection in _savedConnections) {
      connection.reachable = null;
    }

    setState(() {});

    List<Connection> availableConnections =
        await NetworkHelper.checkConnectionAvailabilities(_savedConnections);

    for (var connection in _savedConnections) {
      connection.reachable = availableConnections.any((availableConnection) =>
          availableConnection.host == connection.host &&
          availableConnection.port == connection.port &&
          availableConnection.isDomain == connection.isDomain);
    }
    _savedConnections.sort((c1, c2) => c1.reachable != c2.reachable
        ? c1.reachable!
            ? 0
            : 1
        : c1.name!.compareTo(c2.name!));

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
