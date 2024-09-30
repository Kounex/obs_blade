import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';

class CustomExpansionTile extends StatefulWidget {
  final IconData? leadingIcon;
  final String? headerText;
  final Widget? trailing;
  final Widget? customHeader;
  final TextStyle? headerTextStyle;
  final EdgeInsetsGeometry headerPadding;
  final Widget expandedBody;
  final VoidCallback? onExpand;
  final void Function(VoidCallback, bool)? manualExpand;

  const CustomExpansionTile({
    super.key,
    this.leadingIcon,
    this.headerText,
    this.trailing,
    this.customHeader,
    this.headerTextStyle,
    this.headerPadding = const EdgeInsets.all(12.0),
    required this.expandedBody,
    this.onExpand,
    this.manualExpand,
  })  : assert(headerText != null || customHeader != null),
        super();

  @override
  _CustomExpansionTileState createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<CustomExpansionTile>
    with SingleTickerProviderStateMixin {
  final ExpandableController _expandController = ExpandableController();

  late AnimationController _animController;

  late Animation<double> _rotation;
  late Animation<Color?> _color;

  late VoidCallback _startExpandAnimation;

  @override
  void initState() {
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));

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
      end: Theme.of(context).colorScheme.secondary,
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
        theme: const ExpandableThemeData(
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
                this.widget.manualExpand!(
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
                  const SizedBox(width: 24.0),
                ],
                Expanded(
                  child: this.widget.customHeader ??
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, _) => Text(
                          this.widget.headerText!,
                          style: (this.widget.headerTextStyle ??
                                  Theme.of(context).textTheme.titleMedium)!
                              .copyWith(
                            color: _color.value,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ),
                ),
                this.widget.trailing ?? const SizedBox(),
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
        collapsed: const SizedBox(),
        expanded: this.widget.expandedBody,
      ),
    );
  }
}
