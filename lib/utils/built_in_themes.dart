import '../models/custom_theme.dart';

class BuiltInThemes {
  /// The curated lineup, tuned to the token grammar (token-delta §1 rule 8):
  /// **accent** = brand / selection / filled CTAs, **highlight** = control
  /// states + links. Dark presets use control colors that stay readable on
  /// near-black (iOS dark variants); light presets use the light variants.
  /// UUIDs + creation stamps are pinned - users may have a preset active
  /// (persisted as `ActiveCustomThemeUUID`).
  static Iterable<CustomTheme> get themes => [
    CustomTheme(
      'Pure Indigo',
      'Might remind you of a platform... pure coincidence, I guess',
      false,
      '212121',
      '212121',
      '212121',
      '6f29d6',
      'a78bfa',
      '131313',
      null,
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
      'e4e4e4',
      '0284c7',
      '007aff',
      'e4e4e4',
      null,
      true,
      '4c6b99aa-4d4d-45a6-ba25-53dd181c36cd',
      1600249329020,
    ),
    CustomTheme(
      'Red Underdog',
      'Not every streamer uses the big purple platform - this is for you!',
      false,
      '212121',
      '212121',
      '212121',
      'cc0000',
      '0a84ff',
      '181818',
      null,
      false,
      '0c85f35d-be62-485c-9169-6a00526101c0',
      1600249329020,
    ),
    CustomTheme(
      'Snowstorm',
      'An eye friendly light theme in icy colors.',
      false,
      'dae9ff',
      'cce0fc',
      'cce0fc',
      '4a6fd1',
      '007aff',
      'ebeff5',
      null,
      true,
      'd5ee18fd-9078-4342-94d8-b8239689b84a',
      1600249329020,
    ),
  ];
}
