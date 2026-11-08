import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/base/divider.dart';
import '../../../../../shared/general/base/sheet.dart';
import '../../../../../utils/styling_helper.dart';
import '../license_modal/license_entries.dart';

/// Credits sheet: the app's logo, "Powered by Flutter" and every package
/// license (a package opens its licenses in a sheet on top)
class LicenseModal extends StatelessWidget {
  const LicenseModal({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseSheetScaffold(
      header: const BaseSheetTitle('Credits'),
      bodyIsScrollable: true,
      body: Column(
        children: [
          Align(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: SizedBox(
                width: 256.0,
                child: Image.asset(
                  StylingHelper.brightnessAwareOBSLogo(context),
                ),
              ),
            ),
          ),
          const BaseDivider(),
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
          const BaseDivider(),
          const Expanded(child: LicenseEntries()),
        ],
      ),
    );
  }
}
