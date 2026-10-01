/// An OBS canvas (obs-websocket 5.7+ `GetCanvasList` entry): a separate
/// output with its own resolution and scenes - e.g. a vertical canvas from
/// Aitum Vertical next to the main one.
class ObsCanvas {
  final String uuid;
  final String name;

  /// The main canvas (the regular OBS program output)
  final bool isMain;

  /// Base (canvas) resolution - null when OBS has no video info for it
  final int? baseWidth;
  final int? baseHeight;

  const ObsCanvas({
    required this.uuid,
    required this.name,
    required this.isMain,
    this.baseWidth,
    this.baseHeight,
  });

  factory ObsCanvas.fromJson(Map<String, dynamic> json) {
    final flags = json['canvasFlags'] as Map<String, dynamic>? ?? const {};
    final video =
        json['canvasVideoSettings'] as Map<String, dynamic>? ?? const {};
    return ObsCanvas(
      uuid: json['canvasUuid'] as String,
      name: json['canvasName'] as String? ?? '',
      isMain: flags['MAIN'] == true,
      baseWidth: (video['baseWidth'] as num?)?.toInt(),
      baseHeight: (video['baseHeight'] as num?)?.toInt(),
    );
  }

  /// Width / height of the base resolution, null when unknown
  double? get aspectRatio =>
      this.baseWidth != null &&
          this.baseHeight != null &&
          this.baseWidth! > 0 &&
          this.baseHeight! > 0
      ? this.baseWidth! / this.baseHeight!
      : null;

  /// e.g. "1080×1920", null when the resolution is unknown
  String? get resolutionLabel =>
      this.baseWidth != null && this.baseHeight != null
      ? '${this.baseWidth}×${this.baseHeight}'
      : null;
}

/// A scene of a (non-main) canvas - identified by UUID since scene names
/// can repeat across canvases
class CanvasScene {
  final String uuid;
  final String name;

  const CanvasScene({required this.uuid, required this.name});

  factory CanvasScene.fromJson(Map<String, dynamic> json) => CanvasScene(
    uuid: json['sceneUuid'] as String,
    name: json['sceneName'] as String? ?? '',
  );
}
