import 'package:flutter/cupertino.dart';

import '../../../../shared/general/custom_cupertino_dialog.dart';
import 'blacksmith_content/blacksmith_content.dart';
import 'support_header.dart';
import 'tips_content.dart';

enum SupportType {
  Blacksmith,
  Tips,
}

class SupportDialog extends StatefulWidget {
  final String title;
  final IconData icon;

  final SupportType type;

  const SupportDialog({
    Key? key,
    required this.title,
    this.icon = CupertinoIcons.heart_solid,
    required this.type,
  }) : super(key: key);

  @override
  State<SupportDialog> createState() => _SupportDialogState();
}

class _SupportDialogState extends State<SupportDialog> {
  @override
  Widget build(BuildContext context) {
    return CustomCupertinoDialog(
      paddingTop: 10.0,
      title: SupportHeader(
        title: this.widget.title,
        icon: this.widget.icon,
      ),
      content: SingleChildScrollView(
        child: () {
          if (this.widget.type == SupportType.Tips) {
            return const TipsContent();
          } else {
            return const BlacksmithContent();
          }
        }(),
      ),
    );
  }
}
