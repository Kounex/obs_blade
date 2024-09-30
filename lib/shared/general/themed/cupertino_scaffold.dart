import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class ThemedCupertinoScaffold extends StatelessWidget {
  final Widget body;

  const ThemedCupertinoScaffold({
    super.key,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoScaffold(
      transitionBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IconTheme(
        data: Theme.of(context).iconTheme,
        child: this.body,
      ),
    );
  }
}
