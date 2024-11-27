import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/shared/general/hive_builder.dart';
import 'package:obs_blade/shared/overlay/base_progress_indicator.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/exposed_controls/hotkeys_control/hotkey_entry.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/exposed_controls/hotkeys_control/section_header.dart';

import '../../../../../../models/hotkey.dart';

class HotkeyList extends StatefulWidget {
  final ScrollController? controller;

  const HotkeyList({
    super.key,
    this.controller,
  });

  @override
  State<HotkeyList> createState() => _HotkeyListState();
}

class _HotkeyListState extends State<HotkeyList> {
  late final TextEditingController _controller;

  List<Hotkey> _filteredAllHotkeys = [];
  List<Hotkey> _filteredSavedHotkeys = [];

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController()..addListener(() => setState(() {}));
  }

  bool _lowerCaseContains(String base, String contain) =>
      base.toLowerCase().contains(contain.toLowerCase());

  List<Hotkey> _filterSavedHotkeys(Iterable<Hotkey> savedHotkeys) {
    return savedHotkeys
        .where((hotkey) => _lowerCaseContains(hotkey.name, _controller.text))
        .toList();
  }

  List<Hotkey> _filterAllHotkeys(
      ObservableSet<Hotkey> allHotkeys, Iterable<Hotkey> savedHotkeys) {
    return allHotkeys
        .where((hotkey) =>
            !savedHotkeys
                .any((savedHotkey) => savedHotkey.name == hotkey.name) &&
            _lowerCaseContains(hotkey.name, _controller.text))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hotkeys',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8.0),
              const Text(
                  'Only these internal names are exposed by the WebSocket API, so a bit of guessing and try and error is necessary to find the correct ones. Users have also reported that some hotkeys do not work at all via the WebSocket API, so expect problems when using this feature.'),
              const SizedBox(height: 12.0),
              CupertinoTextField(
                controller: _controller,
                placeholder: 'Filter...',
                clearButtonMode: OverlayVisibilityMode.editing,
              ),
              const SizedBox(height: 12.0),
            ],
          ),
        ),
        Expanded(
          child: HiveBuilder<Hotkey>(
              hiveKey: HiveKeys.Hotkey,
              builder: (context, hotkeyBox, child) {
                return Observer(
                  builder: (context) {
                    if (dashboardStore.hotkeys == null) {
                      return BaseProgressIndicator(
                        text: 'Fetching...',
                      );
                    }

                    _filteredSavedHotkeys =
                        _filterSavedHotkeys(hotkeyBox.values);

                    _filteredAllHotkeys = _filterAllHotkeys(
                        dashboardStore.hotkeys!, hotkeyBox.values);

                    return Scrollbar(
                      controller: this.widget.controller,
                      child: ListView(
                        controller: this.widget.controller,
                        padding: const EdgeInsets.symmetric(horizontal: 24.0) +
                            EdgeInsets.only(
                              bottom:
                                  MediaQuery.paddingOf(context).bottom + 12.0,
                            ),
                        children: [
                          if (hotkeyBox.values.isNotEmpty) ...[
                            const SectionHeader(
                              title: 'Favourites',
                            ),
                            ..._filteredSavedHotkeys.map(
                              (hotkey) => HotkeyEntry(
                                hotkeyBox: hotkeyBox,
                                hotkey: hotkey,
                              ),
                            ),
                            const SizedBox(height: 24.0),
                          ],
                          ...[
                            if (hotkeyBox.values.isNotEmpty)
                              const SectionHeader(
                                title: 'All',
                              ),
                            ..._filteredAllHotkeys.map(
                              (hotkey) => HotkeyEntry(
                                hotkeyBox: hotkeyBox,
                                hotkey: hotkey,
                              ),
                            ),
                          ],
                        ],
                        // itemCount: _filteredHotkeys.length,
                        // separatorBuilder: (context, index) =>
                        //     const BaseDivider(),
                        // itemBuilder: (context, index) => HotkeyEntry(
                        //   hotkey: _filteredHotkeys[index],
                        //   onStar: () {},
                        // ),
                      ),
                    );
                  },
                );
              }),
        ),
      ],
    );
  }
}
