import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/utils/general_helper.dart';

import '../../../../../models/custom_theme.dart';
import '../../../../../shared/general/base/base_button.dart';
import '../../../../../shared/general/cupertino_dropdown.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../utils/built_in_themes.dart';
import '../../../widgets/action_block.dart/light_divider.dart';

class ThemeLoader extends StatefulWidget {
  final void Function(CustomTheme theme)? onLoadTheme;

  const ThemeLoader({
    Key? key,
    this.onLoadTheme,
  }) : super(key: key);

  @override
  _ThemeLoaderState createState() => _ThemeLoaderState();
}

class _ThemeLoaderState extends State<ThemeLoader> {
  late CustomTheme _selectedTheme;
  late List<CustomTheme> _availableThemes;

  @override
  void initState() {
    super.initState();

    _availableThemes = [
      ...BuiltInThemes.themes,
      ...Hive.box<CustomTheme>(HiveKeys.CustomTheme.name).values
    ];
    CustomTheme base = CustomTheme.basic();
    base.name = 'OBS Blade Base';

    _availableThemes.add(base);
    _availableThemes
        .sort((theme1, theme2) => theme1.name!.compareTo(theme2.name!));

    _selectedTheme = base;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LightDivider(),
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 192.0,
              child: CupertinoDropdown<CustomTheme>(
                value: _selectedTheme,
                items: _availableThemes
                    .map(
                      (theme) => DropdownMenuItem<CustomTheme>(
                        value: theme,
                        child: Text(theme.name ?? 'OBS Blade Base'),
                      ),
                    )
                    .toList(),
                selectedItemBuilder: (_) => _availableThemes
                    .map(
                      (theme) => Text(
                        theme.name ?? 'OBS Blade Base',
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                    .toList(),
                onChanged: (theme) => setState(() => _selectedTheme = theme!),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 4.0),
              child: BaseButton(
                text: 'Load',
                onPressed: () {
                  GeneralHelper.advLog(_selectedTheme.cardColorHex);
                  this.widget.onLoadTheme?.call(_selectedTheme);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        LightDivider(),
      ],
    );
  }
}
