import 'package:obs_blade/models/custom_theme.dart';
import 'package:obs_blade/utils/styling_helper.dart';
import '../types/extensions/color.dart';

class BuiltInThemes {
  static Iterable<CustomTheme> get themes => [
        CustomTheme(
          'Pure Indigo',
          'Might remind you of a platform, pure coincidence... i guess',
          false,
          '050505',
          '050505',
          '050505',
          '6700ff',
          '6700ff',
          '171717',
          'ffffff',
          false,
          'a3d48049-f41d-45ad-beca-c9bf76835ef1',
          1600249329020,
        ),
        CustomTheme(
          'Bright Star',
          'For those who prefer getting their eyes fried',
          false,
          'ffffff',
          'e4e4e4',
          'f0f0f0',
          'a6d1ff',
          StylingHelper.highlight_color.toHex(),
          'e4e4e4',
          'ffffff',
          true,
          '4c6b99aa-4d4d-45a6-ba25-53dd181c36cd',
          1600249329020,
        ),
      ];
}
