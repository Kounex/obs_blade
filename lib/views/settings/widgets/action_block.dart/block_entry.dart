import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:obs_blade/shared/general/question_mark_tooltip.dart';
import 'package:obs_blade/utils/styling_helper.dart';

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
  final IconData leading;
  final String title;
  final String help;
  final Widget trailing;
  final Function onTap;
  final String navigateTo;

  BlockEntry(
      {this.leading,
      this.title,
      this.help,
      this.trailing,
      this.onTap,
      this.navigateTo})
      : assert((trailing == null &&
                ((navigateTo != null && onTap == null) ||
                    (navigateTo == null && onTap != null)) ||
            (trailing != null && (navigateTo == null && onTap == null))));

  @override
  _BlockEntryState createState() => _BlockEntryState();
}

class _BlockEntryState extends State<BlockEntry> {
  bool _isPressed = false;

  _handleIsPressed(bool isPressed) =>
      widget.navigateTo != null || widget.onTap != null
          ? setState(() => _isPressed = isPressed)
          : null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      excludeFromSemantics: true,
      onTapDown: (_) => _handleIsPressed(true),
      onTapUp: (_) => _handleIsPressed(false),
      onTapCancel: () => _handleIsPressed(false),
      onTap: widget.navigateTo != null
          ? () => Navigator.of(context).pushNamed(widget.navigateTo)
          : widget.onTap != null ? () => widget.onTap() : null,
      child: Container(
        color: _isPressed
            ? CupertinoDynamicColor.resolve(kPressedColor, context)
            : StylingHelper.MAIN_BLUE,
        height: kblockEntryHeight,
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: EdgeInsets.only(
              left: kblockEntryPadding, right: kblockEntryPadding),
          child: Row(
            children: [
              if (widget.leading != null)
                Padding(
                  padding: EdgeInsets.only(right: kblockEntryPadding),
                  child: Icon(
                    widget.leading,
                    size: kblockEntryIconSize,
                  ),
                ),
              Expanded(
                child: Row(
                  children: [
                    Text(widget.title,
                        style: Theme.of(context).textTheme.subtitle1
                        // .copyWith(fontSize: 15.0),
                        ),
                    if (widget.help != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: QuestionMarkTooltip(message: widget.help),
                      )
                  ],
                ),
              ),
              widget.navigateTo != null || widget.onTap != null
                  ? Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    )
                  : widget.trailing,
            ],
          ),
        ),
      ),
    );
  }
}
