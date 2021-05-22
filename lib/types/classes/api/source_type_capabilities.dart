class SourceTypeCapabilities {
  /// True if source of this type provide frames asynchronously
  bool isAsync;

  /// True if sources of this type provide video
  bool hasVideo;

  /// True if sources of this type provide audio
  bool hasAudio;

  /// True if interaction with this sources of this type is possible
  bool canInteract;

  /// True if sources of this type composite one or more sub-sources
  bool isComposite;

  /// True if sources of this type should not be fully duplicated
  bool doNotDuplicate;

  /// True if sources of this type may cause a feedback loop if it's audio is monitored and shouldn't be
  bool doNotSelfMonitor;

  SourceTypeCapabilities({
    required this.isAsync,
    required this.hasVideo,
    required this.hasAudio,
    required this.canInteract,
    required this.isComposite,
    required this.doNotDuplicate,
    required this.doNotSelfMonitor,
  });

  static SourceTypeCapabilities fromJSON(Map<String, dynamic> json) =>
      SourceTypeCapabilities(
        isAsync: json['isAsync'],
        hasVideo: json['hasVideo'],
        hasAudio: json['hasAudio'],
        canInteract: json['canInteract'],
        isComposite: json['isComposite'],
        doNotDuplicate: json['doNotDuplicate'],
        doNotSelfMonitor: json['doNotSelfMonitor'],
      );
}
