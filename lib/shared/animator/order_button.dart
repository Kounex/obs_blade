import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OrderButton extends StatefulWidget {
  final VoidCallback? toggle;

  OrderButton({this.toggle});

  @override
  _OrderButtonState createState() => _OrderButtonState();
}

class _OrderButtonState extends State<OrderButton>
    with TickerProviderStateMixin {
  late AnimationController _controllerUp;
  late AnimationController _controllerDown;

  late Animation<double> _halfTurnUp;
  late Animation<double> _halfTurnDown;

  @override
  void initState() {
    super.initState();

    _controllerUp =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250));

    _controllerDown =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250));

    _halfTurnUp = Tween<double>(begin: 0.0, end: 0.5).animate(
        CurvedAnimation(parent: _controllerUp, curve: Curves.easeOutCubic));

    _halfTurnDown = Tween<double>(begin: 0.0, end: 0.5).animate(
        CurvedAnimation(parent: _controllerDown, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controllerUp.dispose();
    _controllerDown.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!_controllerDown.isAnimating && !_controllerUp.isAnimating) {
          this.widget.toggle?.call();
          if (_controllerUp.isDismissed) {
            _controllerUp.forward();
          } else if (_controllerDown.isDismissed) {
            _controllerDown.forward().then((value) {
              _controllerUp.reset();
              _controllerDown.reset();
            });
          }
        }
      },
      child: Container(
        padding: EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).accentColor,
        ),
        child: AnimatedBuilder(
          animation: _controllerUp,
          child: AnimatedBuilder(
            animation: _controllerDown,
            child: Icon(
              CupertinoIcons.down_arrow,
              size: 22.0,
            ),
            builder: (context, child) => RotationTransition(
              turns: _halfTurnDown,
              child: child,
            ),
          ),
          builder: (context, child) => RotationTransition(
            turns: _halfTurnUp,
            child: child,
          ),
        ),
      ),
    );
  }
}
