import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../shared/general/base/divider.dart';
import '../../../shared/general/themed/rich_text.dart';
import 'support_dialog/support_dialog.dart';

class BlacksmithDialog extends StatelessWidget {
  const BlacksmithDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SupportDialog(
      title: 'Blacksmith',
      icon: CupertinoIcons.hammer_fill,
      type: SupportType.Blacksmith,
      bodyWidget: ThemedRichText(
        textAlign: TextAlign.center,
        textSpans: [
          TextSpan(
            text: 'Become a blacksmith and forge your OBS Blade',
            style: Theme.of(context)
                .textTheme
                .bodyText1!
                .copyWith(fontStyle: FontStyle.italic),
          ),
          const WidgetSpan(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: BaseDivider(),
            ),
          ),
          TextSpan(
            text:
                'Blacksmith offers you visual customisation options for this app to make it more personalised! Create your own theme to change the overall look and feel of this app to make it yours!',
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ],
      ),
    );
  }
}
