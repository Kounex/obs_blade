import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base/button.dart';

import '../../../../../shared/general/described_box.dart';

class ControlsPreview extends StatelessWidget {
  const ControlsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return DescribedBox(
      label: 'Various Controls',
      labelBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
      borderColor: Theme.of(context).dividerColor,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: BaseButton(
              text: '<action-1>',
              onPressed: () {},
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: BaseButton(
              text: '<action-2>',
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
