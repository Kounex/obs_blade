import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../../models/custom_theme.dart';
import '../../../../../shared/general/cupertino_dropdown.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../utils/built_in_themes.dart';
import '../../../widgets/action_block.dart/light_divider.dart';
import 'theme_row.dart';

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
        const LightDivider(),
        const SizedBox(height: 12.0),
        ThemeRow(
          useDivider: false,
          titleWidget: SizedBox(
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
          description:
              'Load the configuration from another theme if you want to work with existing color settings',
          buttonText: 'Load',
          onButtonPressed: () => this.widget.onLoadTheme?.call(_selectedTheme),
        ),
        const SizedBox(height: 12.0),
        const LightDivider(),
      ],
    );
  }
}
