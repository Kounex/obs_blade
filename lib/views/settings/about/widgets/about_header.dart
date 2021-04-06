import 'package:flutter/material.dart';
import 'package:obs_blade/views/settings/widgets/action_block.dart/light_divider.dart';
import 'package:package_info/package_info.dart';

class AboutHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.only(right: 24.0),
          height: 82.0,
          child: Image.asset('assets/images/kounex_logo_ai_no_background.png'),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.translate(
              offset: Offset(-4.0, 0.0),
              child: Text(
                'OBS Blade',
                style: Theme.of(context).textTheme.headline4,
              ),
            ),
            Container(
              padding: EdgeInsets.only(bottom: 8.0),
              width: 180.0,
              child: LightDivider(),
            ),
            Text(
              'by Kounex (René Schramowski)',
              style: Theme.of(context).textTheme.caption,
            ),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                return Row(
                  children: [
                    Text(
                      'Version ',
                      style: Theme.of(context).textTheme.caption,
                    ),
                    if (snapshot.hasData)
                      Text(
                        '${snapshot.data!.version} (${snapshot.data!.buildNumber})',
                        style: Theme.of(context).textTheme.caption,
                      ),
                  ],
                );
              },
            ),
          ],
        )
      ],
    );
  }
}
