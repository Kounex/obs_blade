import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../../stores/views/statistics.dart';

class FilterName extends StatelessWidget {
  const FilterName({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      placeholder: 'Filter by name...',
      clearButtonMode: OverlayVisibilityMode.always,
      onChanged: (name) => GetIt.instance<StatisticsStore>().setFilterName(
        name.trim().toLowerCase(),
      ),
    );
  }
}
