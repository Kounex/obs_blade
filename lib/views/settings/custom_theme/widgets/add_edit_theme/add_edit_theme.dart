import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/shared/dialogs/confirmation.dart';
import 'package:obs_blade/shared/general/validation_cupertino_textfield.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/views/settings/widgets/action_block.dart/light_divider.dart';

import '../../../../../models/custom_theme.dart';
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
    _customTheme = widget.customTheme ?? CustomTheme.basic();
    _name = TextEditingController(text: _customTheme.name);
    _description = TextEditingController(text: _customTheme.description);
    super.initState();
  }

  String _nameValidation(String name) => name.trim().length == 0
      ? 'Please provide a theme name!'
      : Hive.box<CustomTheme>(HiveKeys.CustomTheme.name)
              .values
              .any((customTheme) => customTheme.name == name)
          ? 'A theme with this name already exists!'
          : null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 0.0),
            child: Row(
              children: [
                Text(
                  widget.customTheme != null ? 'Edit Theme' : 'Add Theme',
                  style: Theme.of(context).textTheme.headline5,
                ),
                CupertinoButton(
                  padding: EdgeInsets.only(left: 24.0),
                  child: Text('Save'),
                  onPressed: () {
                    if (_nameValidation(_name.text) == null) {
                      _customTheme.name = _name.text.trim();
                      _customTheme.description = _description.text.trim();
                      _customTheme.isInBox
                          ? _customTheme.save()
                          : Hive.box<CustomTheme>(HiveKeys.CustomTheme.name)
                              .add(_customTheme);
                      Navigator.of(context).pop();
                    }
                  },
                ),
                CupertinoButton(
                    padding: EdgeInsets.only(left: 24.0),
                    child: Text(
                      'Delete',
                      style: widget.customTheme != null
                          ? TextStyle(color: CupertinoColors.destructiveRed)
                          : null,
                    ),
                    onPressed: widget.customTheme != null
                        ? () => ModalHandler.showBaseDialog(
                              context: context,
                              dialogWidget: ConfirmationDialog(
                                title: 'Delete Theme',
                                isYesDestructive: true,
                                body:
                                    'Are you sure you want to delete this custom theme? This action can\'t be undone!',
                                onOk: () {
                                  Navigator.of(context).pop();
                                  _customTheme.delete();
                                },
                              ),
                            )
                        : null),
              ],
            ),
          ),
          LightDivider(),
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
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
                        colorTitle: 'Primary Color',
                        colorDescription:
                            'Main color which is used for the AppBar, BottomBar, Cards, etc.',
                        colorHex: _customTheme.primaryColorHex,
                        onSave: (colorHex) => setState(
                            () => _customTheme.primaryColorHex = colorHex),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32.0),
                      child: ColorRow(
                        colorTitle: 'Accent Color',
                        colorDescription:
                            'Is being used by action / toggle elements like Switch, Button, etc.',
                        colorHex: _customTheme.accentColorHex,
                        onSave: (colorHex) => setState(
                            () => _customTheme.accentColorHex = colorHex),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32.0),
                      child: ColorRow(
                        colorTitle: 'Highlight Color',
                        colorDescription:
                            'Active state is being displayed with this color, not widely used, currently selected Scene',
                        colorHex: _customTheme.highlightColorHex,
                        onSave: (colorHex) => setState(
                            () => _customTheme.highlightColorHex = colorHex),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32.0),
                      child: ColorRow(
                        colorTitle: 'Background Color',
                        colorDescription:
                            'Typical background color where no UI element is shown',
                        colorHex: _customTheme.backgroundColorHex,
                        onSave: (colorHex) => setState(
                            () => _customTheme.backgroundColorHex = colorHex),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
