import 'package:hive/hive.dart';
import 'package:obs_blade/utils/styling_helper.dart';
import 'package:uuid/uuid.dart';
import '../types/extensions/color.dart';

part 'custom_theme.g.dart';

@HiveType(typeId: 2)
class CustomTheme extends HiveObject {
  @HiveField(0)
  String uuid;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  bool starred;

  @HiveField(4)
  String primaryColorHex;

  @HiveField(5)
  String accentColorHex;

  @HiveField(6)
  String highlightColorHex;

  @HiveField(7)
  String backgroundColorHex;

  @HiveField(8)
  String textColorHex;

  @HiveField(9)
  bool useLightBrightness;

  CustomTheme(
      this.name,
      this.description,
      this.starred,
      this.primaryColorHex,
      this.accentColorHex,
      this.highlightColorHex,
      this.backgroundColorHex,
      this.textColorHex,
      this.useLightBrightness) {
    this.uuid = Uuid().v4();
  }

  CustomTheme.basic() {
    this.uuid = Uuid().v4();
    this.primaryColorHex = StylingHelper.PRIMARY_COLOR.toHex();
    this.accentColorHex = StylingHelper.ACCENT_COLOR.toHex();
    this.highlightColorHex = StylingHelper.HIGHLIGHT_COLOR.toHex();
    this.backgroundColorHex = StylingHelper.BACKGROUND_COLOR.toHex();
    this.useLightBrightness = false;
  }
}
