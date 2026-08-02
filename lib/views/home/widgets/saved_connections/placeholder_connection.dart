import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../shared/general/base/card.dart';

class PlaceholderConnection extends StatelessWidget {
  final double height;
  final double width;

  const PlaceholderConnection(
      {super.key, required this.height, required this.width});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: this.width,
        child: BaseCard(
          topPadding: 0.0,
          rightPadding: 0.0,
          bottomPadding: 0.0,
          leftPadding: 0.0,
          paddingChild: const EdgeInsets.all(0),
          child: Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0),
            child: SizedBox(
              height: this.height,

              /// Same layout contract as [BaseResult] (glyph + centered
              /// description) but with a connection metaphor instead of
              /// the "missing" question mark
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.link,
                    size: 42.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 14.0),
                    child: Text(
                      'No saved connections yet...\nNo worries though, once you successfully connected to an OBS instance you can save one for later! :)',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
