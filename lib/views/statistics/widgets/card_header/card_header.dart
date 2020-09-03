import 'package:flutter/material.dart';
import 'package:obs_blade/utils/styling_helper.dart';

class IconClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0.0, 42.0)
    ..lineTo(size.width - 32, 42.0)
    ..quadraticBezierTo(size.width - 28, 42.0, size.width - 28, 46.0)
    ..lineTo(size.width - 28, size.height)
    ..lineTo(0.0, size.height)
    ..close();

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

class CardHeader extends StatelessWidget {
  final String title;
  final String description;
  final Widget someStats;

  CardHeader({@required this.title, this.description = '', this.someStats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Transform.translate(
              offset: Offset(0.0, -12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    this.title,
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  SizedBox(
                    width: 108.0,
                    child: Divider(height: 8.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      this.description,
                      style: Theme.of(context).textTheme.caption,
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Transform.translate(
                offset: Offset(42.0, -42.0),
                child: ClipPath(
                  clipper: IconClipper(),
                  clipBehavior: Clip.antiAlias,
                  child: Transform.rotate(
                    angle: -0.0,
                    child: Icon(
                      StylingHelper.CUPERTINO_PIE_CHART_SOLID,
                      size: 128.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        this.someStats ?? Container(),
      ],
    );
  }
}
