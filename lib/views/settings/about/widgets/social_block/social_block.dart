import 'package:flutter/material.dart';
import 'package:obs_blade/views/settings/about/widgets/social_block/social_entry.dart';

class SocialBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SocialEntry(
          svgPath: 'assets/svgs/twitter.svg',
          link: 'https://twitter.com/Kounexx',
          linkText: 'Twitter',
        ),
        Container(height: 8.0),
        SocialEntry(
          svgPath: 'assets/svgs/linkedin.svg',
          link: 'https://www.linkedin.com/in/ren%C3%A9-schramowski-a35342157/',
          linkText: 'LinkedIn',
          logoSize: 28.0,
        ),
      ],
    );
  }
}
