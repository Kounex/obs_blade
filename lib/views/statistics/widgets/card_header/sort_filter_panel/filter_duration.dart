import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/general/keyboard_number_header.dart';

import '../../../../../shared/general/cupertino_dropdown.dart';
import '../../../../../stores/views/statistics.dart';

const List<DurationFilter?> kActiveDurationFilters = [
  null,
  DurationFilter.Shorter,
  DurationFilter.Longer,
];

class FilterDuration extends StatefulWidget {
  const FilterDuration({Key? key}) : super(key: key);

  @override
  State<FilterDuration> createState() => _FilterDurationState();
}

class _FilterDurationState extends State<FilterDuration> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = GetIt.instance<StatisticsStore>();

    return Observer(
      builder: (_) => Row(
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
                        : null),
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
