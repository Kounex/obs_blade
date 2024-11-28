import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/dialogs/info.dart';
import 'package:obs_blade/shared/general/base/card.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/views/settings/dashboard_customisation/order/widgets/element_list.dart';

class ElementBody extends StatelessWidget {
  final int index;
  final PreviewConfig config;

  const ElementBody({
    super.key,
    required this.index,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: this.config.canBeNotVisible && !this.config.visible ? 0.6 : 1.0,
      child: BaseCard(
        titleWidget: Row(
          children: [
            ReorderableDragStartListener(
              index: this.index,
              child: Icon(
                CupertinoIcons.circle_grid_3x3_fill,
                color: Theme.of(context).disabledColor,
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                this.config.element.name,
                style: Theme.of(context).textTheme.titleLarge,
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
                          'Some of the elements on the dashboard are only visible if you activated them in the previous screen.\n\nCurrently this element is ${!this.config.visible ? "not " : ""}visible in the dashboard.'),
                ),
                icon: Icon(this.config.visible
                    ? Icons.visibility
                    : Icons.visibility_off),
              )
            : null,
        paddingChild: const EdgeInsets.all(0),
        topPadding: 0,
        bottomPadding: 18.0,
        child: BaseCard(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: Align(
            child: this.config.widget,
          ),
        ),
      ),
    );
  }
}
