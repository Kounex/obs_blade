import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../shared/general/base/divider.dart';

class AboutHeader extends StatelessWidget {
  const AboutHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium!
                    .copyWith(fontWeight: FontWeight.w100),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(bottom: 8.0),
              width: 180.0,
              child: const BaseDivider(),
            ),
            Text(
              'by Kounex (René Schramowski)',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(fontWeight: FontWeight.w100),
            ),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                return Row(
                  children: [
                    Text(
                      'Version ',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(fontWeight: FontWeight.w100),
                    ),
                    if (snapshot.hasData)
                      Text(
                        '${snapshot.data!.version} (${snapshot.data!.buildNumber})',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(fontWeight: FontWeight.w100),
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
