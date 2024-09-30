import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/shared/general/keyboard_number_header.dart';

import '../../../../../shared/general/cupertino_dropdown.dart';
import '../../../../../stores/views/statistics.dart';

const List<DurationFilter?> kActiveDurationFilters = [
  null,
  DurationFilter.Shorter,
  DurationFilter.Longer,
];

class FilterDuration extends StatefulWidget {
  const FilterDuration({
    super.key,
  });

  @override
  State<FilterDuration> createState() => _FilterDurationState();
}

class _FilterDurationState extends State<FilterDuration> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  final List<ReactionDisposer> _disposers = [];

  @override
  void initState() {
    super.initState();

    StatisticsStore statisticsStore = GetIt.instance<StatisticsStore>();

    _disposers.add(reaction((_) => statisticsStore.triggeredDefault, (_) {
      _controller.text = '';
    }));

    _disposers
        .add(reaction((_) => statisticsStore.durationFilter, (durationFilter) {
      if (durationFilter != null && _controller.text.trim().isEmpty) {
        if (statisticsStore.durationFilterAmount == null) {
          _controller.text = '1';
          statisticsStore.setDurationFilterAmount(_controller.text);
        } else {
          _controller.text = statisticsStore.durationFilterAmount.toString();
        }
      }
    }));
  }

  @override
  void dispose() {
    super.dispose();

    for (final d in _disposers) {
      d();
    }
  }

  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = GetIt.instance<StatisticsStore>();

    return Observer(
      builder: (context) => Row(
        children: [
          SizedBox(
            width: 142.0,
            child: CupertinoDropdown<DurationFilter?>(
              value: statisticsStore.durationFilter,
              items: kActiveDurationFilters
                  .map((durationFilter) => DropdownMenuItem<DurationFilter?>(
                        value: durationFilter,
                        child: Text(durationFilter?.text ?? '-'),
                      ))
                  .toList(),
              selectedItemBuilder: (context) => kActiveDurationFilters
                  .map((durationFilter) => Text(durationFilter?.text ?? '-'))
                  .toList(),
              onChanged: (durationFilter) =>
                  statisticsStore.setDurationFilter(durationFilter),
            ),
          ),
          const SizedBox(width: 12.0),
          Flexible(
            child: KeyboardNumberHeader(
              focusNode: _focusNode,
              child: CupertinoTextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: statisticsStore.durationFilter != null,
                style: TextStyle(
                  color: statisticsStore.durationFilter == null
                      ? Colors.white38
                      : null,
                  fontFeatures: const [
                    FontFeature.tabularFigures(),
                  ],
                ),
                maxLength: 4,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                keyboardType: const TextInputType.numberWithOptions(),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (amount) =>
                    statisticsStore.setDurationFilterAmount(amount),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          SizedBox(
            width: 98.0,
            child: CupertinoDropdown<TimeUnit>(
              value: statisticsStore.durationFilterTimeUnit,
              items: TimeUnit.values
                  .map((timeUnit) => DropdownMenuItem<TimeUnit>(
                        value: timeUnit,
                        child: Text(timeUnit.name),
                      ))
                  .toList(),
              selectedItemBuilder: (context) => TimeUnit.values
                  .map((timeUnit) => Text(timeUnit.name))
                  .toList(),
              onChanged: statisticsStore.durationFilter != null
                  ? (timeUnit) =>
                      statisticsStore.setDurationFilterTimeUnit(timeUnit!)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
