import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SupportHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const SupportHeader({
    Key? key,
    required this.title,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.identity()..translate(0.0, -10.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Transform(
                transform: Matrix4.identity()..translate(-10.0),
                child: Container(
                  height: 64.0,
                  width: 64.0,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .switchTheme
                        .trackColor!
                        .resolve({MaterialState.selected}),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(12.0),
                    ),
                  ),
                  child: Transform(
                    transform: Matrix4.identity()..translate(4.0, 4.0),
                    child: Icon(
                      this.icon,
                      size: 38.0,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  CupertinoIcons.clear_circled_solid,
                  size: 24.0,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Transform(
            transform: Matrix4.identity()..translate(0.0, 4.0),
            child: Text(
              this.title,

              /// Taken from [CupertinoAlertDialog]'s title property where text
              /// is being transformed with this style hardcoded (not accessible from
              /// the outside unfortunately - therefore copy&pasted for now)
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontFamily: '.SF UI Display',
                    inherit: false,

                    /// Changed from 17.0
                    fontSize: 20.0,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    letterSpacing: -0.5,
                    textBaseline: TextBaseline.alphabetic,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
