import 'package:flutter/material.dart';
import 'package:obs_blade/views/intro/intro.dart';

class IntroSlide extends StatelessWidget {
  final String imagePath;
  final String slideText;

  IntroSlide({@required this.imagePath, @required this.slideText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 24.0,
        right: 24.0,
        bottom: MediaQuery.of(context).padding.bottom +
            kIntroControlsBottomPadding +
            32.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.scale(
            scale: 1.3,
            child: Transform.translate(
              offset: Offset(0.0, -MediaQuery.of(context).size.height * 0.05),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height / 3,
                ),
                child: Image.asset(this.imagePath),
              ),
            ),
          ),
          Card(
            color: Colors.black12,
            child: Padding(
              padding: EdgeInsets.all(18.0),
              child: Text(
                this.slideText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          )
        ],
      ),
    );
  }
}
