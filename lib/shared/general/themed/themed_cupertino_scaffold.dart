import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class ThemedCupertinoScaffold extends StatelessWidget {
  final Widget body;

  ThemedCupertinoScaffold({@required this.body});

  @override
  Widget build(BuildContext context) {
    return CupertinoScaffold(
      transitionBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Builder(
        builder: (context) => this.body,
      ),
    );
  }
}
