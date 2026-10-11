import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/dialogs/info.dart';
import 'package:obs_blade/shared/general/base/card.dart';
import 'package:obs_blade/shared/general/base/icon_button.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/views/settings/dashboard_customisation/order/widgets/element_list.dart';

class ElementBody extends StatelessWidget {
  final int index;
  final PreviewConfig config;

  const ElementBody({super.key, required this.index, required this.config});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: this.config.canBeNotVisible && !this.config.visible ? 0.6 : 1.0,
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      child: BaseCard(
        titleWidget: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Padding(
              /// Keeps the title at its pre-hit-floor x (24pt glyph +
              /// 12 gap) - the drag target's transparent tail slides
              /// underneath it
              padding: const EdgeInsets.only(left: 24.0 + AppSpacing.md),
              child: Text(
                this.config.element.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ReorderableDragStartListener(
              index: this.index,

              /// Invisible hit expansion: the 24pt glyph keeps its exact
              /// spot, the transparent tail reaches 44pt wide into the old
              /// gap (a 44pt-tall box would grow the cards without a
              /// trailing control - doctrine: hit fixes stay invisible)
              child: SizedBox(
                width: kBaseIconButtonMinHitArea,
                height: 24.0,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    CupertinoIcons.circle_grid_3x3_fill,
                    color: Theme.of(
                      context,
                    ).extension<AppTextColors>()!.textTertiary,
                  ),
                ),
              ),
            ),
          ],
        ),
        trailingTitleWidget: this.config.canBeNotVisible
            ? IconButton(
                onPressed: () => ModalHandler.showBaseDialog(
                  context: context,
                  dialogWidget: InfoDialog(
                    body:
                        'Some of the elements on the dashboard are only visible if you activated them in the previous screen.\n\nCurrently this element is ${!this.config.visible ? "not " : ""}visible in the dashboard.',
                  ),
                ),
                icon: Icon(
                  this.config.visible ? Icons.visibility : Icons.visibility_off,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              )
            : null,
        paddingChild: const EdgeInsets.all(0),
        topPadding: 0,
        bottomPadding: AppSpacing.lg,
        child: BaseCard(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: Align(child: this.config.widget),
        ),
      ),
    );
  }
}
