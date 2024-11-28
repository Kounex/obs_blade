import 'package:flutter/material.dart';

import '../../../../../shared/general/base/dropdown.dart';

class ProfilesPreview extends StatelessWidget {
  const ProfilesPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BaseDropdown<String>(
            value: '<name>',
            items: [
              BaseDropdownItem(
                value: '<name>',
                text: '<name>',
              ),
            ],
            label: 'Profile',
          ),
        ),
        Expanded(
          child: BaseDropdown<String>(
            value: '<name>',
            items: [
              BaseDropdownItem(
                value: '<name>',
                text: '<name>',
              ),
            ],
            label: 'Scene Collection',
          ),
        ),
      ],
    );
  }
}
