import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/views/settings/custom_theme/widgets/add_edit_theme/custom_logo_row.dart';
import 'package:obs_blade/views/settings/custom_theme/widgets/add_edit_theme/theme_loader.dart';

import '../../../../../models/custom_theme.dart';
import '../../../../../shared/dialogs/confirmation.dart';
import '../../../../../shared/general/themed/themed_cupertino_button.dart';
import '../../../../../shared/general/validation_cupertino_textfield.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/modal_handler.dart';
import '../../../widgets/action_block.dart/light_divider.dart';
import 'theme_row.dart';

class AddEditTheme extends StatefulWidget {
  final CustomTheme? customTheme;
  final ScrollController? scrollController;

  const AddEditTheme({Key? key, this.customTheme, this.scrollController})
      : super(key: key);

  @override
  _AddEditThemeState createState() => _AddEditThemeState();
}

class _AddEditThemeState extends State<AddEditTheme> {
  late CustomTheme _initialTheme;
  late CustomTheme _customTheme;

  late CustomValidationTextEditingController _name;
  late TextEditingController _description;

  @override
  void initState() {
    _customTheme = CustomTheme.basic();
    _initialTheme = CustomTheme.basic();
    if (this.widget.customTheme != null) {
      CustomTheme.copyFrom(this.widget.customTheme!, _customTheme, full: true);
      CustomTheme.copyFrom(this.widget.customTheme!, _initialTheme, full: true);
    }
    _name = CustomValidationTextEditingController(
      text: _customTheme.name,
      check: _nameValidation,
    );

    _description = TextEditingController(text: _customTheme.description);
    super.initState();
  }

