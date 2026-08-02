import 'package:flutter/material.dart';
import 'package:obs_blade/utils/routing_helper.dart';

import '../../../../shared/design/design.dart';
import '../../../../shared/general/question_mark_tooltip.dart';
import '../accent_icon_tile.dart';

const double kblockEntryPadding = 14.0;
const double kblockEntryIconSize = 32.0;
const double kblockEntryHeight = 44.0;

class BlockEntry extends StatelessWidget {
  final IconData? leading;
  final double leadingSize;
  final IconData? heroPlaceholder;
  final String? title;
  final String? help;
  final Widget? trailing;
  final Function? onTap;
  final RoutingKeys? navigateTo;
  final bool rootNavigation;
  final Widget? navigateToResult;

  /// Whether the row is currently shown - [ActionBlock] animates
  /// appear/disappear with an AnimatedSize when this flips
  final bool visible;

  const BlockEntry({
    super.key,
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
    this.visible = true,
  }) : assert(
         (trailing == null &&
                 ((navigateTo != null && onTap == null) ||
                     (navigateTo == null && onTap != null)) ||
             (trailing != null && (navigateTo == null && onTap == null))),
       ),
       super();

  @override
  Widget build(BuildContext context) {
    final void Function()? onPressed = this.navigateTo != null
        ? () => this.rootNavigation
              ? Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushReplacementNamed(this.navigateTo!.route)
              : Navigator.of(context).pushNamed(this.navigateTo!.route)
        : this.onTap != null
        ? () => this.onTap!()
        : null;

    return Pressable(
      onTap: onPressed,
      child: Container(
        color: Theme.of(context).cardColor,
        height: kblockEntryHeight,
        width: MediaQuery.sizeOf(context).width,
        child: Padding(
          padding: const EdgeInsets.only(
            left: kblockEntryPadding,
            right: kblockEntryPadding,
          ),
          child: Row(
            children: [
              if (this.leading != null)
                Padding(
                  padding: const EdgeInsets.only(right: kblockEntryPadding),
                  child: Hero(
                    tag: this.title!,
                    placeholderBuilder: this.heroPlaceholder != null
                        ? (context, heroSize, child) =>
                              Icon(this.heroPlaceholder)
                        : null,
                    child: AccentIconTile(
                      icon: this.leading!,
                      size: kblockEntryIconSize,
                      iconSize: this.leadingSize * 0.66,
                    ),
                  ),
                ),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        this.title!,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleMedium,
                        // .copyWith(fontSize: 15.0),
                      ),
                    ),
                    if (this.help != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0, right: 12.0),
                        child: QuestionMarkTooltip(message: this.help!),
                      ),
                  ],
                ),
              ),
              this.navigateTo != null || this.onTap != null
                  ? Row(
                      children: [
                        if (this.navigateToResult != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.xs,
                            ),
                            child: DefaultTextStyle(
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall!.copyWith(fontSize: 14.0),
                              child: this.navigateToResult!,
                            ),
                          ),
                        Icon(
                          Icons.chevron_right,
                          size: 20.0,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ],
                    )
                  : this.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
