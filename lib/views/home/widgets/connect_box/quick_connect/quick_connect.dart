import 'package:flutter/cupertino.dart';

import '../../../../../shared/dialogs/info.dart';
import '../../../../../shared/general/base/button.dart';
import '../../../../../utils/modal_handler.dart';

class QuickConnect extends StatelessWidget {
  const QuickConnect({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          // const ThemedRichText(
          //   textAlign: TextAlign.center,
          //   textSpans: [
          //     TextSpan(
          //       text:
          //           'Useable with OBS Studio version >= 28.0.0 or WebSocket version >= 5.0!',
          //       style: TextStyle(fontWeight: FontWeight.bold),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 12.0),
          BaseButton(
            onPressed: () => ModalHandler.showBaseDialog(
              context: context,
              dialogWidget: InfoDialog(
                title: 'Quick Connect',
                body: '',
                enableDontShowAgainOption: true,
                onPressed: (dontShow) {},
              ),
            ),
            icon: const Icon(CupertinoIcons.qrcode_viewfinder),
            text: 'Scan',
          ),
        ],
      ),
    );
  }
}
