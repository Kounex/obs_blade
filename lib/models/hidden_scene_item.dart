import 'package:hive/hive.dart';
import 'package:obs_blade/models/type_ids.dart';
import 'package:obs_blade/types/classes/api/scene_item.dart';

import 'enums/scene_item_type.dart';

part 'hidden_scene_item.g.dart';

@HiveType(typeId: TypeIDs.HiddenSceneItem)
class HiddenSceneItem extends HiveObject {
  /// Name of the scene (unfortunately OBS WebSocket does not expose something
  /// like an ID for scene, just the name) from where this item should be hidden from.
  @HiveField(0)
  String sceneName;

  /// Indicates whether the user wanted to hide an item from the audio panel
  /// or the scene item panel, since one scene item could be in both lists
  @HiveField(1)
  SceneItemType type;

  /// The id of the audio scene item to hide - will be used as the main indicator
  /// of which item to hide
  @HiveField(2)
  int? id;

  /// The name of the audio "scene item". Global audio items like Mic or special
  /// Desktop occasions are not bound to a scene but available everywhere, hence
  /// the name global, they dont have an id since the id is also bound to a scene.
  /// In cases where one entry does not oppose an id, the name will be used instead.
  /// This means once a global audio item gets renamed, its hidden state gets lost
  @HiveField(3)
  String name;

  /// Indicates what kind of item this is. Primarly used (currently) to find out
  /// if this hidden item is a group container, meaning children should be hidden
  /// as well (will be checked by mathing this name and the scene items parentName
  /// property while also checking whether this item is from type 'group')
  /// [IMPORTANT]: Is new since production, might be null!
  @HiveField(4)
  String? sourceType;

  HiddenSceneItem(
      this.sceneName, this.type, this.id, this.name, this.sourceType);

  bool isSceneItem(String sceneName, SceneItemType type, SceneItem sceneItem) =>
      this.sceneName == sceneName &&
      this.type == type &&
      this.id == sceneItem.id &&
      this.name == sceneItem.name &&
      this.sourceType == sceneItem.type;
}
