import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/general/keyboard_number_header.dart';
import '../../../../../stores/shared/network.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/request_type.dart';
import '../../../../../utils/network_helper.dart';

class Transition extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = context.read<DashboardStore>();
    FocusNode focusNode = FocusNode();

    return Observer(builder: (_) {
      TextEditingController controller = TextEditingController(
          text: dashboardStore.sceneTransitionDurationMS?.toString() ?? '-');

      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          DropdownButton<String>(
            value: dashboardStore.currentTransitionName,
            disabledHint: Text('Empty...'),
            isDense: true,
            items: dashboardStore.availableTransitionsNames
                ?.map(
                  (transition) => DropdownMenuItem<String>(
                    value: transition,
                    child: Text(transition),
                  ),
                )
                .toList(),
            onChanged: (selectedTransition) => NetworkHelper.makeRequest(
              context.read<NetworkStore>().activeSession!.socket,
              RequestType.SetCurrentTransition,
              {'transition-name': selectedTransition},
            ),
          ),
          SizedBox(
            width: 24.0,
          ),
          SizedBox(
            width: 72.0,
            child: KeyboardNumberHeader(
              focusNode: focusNode,
              onDone: () {
                if (controller.text.isEmpty) {
                  controller.text = '0';
                  controller.selection =
                      TextSelection.fromPosition(TextPosition(offset: 1));
                }
                NetworkHelper.makeRequest(
                  context.read<NetworkStore>().activeSession!.socket,
                  RequestType.SetTransitionDuration,
                  {'duration': int.tryParse(controller.text) ?? 0},
                );
              },
              child: CupertinoTextField(
                focusNode: focusNode,
                enabled: dashboardStore.sceneTransitionDurationMS != null,
                controller: controller,
                textAlign: TextAlign.center,
                maxLength: 5,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
              ),
            ),
          ),
        ],
      );
    });
  }
}
