import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../shared/general/base/card.dart';
import '../../../../shared/overlay/base_result.dart';

class PlaceholderConnection extends StatelessWidget {
  final double height;
  final double width;

  const PlaceholderConnection(
      {Key? key, required this.height, required this.width})
      : super(key: key);

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
              child: const BaseResult(
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
