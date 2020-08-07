import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../utils/styling_helper.dart';
import 'donate_button.dart';

class SupportDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CupertinoAlertDialog(
            content: SizedBox(
              height: 225.0,
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('Support',
                        style: Theme.of(context).textTheme.headline6),
                    Text(
                        'You sure? Tapped accidentaly? Or just curious? I mean, you know, I always appreciate the love! Motivates me to keep this app updated! But it\s completly optional :)'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DonateButton(text: 'Nice', value: 0.99),
                        DonateButton(text: 'Yoo', value: 2.99),
                        DonateButton(text: 'WTF?', value: 5.99),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Transform(
            transform: Matrix4.identity()..translate(0.0, -130.0),
            child: Container(
              height: 60.0,
              width: 60.0,
              decoration: BoxDecoration(
                // color: CupertinoDynamicColor.resolve(kDialogColor, context)
                //     .withOpacity(1.0),
                color: StylingHelper.MAIN_RED,
                shape: BoxShape.circle,
              ),
              child: Hero(
                tag: 'Support Me',
                child: Icon(
                  CupertinoIcons.heart_solid,
                  size: 38.0,
                ),
              ),
            ),
          ),
          Transform(
            transform: Matrix4.identity()..translate(110.0, -110.0),
            child: IconButton(
              icon: Icon(
                CupertinoIcons.clear_circled_solid,
                size: 24.0,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Transform(
            transform: Matrix4.identity()..translate(110.0, 110.0),
            child: CupertinoButton(
              child: Text('...'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
