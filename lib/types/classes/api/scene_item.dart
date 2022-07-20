class SceneItemTransform {
  int? alignment;
  int? boundsAlignment;
  double? boundsHeight;
  String? boundsType;
  double? boundsWidth;
  int? cropBottom;
  int? cropLeft;
  int? cropRight;
  int? cropTop;
  double? height;
  double? positionX;
  double? positionY;
  double? rotation;
  double? scaleX;
  double? scaleY;
  double? sourceHeight;
  double? sourceWidth;
  double? width;

  SceneItemTransform({
    required this.alignment,
    required this.boundsAlignment,
    required this.boundsHeight,
    required this.boundsType,
    required this.boundsWidth,
    required this.cropBottom,
    required this.cropLeft,
    required this.cropRight,
    required this.cropTop,
    required this.height,
    required this.positionX,
    required this.positionY,
    required this.rotation,
    required this.scaleX,
    required this.scaleY,
    required this.sourceHeight,
    required this.sourceWidth,
    required this.width,
  });

  static SceneItemTransform fromJSON(Map<String, dynamic> json) {
    return SceneItemTransform(
      alignment: json['alignment'],
      boundsAlignment: json['boundsAlignment'],
      boundsHeight: json['boundsHeight'],
      boundsType: json['boundsType'],
      boundsWidth: json['boundsWidth'],
      cropBottom: json['cropBottom'],
      cropLeft: json['cropLeft'],
      cropRight: json['cropRight'],
      cropTop: json['cropTop'],
      height: json['height'],
      positionX: json['positionX'],
      positionY: json['positionY'],
      rotation: json['rotation'],
      scaleX: json['scaleX'],
      scaleY: json['scaleY'],
      sourceHeight: json['sourceHeight'],
      sourceWidth: json['sourceWidth'],
      width: json['width'],
    );
  }
}

class SceneItem {
  String? inputKind;
  bool? isGroup;
  String? sceneItemBlendMode;
  bool? sceneItemEnabled;
  int? sceneItemId;
  int? sceneItemIndex;
  bool? sceneItemLocked;
  SceneItemTransform? sceneItemTransform;
  String? sourceName;
  String? sourceType;

  /// OPTIONAL - Name of the item's parent (if this item belongs to a group)
  String? parentGroupName;

  /// OPTIONAL - List of children (if this item is a group)
  List<SceneItem>? groupChildren;

  /// CUSTOM - added myself to handle stuff internally

  /// Indicate whether we want to display the children of this group
  /// (if this [SceneItem] is a group)
  bool displayGroup = false;

  SceneItem({
    required this.inputKind,
    required this.isGroup,
    required this.sceneItemBlendMode,
    required this.sceneItemEnabled,
    required this.sceneItemId,
    required this.sceneItemIndex,
    required this.sceneItemLocked,
    required this.sceneItemTransform,
    required this.sourceName,
    required this.sourceType,
  });

  static SceneItem fromJSON(Map<String, dynamic> json) {
    return SceneItem(
      inputKind: json['inputKind'],
      isGroup: json['isGroup'],
      sceneItemBlendMode: json['sceneItemBlendMode'],
      sceneItemEnabled: json['sceneItemEnabled'],
      sceneItemId: json['sceneItemId'],
      sceneItemIndex: json['sceneItemIndex'],
      sceneItemLocked: json['sceneItemLocked'],
      sceneItemTransform: json['sceneItemTransform'] != null
          ? SceneItemTransform.fromJSON(json['sceneItemTransform'])
          : null,
      sourceName: json['sourceName'],
      sourceType: json['sourceType'],
    );
  }
}
