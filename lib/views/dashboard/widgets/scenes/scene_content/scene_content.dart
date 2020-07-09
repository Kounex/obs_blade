import 'package:flutter/material.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import 'audio_inputs.dart';
import 'scene_items.dart';

class SceneContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(left: 24.0, right: 12.0),
            child: Column(
              children: [
                Container(
                  color: StylingHelper.MAIN_BLUE,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Text(
                      'Sources',
                      style: Theme.of(context)
                          .textTheme
                          .subtitle1
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Divider(height: 0.0),
                SizedBox(
                  height: 250.0,
                  child: SceneItems(),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(left: 12.0, right: 24.0),
            child: Column(
              children: [
                Container(
                  color: StylingHelper.MAIN_BLUE,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Text(
                      'Audio',
                      style: Theme.of(context)
                          .textTheme
                          .subtitle1
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Divider(height: 0.0),
                SizedBox(
                  height: 250.0,
                  child: AudioInputs(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                color: Theme.of(context).cardColor,
                height: 30.0,
                alignment: Alignment.center,
                child: Text('Sources'),
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).cardColor,
                height: 30.0,
                alignment: Alignment.center,
                child: Text('Audio'),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(height: 250.0, child: SceneItems()),
              ),
            ),
            VerticalDivider(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(height: 250.0, child: AudioInputs()),
              ),
            )
          ],
        ),
      ],
    );
  }
}
