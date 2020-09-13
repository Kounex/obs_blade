import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/overlay/base_result.dart';

import '../../../../shared/general/base_card.dart';

class PlaceholderConnection extends StatelessWidget {
  final double height;
  final double width;

  PlaceholderConnection({@required this.height, @required this.width})
      : assert(height != null && width != null);

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
          noPaddingChild: true,
          child: Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0),
            child: SizedBox(
              height: this.height,
              child: BaseResult(
                icon: BaseResultIcon.Missing,
                iconSize: 42.0,
                text:
                    'No saved connections yet...\nNo worries though, once you successfully connected to an OBS instance you can save one for later! :)',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
