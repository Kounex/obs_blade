import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../shared/general/base/divider.dart';

class AboutHeader extends StatelessWidget {
  const AboutHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle titleStyle = Theme.of(context)
        .textTheme
        .headlineMedium!
        .copyWith(fontWeight: FontWeight.w100);

    TextStyle descriptionStyle = Theme.of(context)
        .textTheme
        .bodySmall!
        .copyWith(fontWeight: FontWeight.w300);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.only(right: 24.0),
          height: 82.0,
          child: Image.asset('assets/images/kounex_logo_ai_no_background.png'),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.translate(
              offset: const Offset(-4.0, 0.0),
              child: Text(
                'OBS Blade',
                style: titleStyle,
              ),
            ),
            Container(
              padding: const EdgeInsets.only(bottom: 4.0),
              width: 180.0,
              child: const BaseDivider(),
            ),
            Text(
              'by Kounex (René Schramowski)',
              style: descriptionStyle,
            ),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                return Row(
                  children: [
                    Text(
                      'Version ',
                      style: descriptionStyle,
                    ),
                    if (snapshot.hasData)
                      Text(
                        '${snapshot.data!.version} (${snapshot.data!.buildNumber})',
                        style: descriptionStyle,
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
