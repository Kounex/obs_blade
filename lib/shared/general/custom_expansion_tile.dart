import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';

class CustomExpansionTile extends StatefulWidget {
  final IconData leadingIcon;
  final String headerText;
  final TextStyle headerTextStyle;
  final EdgeInsetsGeometry headerPadding;
  final Widget expandedBody;
  final VoidCallback onExpand;
  final void Function(VoidCallback, bool) manualExpand;

  CustomExpansionTile({
    this.leadingIcon,
    @required this.headerText,
    this.headerTextStyle,
    this.headerPadding = const EdgeInsets.all(12.0),
    @required this.expandedBody,
    this.onExpand,
    this.manualExpand,
  });

  @override
  _CustomExpansionTileState createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<CustomExpansionTile>
    with SingleTickerProviderStateMixin {
  ExpandableController _expandController = ExpandableController();

  AnimationController _animController;

  Animation<double> _rotation;
  Animation<Color> _color;

  VoidCallback _startExpandAnimation;

  @override
  void initState() {
    _animController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));

    _startExpandAnimation = () {
      _expandController.toggle();
      if (_animController.isDismissed) {
        _animController.forward();
      } else if (_animController.isCompleted) {
        _animController.reverse();
      }
    };
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _rotation = Tween<double>(begin: 0.0, end: 0.5).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _color = ColorTween(
      begin: Theme.of(context).iconTheme.color,
      end: Theme.of(context).accentColor,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _expandController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      child: ExpandablePanel(
        controller: _expandController,
        theme: ExpandableThemeData(
          inkWellBorderRadius: BorderRadius.zero,
          headerAlignment: ExpandablePanelHeaderAlignment.center,
          bodyAlignment: ExpandablePanelBodyAlignment.center,
          hasIcon: false,
          tapBodyToExpand: false,
          tapBodyToCollapse: false,
          tapHeaderToExpand: false,
        ),
        header: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!_animController.isAnimating) {
              if (this.widget.manualExpand != null) {
                this.widget.manualExpand(
                    _startExpandAnimation, _expandController.expanded);
              } else {
                if (!_expandController.expanded) this.widget.onExpand?.call();
                _startExpandAnimation();
              }
            }
          },
          child: Padding(
            padding: this.widget.headerPadding,
            child: Row(
              children: [
                if (this.widget.leadingIcon != null) ...[
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, _) => Icon(
                      this.widget.leadingIcon,
                      color: _color.value,
                    ),
                  ),
                  SizedBox(width: 24.0),
                ],
                Expanded(
                  child: AnimatedBuilder(
                    animation: _animController,
                    builder: (context, _) => Text(
                      this.widget.headerText,
                      style: (this.widget.headerTextStyle ??
                              Theme.of(context).textTheme.subtitle1)
                          .copyWith(color: _color.value),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) => RotationTransition(
                    turns: _rotation,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: _color.value,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        expanded: this.widget.expandedBody,
      ),
    );
  }
}
