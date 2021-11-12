import 'package:hive/hive.dart';
import 'package:obs_blade/models/type_ids.dart';

part 'hidden_scene.g.dart';

@HiveType(typeId: TypeIDs.HiddenScene)
class HiddenScene extends HiveObject {
  /// Name of the scene (unfortunately OBS WebSocket does not expose something
  /// like an ID for scene, just the name) which should be hidden
  @HiveField(0)
  String sceneName;

  /// Since the scene name itself is not a good enough indicator (different OBS
  /// instances could share the same scene name like "Main"), a good indicator
  /// (if present since it's not mandatory) would be the connection name because
  /// it has to be unique
  @HiveField(1)
  String? connectionName;

  /// Used as a backup if no connection name is present because it's better than
  /// only using the name but might cause false behaviour when the ip address
  /// changes for whatever reasons
  @HiveField(2)
  String ipAddress;

  HiddenScene(this.sceneName, this.connectionName, this.ipAddress);
}
