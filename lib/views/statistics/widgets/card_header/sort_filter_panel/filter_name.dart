import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';

import '../../../../../stores/views/statistics.dart';

class FilterName extends StatefulWidget {
  const FilterName({Key? key}) : super(key: key);

  @override
  State<FilterName> createState() => _FilterNameState();
}

class _FilterNameState extends State<FilterName> {
  final List<ReactionDisposer> _d = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    _d.add(reaction(
      (_) => GetIt.instance<StatisticsStore>().triggeredDefault,
      (__) => _controller.clear(),
    ));
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
      clearButtonMode: OverlayVisibilityMode.always,
      onChanged: (name) => GetIt.instance<StatisticsStore>().setFilterName(
        name.trim().toLowerCase(),
      ),
    );
  }
}
