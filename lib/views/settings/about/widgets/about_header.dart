import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../widgets/subpage_header.dart';

class AboutHeader extends StatelessWidget {
  const AboutHeader({super.key});

  @override
  Widget build(BuildContext context) {
    TextStyle descriptionStyle = Theme.of(
      context,
    ).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w300);

    return SubpageHeader(
      visual: SizedBox(
        height: 82.0,

        /// The logo asset is full-bleed (glyph touches the canvas edges) -
        /// inset ~8% so it keeps some air inside the box
        child: Padding(
          padding: const EdgeInsets.all(6.5),
          child: Image.asset('assets/images/kounex_logo_ai_no_background.png'),
        ),
      ),
      title: 'OBS Blade',
      bylines: [
        Text('by Kounex (René Schramowski)', style: descriptionStyle),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            return Row(
              children: [
                Text('Version ', style: descriptionStyle),
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
    );
  }
}
