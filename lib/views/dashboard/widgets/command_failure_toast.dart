import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';

import '../../../shared/design/design.dart';
import '../../../shared/general/base/card.dart';
import '../../../stores/views/dashboard.dart';

/// Toast for definitively failed OBS commands (command-ack layer) - listens
/// to [DashboardStore.commandFailureNotice], slides/fades in on a new notice
/// and dismisses itself again. Follows the [ReconnectToast] idiom. Never
/// blocks input and only ever shows failures which already re-synced the
/// confirmed state from OBS.
class CommandFailureToast extends StatefulWidget {
  const CommandFailureToast({super.key});

  @override
  State<CommandFailureToast> createState() => _CommandFailureToastState();
}

class _CommandFailureToastState extends State<CommandFailureToast>
    with TickerProviderStateMixin {
  static const Duration _visibleFor = Duration(seconds: 4);

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
      reaction((_) => GetIt.instance<DashboardStore>().commandFailureNotice, (
        notice,
      ) {
        if (notice == null) return;
        _hideTimer?.cancel();
        _controller.forward();
        _hideTimer = Timer(_visibleFor, () => _controller.reverse());
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
    return IgnorePointer(
      ignoring: true,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _offset,
          child: Observer(
            builder: (context) {
              final notice =
                  GetIt.instance<DashboardStore>().commandFailureNotice;

              return BaseCard(
                paintBorder: true,
                constrained: false,
                borderColor: Theme.of(
                  context,
                ).extension<AppStatusColors>()!.destructive,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_triangle_fill,
                      color: Theme.of(
                        context,
                      ).extension<AppStatusColors>()!.destructiveText,
                      size: 20.0,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        notice?.message ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
