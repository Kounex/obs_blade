import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../shared/general/base_card.dart';
import '../../../shared/general/themed/themed_cupertino_button.dart';
import '../../../shared/general/themed/themed_cupertino_scaffold.dart';
import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../../shared/overlay/base_result.dart';
import '../../../utils/modal_handler.dart';
import 'widgets/add_edit_theme/add_edit_theme.dart';
import 'widgets/custom_theme_list/custom_theme_list.dart';
import 'widgets/theme_active/theme_active.dart';

class CustomThemeView extends StatefulWidget {
  @override
  _CustomThemeViewState createState() => _CustomThemeViewState();
}

class _CustomThemeViewState extends State<CustomThemeView> {
  @override
  Widget build(BuildContext context) {
    return ThemedCupertinoScaffold(
      body: Builder(
        builder: (context) => TransculentCupertinoNavBarWrapper(
          previousTitle: 'Settings',
          title: 'Custom Theme',
          listViewChildren: [
            BaseCard(
              bottomPadding: 12.0,
              child: ThemeActive(),
            ),
            BaseCard(
              title: 'Predefined Themes',
              bottomPadding: 12.0,
              paddingChild: EdgeInsets.all(0),
              child: CustomThemeList(
                predefinedThemes: true,
              ),
            ),
            Stack(
              fit: StackFit.loose,
              alignment: Alignment.bottomCenter,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: BaseCard(
                    title: 'Your Themes',
                    trailingTitleWidget: ThemedCupertinoButton(
                      padding: const EdgeInsets.all(0),
                      onPressed: () =>
                          ModalHandler.showBaseCupertinoBottomSheet(
                        context: context,
                        modalWidgetBuilder: (context, scrollController) =>
                            AddEditTheme(
                          scrollController: scrollController,
                        ),
                      ),
                      text: 'Add Theme',
                    ),
                    bottomPadding: 12.0,
                    paddingChild: EdgeInsets.all(0),
                    child: CustomThemeList(),
                  ),
                ),
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 1.25, sigmaY: 1.25),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: BaseCard(
                          paintBorder: true,
                          child: BaseResult(
                            icon: BaseResultIcon.Missing,
                            text: 'Available soon...',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Padding(
                //   padding:
                //       const EdgeInsets.only(top: 21.0, left: 23.0, right: 23.0),
                //   child: Container(
                //     padding: EdgeInsets.only(top: 92.0),
                //     alignment: Alignment.center,
                //     decoration: BoxDecoration(
                //       gradient: LinearGradient(
                //         begin: Alignment.topCenter,
                //         end: Alignment.bottomCenter,
                //         stops: [0, 0.55],
                //         colors: [
                //           Colors.transparent,
                //           // Colors.black,
                //           Theme.of(context).scaffoldBackgroundColor,
                //         ],
                //       ),
                //     ),
                //     child: BaseResult(
                //       icon: BaseResultIcon.Missing,
                //       text: 'Available soon...',
                //     ),
                //   ),
                // )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
