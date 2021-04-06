import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:obs_blade/shared/general/question_mark_tooltip.dart';

const double kblockEntryPadding = 14.0;
const double kblockEntryIconSize = 32.0;
const double kblockEntryHeight = 42.0;

/// Translucent, light gray that is painted on top of the blurred backdrop as
/// the background color of a pressed button.
/// Eye-balled from iOS 13 beta simulator.
///
/// Took from: action_sheet.dart (26.07.2020)
const Color kPressedColor = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFE1E1E1),
  darkColor: Color(0xFF2E2E2E),
);

class BlockEntry extends StatefulWidget {
  final IconData? leading;
  final double leadingSize;
  final IconData? heroPlaceholder;
  final String? title;
  final String? help;
  final Widget? trailing;
  final Function? onTap;
  final String? navigateTo;
  final bool rootNavigation;
  final String? navigateToResult;

  BlockEntry({
    this.leading,
    this.leadingSize = 28.0,
    this.heroPlaceholder,
    this.title,
    this.help,
    this.trailing,
    this.onTap,
    this.navigateTo,
    this.rootNavigation = false,
    this.navigateToResult,
  }) : assert((trailing == null &&
                ((navigateTo != null && onTap == null) ||
                    (navigateTo == null && onTap != null)) ||
            (trailing != null && (navigateTo == null && onTap == null))));

  @override
  _BlockEntryState createState() => _BlockEntryState();
}

class _BlockEntryState extends State<BlockEntry> {
  bool _isPressed = false;

  _handleIsPressed(bool isPressed) =>
      this.widget.navigateTo != null || this.widget.onTap != null
          ? setState(() => _isPressed = isPressed)
          : null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      excludeFromSemantics: true,
      onTapDown: (_) => _handleIsPressed(true),
      onTapUp: (_) => _handleIsPressed(false),
      onTapCancel: () => _handleIsPressed(false),
      onTap: this.widget.navigateTo != null
          ? () => this.widget.rootNavigation
              ? Navigator.of(context, rootNavigator: true)
                  .pushReplacementNamed(this.widget.navigateTo!)
              : Navigator.of(context).pushNamed(this.widget.navigateTo!)
          : this.widget.onTap != null
              ? () => this.widget.onTap!()
              : null,
      child: Container(
        color: _isPressed
            ? CupertinoDynamicColor.resolve(kPressedColor, context)
            : Theme.of(context).backgroundColor,
        height: kblockEntryHeight,
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: EdgeInsets.only(
              left: kblockEntryPadding, right: kblockEntryPadding),
          child: Row(
            children: [
              if (this.widget.leading != null)
                Padding(
                  padding: EdgeInsets.only(right: kblockEntryPadding),
                  child: SizedBox(
                    width: kblockEntryIconSize,
                    child: Hero(
                      tag: this.widget.title!,
                      placeholderBuilder: this.widget.heroPlaceholder != null
                          ? (context, heroSize, child) =>
                              Icon(this.widget.heroPlaceholder)
                          : null,
                      child: Icon(
                        this.widget.leading,
                        size: this.widget.leadingSize,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Row(
                  children: [
                    Text(this.widget.title!,
                        style: Theme.of(context).textTheme.subtitle1
                        // .copyWith(fontSize: 15.0),
                        ),
                    if (this.widget.help != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: QuestionMarkTooltip(message: this.widget.help!),
                      )
                  ],
                ),
              ),
              this.widget.navigateTo != null || this.widget.onTap != null
                  ? Row(
                      children: [
                        if (this.widget.navigateToResult != null)
                          Text(
                            this.widget.navigateToResult!,
                            style: Theme.of(context)
                                .textTheme
                                .caption!
                                .copyWith(fontSize: 14.0),
                          ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ],
                    )
                  : this.widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
