import 'package:flutter/material.dart';

class SwitcherCard extends StatelessWidget {
  final String title;
  final Widget child;

  SwitcherCard({@required this.title, @required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 24.0, top: 12.0, bottom: 12.0),
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              child: Container(
                // first element of the AnimatedSwitcher needs to have a key if the
                // switching widgets share the same widget type (in this case Container)
                key: Key(this.title),
                width: 150.0,
                child: Text(
                  this.title,
                  style: Theme.of(context)
                      .textTheme
                      .headline5
                      .copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
          Divider(
            height: 0.0,
          ),
          AnimatedSwitcher(
              duration: Duration(milliseconds: 200), child: this.child)
        ],
      ),
    );
  }
}
