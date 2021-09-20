import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/general/themed/themed_cupertino_button.dart';
import '../../../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../../widgets/action_block.dart/light_divider.dart';
import '../license_modal/license_entries.dart';

class LicenseModal extends StatelessWidget {
  final ScrollController? scrollController;

  const LicenseModal({Key? key, this.scrollController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TransculentCupertinoNavBarWrapper(
      title: 'Credits',
      actions: ThemedCupertinoButton(
        padding: const EdgeInsets.all(0),
        text: 'Done',
        onPressed: () => Navigator.of(context).pop(),
      ),
      customBody: Column(
        children: [
          Align(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: SizedBox(
                width: 256.0,
                child: Image.asset('assets/images/base_logo.png'),
              ),
            ),
          ),
          const LightDivider(),
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.only(right: 8.0),
                  height: 32.0,
                  child: Image.asset('assets/images/flutter_logo_render.png'),
                ),
                const Text('Powered by Flutter'),
              ],
            ),
          ),
          const LightDivider(),
          Expanded(
            child: LicenseEntries(
              scrollController: scrollController,
            ),
          ),
        ],
      ),
    );
  }
}
