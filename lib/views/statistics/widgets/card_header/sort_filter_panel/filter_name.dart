import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../stores/views/statistics.dart';
import '../../../../../utils/styling_helper.dart';

class FilterName extends StatefulWidget {
  const FilterName({super.key});

  @override
  State<FilterName> createState() => _FilterNameState();
}

class _FilterNameState extends State<FilterName> {
  final List<ReactionDisposer> _d = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    _d.add(
      reaction(
        (_) => GetIt.instance<StatisticsStore>().triggeredDefault,
        (__) => _controller.clear(),
      ),
    );
  }

  @override
  void dispose() {
    for (final d in _d) {
      d();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: _controller,
      placeholder: 'Filter by name...',

      /// Raised-card fill + divider hairline (same explicit decoration as
      /// [CupertinoDropdown]) - the stock one renders pure black in dark mode
      decoration: BoxDecoration(
        color: StylingHelper.lightenDarkenColor(Theme.of(context).cardColor, 8),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      clearButtonMode: OverlayVisibilityMode.always,
      onChanged: (name) => GetIt.instance<StatisticsStore>().setFilterName(
        name.trim().toLowerCase(),
      ),
    );
  }
}
