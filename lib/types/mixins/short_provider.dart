import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

mixin ShortProvider {
  static T of<T>(BuildContext context) =>
      Provider.of<T>(context, listen: false);

  static T listen<T>(BuildContext context) => Provider.of<T>(context);
}
