import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';

import '../../../../stores/views/dashboard.dart';
import '../../../../types/extensions/int.dart';

class StreamRecTimers extends StatefulWidget {
  const StreamRecTimers({Key? key}) : super(key: key);

  @override
  State<StreamRecTimers> createState() => _StreamRecTimersState();
}

class _StreamRecTimersState extends State<StreamRecTimers> {
  final List<ReactionDisposer> _disposers = [];

  Timer? _streamTimer;
  Timer? _recordTimer;

  int _streamTimeS = 0;
  int _recordTimeS = 0;

  @override
  void initState() {
    super.initState();
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    _disposers.add(
        reaction<int?>((_) => dashboardStore.latestStreamTimeDurationMS,
            (latestStreamTimeDurationMS) {
      _streamTimer?.cancel();
      setState(() {
        if (dashboardStore.isLive) {
          _streamTimeS = (latestStreamTimeDurationMS ?? 0) ~/ 1000;
          _streamTimer = Timer.periodic(const Duration(seconds: 1),
              (_) => setState(() => _streamTimeS++));
        } else {
          _streamTimeS = 0;
        }
      });
    }));

    _disposers.add(
        reaction<int?>((_) => dashboardStore.latestRecordTimeDurationMS,
            (latestRecordTimeDurationMS) {
      _recordTimer?.cancel();
      setState(() {
        if (dashboardStore.isRecording) {
          _recordTimeS = (latestRecordTimeDurationMS ?? 0) ~/ 1000;
          _recordTimer = Timer.periodic(const Duration(seconds: 1),
              (_) => setState(() => _recordTimeS++));
        } else {
          _recordTimeS = 0;
        }
      });
    }));

    _disposers.add(reaction<bool>((_) => dashboardStore.isRecordingPaused,
        (isRecordingPaused) {
      _recordTimer?.cancel();
      if (!isRecordingPaused) {
        _recordTimer = Timer.periodic(
            const Duration(seconds: 1), (_) => setState(() => _recordTimeS++));
      }
    }));
  }

  @override
  void dispose() {
    for (var d in _disposers) {
      d();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            const Icon(
              CupertinoIcons.dot_radiowaves_left_right,
              size: 16.0,
            ),
            const SizedBox(width: 8.0),
            Text(
              _streamTimeS.secondsToFormattedDurationString(),
              style: const TextStyle(
                fontFeatures: [
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 32.0),
        Row(
          children: [
            const Icon(
              CupertinoIcons.recordingtape,
              size: 18.0,
            ),
            const SizedBox(width: 8.0),
            Text(
              _recordTimeS.secondsToFormattedDurationString(),
              style: const TextStyle(
                fontFeatures: [
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
