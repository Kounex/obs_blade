import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../stores/views/statistics.dart';

class FilterName extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      placeholder: 'Filter by name...',
      clearButtonMode: OverlayVisibilityMode.always,
      onChanged: (name) => context.read<StatisticsStore>().setFilterName(
            name.trim().toLowerCase(),
          ),
    );
  }
}
