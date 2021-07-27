import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base/base_button.dart';

class DonateButton extends StatelessWidget {
  final String text;
  final double value;

  DonateButton({required this.text, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 65.0,
      width: 65.0,
      child: BaseButton(
        padding: const EdgeInsets.all(0.0),
        onPressed: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(this.text),
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text('${this.value.toString()}€'),
            ),
          ],
        ),
      ),
    );
  }
}
