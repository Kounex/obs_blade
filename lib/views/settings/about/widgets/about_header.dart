import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import '../../widgets/subpage_header.dart';
import '../../widgets/version_stamp.dart';

class AboutHeader extends StatelessWidget {
  const AboutHeader({super.key});

  @override
  Widget build(BuildContext context) {
    TextStyle descriptionStyle = Theme.of(context).textTheme.bodySmall!
        .copyWith(
          fontWeight: FontWeight.w300,

          /// Bylines / version read at the footnote level (token-delta §2.1)
          color: Theme.of(context).extension<AppTextColors>()!.textTertiary,
        );

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
        VersionStamp(style: descriptionStyle, showBuildNumber: true),
      ],
    );
  }
}
