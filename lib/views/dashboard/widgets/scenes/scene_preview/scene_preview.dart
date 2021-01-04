import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:obs_blade/shared/overlay/base_progress_indicator.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/utils/network_helper.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/scene_preview/preview_warning_dialog.dart';
import 'package:provider/provider.dart';

class ScenePreview extends StatefulWidget {
  @override
  _ScenePreviewState createState() => _ScenePreviewState();
}

class _ScenePreviewState extends State<ScenePreview>
    with SingleTickerProviderStateMixin {
  ExpandableController _expandController = ExpandableController();

  AnimationController _animController;

  Animation<double> _rotation;
  Animation<Color> _color;

  @override
  void initState() {
    _animController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _rotation = Tween<double>(begin: 0.0, end: 0.5).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _color = ColorTween(
      begin: Theme.of(context).iconTheme.color,
      end: Theme.of(context).accentColor,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _expandController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = context.watch<DashboardStore>();

    double maxImageHeight = min(
      MediaQuery.of(context).size.height -
          kBottomNavigationBarHeight -
          kToolbarHeight -
          64 -
          48 -
          24,
      300,
    );

    VoidCallback onExpand = () {
      _expandController.toggle();
      if (_animController.isDismissed) {
        _animController.forward();
      } else if (_animController.isCompleted) {
        _animController.reverse();
      }
      dashboardStore.setShouldRequestPreviewImage(
          !dashboardStore.shouldRequestPreviewImage);
    };

    return ValueListenableBuilder(
      valueListenable: Hive.box(HiveKeys.Settings.name)
          .listenable(keys: [SettingsKeys.DontShowPreviewWarning.name]),
      builder: (context, Box settingsBox, child) => GestureDetector(
        onTap: () => !settingsBox.get(SettingsKeys.DontShowPreviewWarning.name,
                    defaultValue: false) &&
                !_expandController.expanded
            ? ModalHandler.showBaseDialog(
                context: context,
                dialogWidget: PreviewWarningDialog(
                  onOk: (checked) {
                    onExpand();
                    settingsBox.put(
                        SettingsKeys.DontShowPreviewWarning.name, checked);
                  },
                ),
              )
            : onExpand(),
        child: child,
      ),
      child: Container(
        color: Theme.of(context).appBarTheme.color,
        child: ExpandablePanel(
          controller: _expandController,
          theme: ExpandableThemeData(
            inkWellBorderRadius: BorderRadius.zero,
            headerAlignment: ExpandablePanelHeaderAlignment.center,
            bodyAlignment: ExpandablePanelBodyAlignment.center,
            hasIcon: false,
            tapBodyToExpand: false,
            tapBodyToCollapse: false,
            tapHeaderToExpand: false,
          ),
          header: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedBuilder(
                  animation: _animController,
                  child: Text('Show preview'),
                  builder: (context, child) => Text(
                    'Show preview',
                    style: TextStyle(color: _color.value),
                  ),
                ),
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) => RotationTransition(
                    turns: _rotation,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: _color.value,
                    ),
                  ),
                ),
              ],
            ),
          ),
          expanded: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Observer(
              builder: (_) => dashboardStore.scenePreviewImageBytes != null
                  ? Image.memory(
                      dashboardStore.scenePreviewImageBytes,
                      height: maxImageHeight,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    )
                  : BaseProgressIndicator(
                      text: 'Fetching preview...',
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
