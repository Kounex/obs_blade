import 'package:flutter/material.dart';

class ScrollRefreshIcon extends StatefulWidget {
  final double expandedBarHeight;
  final double barStretchOffset;

  ScrollRefreshIcon(
      {@required this.expandedBarHeight, @required this.barStretchOffset});

  @override
  _ScrollRefreshIconState createState() => _ScrollRefreshIconState();
}

class _ScrollRefreshIconState extends State<ScrollRefreshIcon> {
  double _barHeight;

  double _getRefreshOpacity(double currentBarHeight) {
    double opacity = (currentBarHeight - _barHeight) / widget.barStretchOffset;
    return opacity > 1.0 ? 1.0 : opacity;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_barHeight == null) {
          _barHeight = constraints.maxHeight;
        }
        return Padding(
          padding: EdgeInsets.only(top: widget.expandedBarHeight / 2),
          child: Align(
            child: Opacity(
              opacity: _getRefreshOpacity(constraints.maxHeight),
              child: Container(
                width: 32.0,
                height: 32.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_downward,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
