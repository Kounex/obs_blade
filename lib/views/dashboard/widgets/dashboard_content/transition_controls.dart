import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/general/base/dropdown.dart';
import 'package:obs_blade/shared/general/cupertino_number_text_field.dart';

import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/request_type.dart';

class TransitionControls extends StatelessWidget {
  const TransitionControls({super.key});

  void _handleSubmit(TextEditingController controller) {
    if (controller.text.isEmpty) {
      controller.text = '0';
      controller.selection = TextSelection.fromPosition(
        const TextPosition(offset: 1),
      );
    }
    GetIt.instance<DashboardStore>().sendMutation(
      RequestType.SetCurrentSceneTransitionDuration,
      fields: {'transitionDuration': int.tryParse(controller.text) ?? 0},
      label: 'Transition duration',
    );
  }

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return Observer(
      builder: (context) {
        TextEditingController controller = TextEditingController(
          text:
              dashboardStore.currentTransition?.transitionDuration
                  ?.toString() ??
              '-',
        );

        return Padding(
          /// Small hack - not sure why, but without having this vertical padding
          /// the textfield will kinda cut off its top and bottom border and it
          /// makes it look weird (especially with the suffix)
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              BaseDropdown<String>(
                value: dashboardStore.currentTransition?.transitionName,
                items:
                    dashboardStore.availableTransitions
                        ?.map(
                          (transition) => BaseDropdownItem(
                            value: transition.transitionName,
                            text: transition.transitionName,
                          ),
                        )
                        .toList() ??
                    [],
                onChanged: (selectedTransition) => dashboardStore.sendMutation(
                  RequestType.SetCurrentSceneTransition,
                  fields: {'transitionName': selectedTransition},
                  label: 'Transition',
                ),
              ),
              const SizedBox(width: 24.0),
              CupertinoNumberTextField(
                width: 112.0,
                minValue: 50,
                maxValue: 20000,
                enabled:
                    dashboardStore.currentTransition?.transitionDuration !=
                    null,
                controller: controller,
                suffix: 'ms',
                onDone: () => _handleSubmit(controller),
              ),
              const SizedBox(width: 4),
            ],
          ),
        );
      },
    );
  }
}
