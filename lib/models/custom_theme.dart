import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../types/extensions/color.dart';
import '../utils/styling_helper.dart';

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
  String cardColorHex;

  @HiveField(5)
  String appBarColorHex;

  @HiveField(6)
  String tabBarColorHex;

  @HiveField(7)
  String accentColorHex;

  @HiveField(8)
  String highlightColorHex;

  @HiveField(9)
  String backgroundColorHex;

  @HiveField(10)
  String textColorHex;

  @HiveField(11)
  bool useLightBrightness;

  @HiveField(12)
  int dateCreatedMS;

  @HiveField(13)
  int dateUpdatedMS;

  CustomTheme(
      this.name,
      this.description,
      this.starred,
      this.cardColorHex,
      this.appBarColorHex,
      this.tabBarColorHex,
      this.accentColorHex,
      this.highlightColorHex,
      this.backgroundColorHex,
      this.textColorHex,
      this.useLightBrightness,
      [this.uuid,
      this.dateCreatedMS]) {
    this.uuid = uuid ?? Uuid().v4();
    this.dateCreatedMS = dateCreatedMS ?? DateTime.now().millisecondsSinceEpoch;
  }

  CustomTheme.basic() {
    this.uuid = Uuid().v4();
    this.dateCreatedMS = DateTime.now().millisecondsSinceEpoch;
    this.cardColorHex = StylingHelper.primary_color.toHex();
    this.appBarColorHex = StylingHelper.primary_color.toHex();
    this.tabBarColorHex = StylingHelper.primary_color.toHex();
    this.accentColorHex = StylingHelper.accent_color.toHex();
    this.highlightColorHex = StylingHelper.highlight_color.toHex();
    this.backgroundColorHex = StylingHelper.background_color.toHex();
    this.useLightBrightness = false;
  }
}