  String? _nameValidation(String name) {
    if (name.trim().isEmpty) {
      return 'Please provide a theme name!';
    }
    if (Hive.box<CustomTheme>(HiveKeys.CustomTheme.name)
        .values
        .any((customTheme) => customTheme.name == name)) {
      if (this.widget.customTheme != null &&
          this.widget.customTheme!.name != name) {
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
          padding: const EdgeInsets.only(right: 4.0),
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(CupertinoIcons.clear_circled_solid),
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
                      padding: const EdgeInsets.only(left: 24.0),
                      text: 'Save',
                      onPressed: () {
                        _name.submit();
                        if (_name.isValid) {
                          if (this.widget.customTheme != null) {
                            CustomTheme.copyFrom(
                                _customTheme, this.widget.customTheme!);
                            this.widget.customTheme!.name = _name.text.trim();
                            this.widget.customTheme!.description =
                                _description.text.trim();
                            this.widget.customTheme!.dateUpdatedMS =
                                DateTime.now().millisecondsSinceEpoch;
                            this.widget.customTheme!.save();
                          } else {
                            _customTheme.name = _name.text.trim();
                            _customTheme.description = _description.text.trim();
                            Hive.box<CustomTheme>(HiveKeys.CustomTheme.name)
                                .add(_customTheme);
                          }
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    ThemedCupertinoButton(
                        padding: const EdgeInsets.only(left: 24.0),
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
                                      Box settingsBox =
                                          Hive.box(HiveKeys.Settings.name);
                                      if (settingsBox.get(
                                              SettingsKeys
                                                  .ActiveCustomThemeUUID.name,
                                              defaultValue: '') ==
                                          this.widget.customTheme!.uuid) {
                                        settingsBox.put(
                                            SettingsKeys
                                                .ActiveCustomThemeUUID.name,
                                            '');
                                      }
                                      this.widget.customTheme!.delete();
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                )
                            : null),
                  ],
                ),
                const LightDivider(),
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
                          ),
                          CupertinoTextField(
                            controller: _description,
                            placeholder: 'Description (Optional)',
                            minLines: 3,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 32.0),
                          ThemeLoader(
                            onLoadTheme: (theme) => setState(() =>
                                CustomTheme.copyFrom(theme, _customTheme)),
                          ),
                          const SizedBox(height: 32.0),
                          CustomLogoRow(
                            customTheme: _customTheme,
                            onReset: () =>
                                setState(() => _customTheme.customLogo = null),
                            onSelectLogo: (imageBytes) => setState(
                              () => _customTheme.customLogo =
                                  base64Encode(imageBytes),
                            ),
                          ),
                          const SizedBox(height: 32.0),
                          ThemeRow(
                            title: 'Logo Background',
                            description:
                                'If you want to have a specific background color for your logo instead of the app bar color, you can cusotmise it here',
                            colorHex: _customTheme.logoAppBarColorHex,
                            onReset: () => setState(
                                () => _customTheme.logoAppBarColorHex = null),
                            onSave: (colorHex) => setState(() =>
                                _customTheme.logoAppBarColorHex = colorHex),
                          ),
                          const SizedBox(height: 32.0),
                          ThemeRow(
                            title: 'Is this a light theme?',
                            description:
                                'If this theme is intended to be a light theme, this option should be checked so text / system UI correctly adapts',
                            active: _customTheme.useLightBrightness,
                            onActiveChanged: (active) => setState(
                                () => _customTheme.useLightBrightness = active),
                          ),
                          const SizedBox(height: 32.0),
                          ThemeRow(
                            title: 'Card Color',
                            description:
                                'Most UI elements are inside Cards so this is kinda the primary color of the app',
                            colorHex: _customTheme.cardColorHex,
                            onReset: () => setState(() => _customTheme
                                .cardColorHex = _initialTheme.cardColorHex),
                            onSave: (colorHex) => setState(
                                () => _customTheme.cardColorHex = colorHex),
                          ),
                          const SizedBox(height: 32.0),
                          ThemeRow(
                            title: 'AppBar Color',
                            description:
                                'The top UI element which contains the title of the current view, back navigation etc.',
                            colorHex: _customTheme.appBarColorHex,
                            onReset: () => setState(() => _customTheme
                                .appBarColorHex = _initialTheme.appBarColorHex),
                            onSave: (colorHex) => setState(
                                () => _customTheme.appBarColorHex = colorHex),
                          ),
                          const SizedBox(height: 32.0),
                          ThemeRow(
                            title: 'TabBar Color',
                            description:
                                'The bottom navigation bar containing the tabs for this app',
                            colorHex: _customTheme.tabBarColorHex,
                            onReset: () => setState(() => _customTheme
                                .tabBarColorHex = _initialTheme.tabBarColorHex),
                            onSave: (colorHex) => setState(
                                () => _customTheme.tabBarColorHex = colorHex),
                          ),
                          const SizedBox(height: 32.0),
                          ThemeRow(
                            title: 'Accent Color',
                            description:
                                'Is being used by action / toggle elements like Switch, Button, etc.',
                            colorHex: _customTheme.accentColorHex,
                            onReset: () => setState(() => _customTheme
                                .accentColorHex = _initialTheme.accentColorHex),
                            onSave: (colorHex) => setState(
                                () => _customTheme.accentColorHex = colorHex),
                          ),
                          const SizedBox(height: 32.0),
                          ThemeRow(
                            title: 'Highlight Color',
                            description:
                                'Active state is being displayed with this color like active scene, active tab, some buttons, etc.',
                            colorHex: _customTheme.highlightColorHex,
                            onReset: () => setState(() =>
                                _customTheme.highlightColorHex =
                                    _initialTheme.highlightColorHex),
                            onSave: (colorHex) => setState(() =>
                                _customTheme.highlightColorHex = colorHex),
                          ),
                          const SizedBox(height: 32.0),
                          ThemeRow(
                            title: 'Background Color',
                            description:
                                'Color for the typical background which behind all the UI elements',
                            colorHex: _customTheme.backgroundColorHex,
                            onReset: () => setState(() =>
                                _customTheme.backgroundColorHex =
                                    _initialTheme.backgroundColorHex),
                            onSave: (colorHex) => setState(() =>
                                _customTheme.backgroundColorHex = colorHex),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).padding.bottom + 32.0),
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
