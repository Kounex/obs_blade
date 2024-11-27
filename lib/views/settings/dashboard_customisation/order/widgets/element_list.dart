import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../models/enums/dashboard_element.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import 'element_body.dart';

class ElementList extends StatefulWidget {
  const ElementList({super.key});

  @override
  State<ElementList> createState() => _ElementListState();
}

class _ElementListState extends State<ElementList> {
  final Map<DashboardElement, Widget> _preview = {};

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      builder: (context, settingsBox, child) {
        List<DashboardElement> elements = [
          ...settingsBox.get(SettingsKeys.DashboardElementsOrder.name,
              defaultValue: DashboardElement.values)
        ];
        return ReorderableListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.only(top: 18.0),
          buildDefaultDragHandles: false,
          itemCount: elements.length,
          proxyDecorator: (child, index, animation) => AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              final double animValue =
                  Curves.easeInOut.transform(animation.value);
              final double elevation = lerpDouble(0, 6, animValue)!;
              return Material(
                elevation: elevation,
                type: MaterialType.transparency,
                child: child,
              );
            },
            child: child,
          ),
          itemBuilder: (context, index) => ElementBody(
            index: index,
            key: ValueKey(elements[index]),
            element: elements[index],
            preview: _preview[elements[index]] ?? const Text('???'),
          ),
          onReorder: (oldIndex, newIndex) {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            elements.insert(newIndex, elements.removeAt(oldIndex));
            settingsBox.put(SettingsKeys.DashboardElementsOrder.name, elements);
          },
        );
      },
    );
  }
}
