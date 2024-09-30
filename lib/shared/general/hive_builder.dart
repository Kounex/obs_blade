import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../types/enums/hive_keys.dart';
import '../../types/enums/settings_keys.dart';

class HiveBuilder<T> extends StatelessWidget {
  final HiveKeys hiveKey;
  final List<SettingsKeys>? rebuildKeys;
  final Widget? child;
  final Widget Function(BuildContext context, Box<T> box, Widget? child)
      builder;

  const HiveBuilder({
    super.key,
    required this.hiveKey,
    this.child,
    required this.builder,
    this.rebuildKeys,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<T>(this.hiveKey.name).listenable(
        keys: this.rebuildKeys?.map((key) => key.name).toList(),
      ),
      builder: this.builder,
      child: this.child,
    );
  }
}
