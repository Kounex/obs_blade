import 'package:hive/hive.dart';

import '../type_ids.dart';

part 'dashboard_element.g.dart';

@HiveType(typeId: TypeIDs.DashboardElement)
enum DashboardElement {
  @HiveField(0)
  ExposedProfile,

  @HiveField(1)
  ExposedControls,

  @HiveField(2)
  SceneButtons,

  @HiveField(3)
  StudioModeTransition,

  @HiveField(4)
  StudioModeConfig,

  @HiveField(5)
  ScenePreview,

  @HiveField(6)
  SceneItems,

  @HiveField(7)
  SceneItemsAudio,

  @HiveField(8)
  StreamChat,

  @HiveField(9)
  OBSStats;

  String get name => switch (this) {
        DashboardElement.ExposedProfile => 'Profiles',
        DashboardElement.ExposedControls => 'Controls',
        DashboardElement.SceneButtons => 'Scene Buttons',
        DashboardElement.StudioModeTransition => 'Studio Mode Transition',
        DashboardElement.StudioModeConfig => 'Studio Mode Config',
        DashboardElement.ScenePreview => 'Scene Preview',
        DashboardElement.SceneItems => 'Scene Items',
        DashboardElement.SceneItemsAudio => 'Scene Audio',
        DashboardElement.StreamChat => 'Chat',
        DashboardElement.OBSStats => 'Stats',
      };
}
