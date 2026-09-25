import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';

import '../../../shared/design/design.dart';
import '../../../shared/general/base/card.dart';
import '../../../stores/views/dashboard.dart';

/// Brief "Reconnected" flash once a lost OBS connection is back. The lost
/// state itself is NOT toasted here - the inline "LAST KNOWN STATE" badges
/// ([StaleStateBadge], stream health pill) and the disabled controls
/// already say it where the values are, and a second floating card on top
/// read as a doubled alarm mid-stream.
class ReconnectToast extends StatefulWidget {
  const ReconnectToast({super.key});

  @override
  State<ReconnectToast> createState() => _ReconnectToastState();
}

class _ReconnectToastState extends State<ReconnectToast>
    with TickerProviderStateMixin {
  static const Duration _visibleFor = Duration(seconds: 3);

  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  final List<ReactionDisposer> _disposers = [];
  Timer? _hideTimer;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: AppMotion.medium);

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.standard));

    _offset = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.standard));

    _disposers.add(
      reaction((_) => GetIt.instance<DashboardStore>().reconnecting, (
        bool reconnecting,
      ) {
        _hideTimer?.cancel();
        if (reconnecting) {
          /// Dropped again while the flash is still up - it's not
          /// connected anymore
          _controller.reverse();
        } else {
          _controller.forward();
          _hideTimer = Timer(_visibleFor, () => _controller.reverse());
        }
      }),
    );

    super.initState();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    for (var d in _disposers) {
      d();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStatusColors statusColors = Theme.of(
      context,
    ).extension<AppStatusColors>()!;

    return IgnorePointer(
      ignoring: true,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _offset,
          child: BaseCard(
            paintBorder: true,
            constrained: false,
            borderColor: statusColors.reachable,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: statusColors.reachable,
                  size: 20.0,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Reconnected to OBS',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
