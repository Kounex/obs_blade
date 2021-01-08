import 'package:hive/hive.dart';

part 'scene_item_type.g.dart';

@HiveType(typeId: 0)
enum SceneItemType {
  /// Source related to items in the "Sources" list of OBS.
  /// Basically the "actual" scene items
  @HiveField(0)
  Source,

  /// Items which result from entries in the "Sources" list but
  /// have a designated entry in the "Audio Mixer" list of OBS
  @HiveField(1)
  Audio,
}
