import 'dart:async';

import 'package:flutter/widgets.dart';

/// Rebuilds [builder] with the current time a few times per second while
/// [running] - drives the extrapolated progress of a playing clip (OBS
/// sends no cursor events). Idle rows run no timer at all.
class MediaClock extends StatefulWidget {
  final bool running;
  final Widget Function(BuildContext context, DateTime now) builder;

  const MediaClock({super.key, required this.running, required this.builder});

  @override
  State<MediaClock> createState() => _MediaClockState();
}

class _MediaClockState extends State<MediaClock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant MediaClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (this.widget.running && _timer == null) {
      _timer = Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => this.mounted ? setState(() {}) : null,
      );
    } else if (!this.widget.running && _timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      this.widget.builder(context, DateTime.now());
}
