import 'package:flutter/material.dart';

import '../../../../../shared/dialogs/info.dart';

class BlacksmithNotAvailableDialog extends StatelessWidget {
  const BlacksmithNotAvailableDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoDialog(
      body:
          'Blacksmith is a highly optional feature which enables customising the appearance of OBS Blade with own themes etc. (no actual features are hidden!) - definitely for power users. It\'s a paid feature for App Store / Google Play users and it would be unfair to offer it for free in this version. Maybe I will come up with a way to include this feature in a later stage!',
    );
  }
}
