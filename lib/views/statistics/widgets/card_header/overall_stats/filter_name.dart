import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/stores/views/statistics.dart';
import 'package:provider/provider.dart';

class FilterName extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      placeholder: 'Filter by name...',
      clearButtonMode: OverlayVisibilityMode.editing,
      onChanged: (name) => context.read<StatisticsStore>().setFilterName(
            name.trim().toLowerCase(),
          ),
    );
  }
}
