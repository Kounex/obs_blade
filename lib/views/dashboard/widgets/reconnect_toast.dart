import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/utils/general_helper.dart';

import '../../../shared/general/base/base_card.dart';
import '../../../shared/overlay/base_progress_indicator.dart';
import '../../../shared/overlay/base_result.dart';
import '../../../stores/views/dashboard.dart';

class ReconnectToast extends StatefulWidget {
  @override
  _ReconnectToastState createState() => _ReconnectToastState();
}

class _ReconnectToastState extends State<ReconnectToast>
    with TickerProviderStateMixin {
  late AnimationController _controllerReconnecting;
  late Animation<double> _opacityReconnecting;
  late Animation<Offset> _offsetReconnecting;

  late AnimationController _controllerConnected;
  late Animation<double> _opacityConnected;
  late Animation<Offset> _offsetConnected;

  List<ReactionDisposer> _disposers = [];

  @override
  void initState() {
    _controllerReconnecting =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));

    _opacityReconnecting = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _controllerReconnecting, curve: Curves.easeOut));

    _offsetReconnecting =
        Tween<Offset>(begin: Offset(0, -0.1), end: Offset(0, 0)).animate(
            CurvedAnimation(
                parent: _controllerReconnecting, curve: Curves.easeOut));

    _controllerConnected =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));

    _opacityConnected = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controllerConnected, curve: Curves.easeOut));

    _offsetConnected = Tween<Offset>(begin: Offset(0, -0.1), end: Offset(0, 0))
        .animate(CurvedAnimation(
            parent: _controllerConnected, curve: Curves.easeOut));

    _disposers.add(
      reaction(
        (_) => GetIt.instance<DashboardStore>().reconnecting,
        (bool reconnecting) {
          GeneralHelper.advLog('RECONNECTING!!!!! - $reconnecting');
          if (reconnecting && _controllerReconnecting.isDismissed) {
            _controllerReconnecting.forward();
          } else if (!reconnecting && !_controllerReconnecting.isDismissed) {
            _controllerReconnecting.reverse();
            if (_controllerConnected.isDismissed) {
              _controllerConnected.forward();
              Future.delayed(
                  Duration(seconds: 3), () => _controllerConnected.reverse());
            }
          }
        },
      ),
    );

    super.initState();
  }

  @override
  void dispose() {
    _disposers.forEach((d) => d());
    _controllerReconnecting.dispose();
    _controllerConnected.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          AnimatedBuilder(
            animation: _controllerReconnecting,
            child: BaseCard(
              paintBorder: true,
              borderColor: CupertinoColors.destructiveRed,
              child: BaseProgressIndicator(
                text: 'OBS connection lost\nReconnecting...',
              ),
            ),
            builder: (context, child) => FadeTransition(
              opacity: _opacityReconnecting,
              child: SlideTransition(
                position: _offsetReconnecting,
                child: child,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controllerConnected,
            child: BaseCard(
              paintBorder: true,
              borderColor: CupertinoColors.activeGreen.color,
              child: BaseResult(
                text: 'Reconnected!',
              ),
            ),
            builder: (context, child) => FadeTransition(
              opacity: _opacityConnected,
              child: SlideTransition(
                position: _offsetConnected,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
