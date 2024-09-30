import 'package:flutter/material.dart';

import '../../../../shared/general/base/divider.dart';
import '../../../../shared/general/custom_sliver_list.dart';
import '../../../../shared/general/responsive_widget_wrapper.dart';
import '../obs_widgets/obs_widgets.dart';
import '../obs_widgets/obs_widgets_mobile.dart';
import '../scenes/scenes.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomSliverList(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 24.0),
          child: Scenes(),
        ),
        Container(
          padding: const EdgeInsets.only(left: 8.0),
          alignment: Alignment.centerLeft,
          child: Text(
            'Widgets',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const ResponsiveWidgetWrapper(
          mobileWidget: Column(
            children: [
              SizedBox(height: 8.0),
              OBSWidgetsMobile(),
            ],
          ),
          tabletWidget: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: BaseDivider(),
              ),
              OBSWidgets(),
            ],
          ),
        ),
      ],
    );
  }
}
