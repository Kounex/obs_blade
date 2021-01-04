import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../../models/custom_theme.dart';
import '../../../../../shared/dialogs/confirmation.dart';
import '../../../../../shared/general/themed/themed_cupertino_button.dart';
import '../../../../../shared/general/validation_cupertino_textfield.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/modal_handler.dart';
import '../../../widgets/action_block.dart/light_divider.dart';
import 'color_row.dart';

class AddEditTheme extends StatefulWidget {
  final CustomTheme customTheme;
  final ScrollController scrollController;

  AddEditTheme({this.customTheme, this.scrollController});

  @override
  _AddEditThemeState createState() => _AddEditThemeState();
}

class _AddEditThemeState extends State<AddEditTheme> {
  CustomTheme _customTheme;

  TextEditingController _name;
  TextEditingController _description;

  @override
  void initState() {
    _customTheme = this.widget.customTheme ?? CustomTheme.basic();
    _name = TextEditingController(text: _customTheme.name);
    _description = TextEditingController(text: _customTheme.description);
    super.initState();
  }

  String _nameValidation(String name) {
    if (name.trim().length == 0) {
      return 'Please provide a theme name!';
    }
    if (Hive.box<CustomTheme>(HiveKeys.CustomTheme.name)
        .values
        .any((customTheme) => customTheme.name == name)) {
      if (this.widget.customTheme != null &&
          this.widget.customTheme.name != name) {
        return 'A theme with this name already exists!';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(right: 4.0),
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: Icon(CupertinoIcons.clear_circled_solid),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      this.widget.customTheme != null
                          ? 'Edit Theme'
                          : 'Add Theme',
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    ThemedCupertinoButton(
                      padding: EdgeInsets.only(left: 24.0),
                      text: 'Save',
                      onPressed: () {
                        if (_nameValidation(_name.text) == null) {
                          _customTheme.name = _name.text.trim();
                          _customTheme.description = _description.text.trim();
                          if (_customTheme.isInBox) {
                            _customTheme.dateUpdatedMS =
                                DateTime.now().millisecondsSinceEpoch;
                            Hive.box<CustomTheme>(HiveKeys.CustomTheme.name)
                                .put(_customTheme.key, _customTheme);
                            // _customTheme.save();
                          } else {
                            Hive.box<CustomTheme>(HiveKeys.CustomTheme.name)
                                .add(_customTheme);
                          }
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    ThemedCupertinoButton(
                        padding: EdgeInsets.only(left: 24.0),
                        isDestructive: this.widget.customTheme != null,
                        text: 'Delete',
                        onPressed: this.widget.customTheme != null
                            ? () => ModalHandler.showBaseDialog(
                                  context: context,
                                  dialogWidget: ConfirmationDialog(
                                    title: 'Delete Theme',
                                    isYesDestructive: true,
                                    body:
                                        'Are you sure you want to delete this custom theme? This action can\'t be undone!',
                                    onOk: (_) {
                                      Navigator.of(context).pop();
                                      Box settingsBox =
                                          Hive.box(HiveKeys.Settings.name);
                                      if (settingsBox.get(
                                              SettingsKeys
                                                  .ActiveCustomThemeUUID.name,
                                              defaultValue: '') ==
                                          _customTheme.uuid) {
                                        settingsBox.put(
                                            SettingsKeys
                                                .ActiveCustomThemeUUID.name,
                                            '');
                                      }
                                      _customTheme.delete();
                                    },
                                  ),
                                )
                            : null),
                  ],
                ),
                LightDivider(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: this.widget.scrollController,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Column(
                        children: [
                          ValidationCupertinoTextfield(
                            controller: _name,
                            placeholder: 'Name',
                            autocorrect: true,
                            check: (name) => _nameValidation(name),
                          ),
                          ValidationCupertinoTextfield(
                            controller: _description,
                            placeholder: 'Description (Optional)',
                            autocorrect: true,
                            minLines: 3,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 32.0),
                            child: ColorRow(
                              title: 'Is this a light theme?',
                              description:
                                  'If this theme is intended to be a light theme, this option should be checked so text / system UI correctly adapts',
                              colorHex: _customTheme.cardColorHex,
                              active: _customTheme.useLightBrightness ?? false,
                              onActiveChanged: (active) => setState(() =>
                                  _customTheme.useLightBrightness = active),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 32.0),
                            child: ColorRow(
                              title: 'Card Color',
                              description:
                                  'Most UI elements are inside Cards so this is kinda the primary color of the app',
                              colorHex: _customTheme.cardColorHex,
                              onSave: (colorHex) => setState(
                                  () => _customTheme.cardColorHex = colorHex),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 32.0),
                            child: ColorRow(
                              title: 'AppBar Color',
                              description:
                                  'The top UI element which contains the title of the current view, back navigation etc.',
                              colorHex: _customTheme.appBarColorHex,
                              onSave: (colorHex) => setState(
                                  () => _customTheme.appBarColorHex = colorHex),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 32.0),
                            child: ColorRow(
                              title: 'TabBar Color',
                              description:
                                  'The bottom navigation bar containing the tabs for this app',
                              colorHex: _customTheme.tabBarColorHex,
                              onSave: (colorHex) => setState(
                                  () => _customTheme.tabBarColorHex = colorHex),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 32.0),
                            child: ColorRow(
                              title: 'Accent Color',
                              description:
                                  'Is being used by action / toggle elements like Switch, Button, etc.',
                              colorHex: _customTheme.accentColorHex,
                              onSave: (colorHex) => setState(
                                  () => _customTheme.accentColorHex = colorHex),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 32.0),
                            child: ColorRow(
                              title: 'Highlight Color',
                              description:
                                  'Active state is being displayed with this color like active scene, active tab, some buttons, etc.',
                              colorHex: _customTheme.highlightColorHex,
                              onSave: (colorHex) => setState(() =>
                                  _customTheme.highlightColorHex = colorHex),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 32.0),
                            child: ColorRow(
                              title: 'Background Color',
                              description:
                                  'Color for the typical background which behind all the UI elements',
                              colorHex: _customTheme.backgroundColorHex,
                              onSave: (colorHex) => setState(() =>
                                  _customTheme.backgroundColorHex = colorHex),
                            ),
                          ),
                          SizedBox(height: 32.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
