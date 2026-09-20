import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../stores/views/dashboard.dart';
import 'app_motion.dart';

/// Disables a mutation control while [DashboardStore.obsStateStale] (dead
/// transport, intent would be lost). Wrap CONTROLS only - never value
/// displays - and never a scrollable (IgnorePointer would block scrolling).
class StaleGuard extends StatelessWidget {
  final Widget child;

  const StaleGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final bool stale = GetIt.instance<DashboardStore>().obsStateStale;
        return IgnorePointer(
          ignoring: stale,
          child: AnimatedOpacity(
            duration: AppMotion.fast,
            opacity: stale ? 0.45 : 1.0,
            child: this.child,
          ),
        );
      },
    );
  }
}
