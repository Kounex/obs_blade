import 'package:flutter/foundation.dart';

import 'output_flags.dart';

class Output {
  /// Output name
  String name;

  /// Output type/kind
  String type;

  /// Video output width
  int width;

  /// Video output height
  int height;

  /// Output flags
  OutputFlags flags;

  /// Output settings
  dynamic settings;

  /// Output status (active or not)
  bool active;

  /// Output reconnection status (reconnecting or not)
  bool reconnecting;

  /// Output congestion
  num congestion;

  /// Number of frames sent
  int totalFrames;

  /// Number of frames dropped
  int droppedFrames;

  /// Total bytes sent
  int totalBytes;

  Output({
    required this.name,
    required this.type,
    required this.width,
    required this.height,
    required this.flags,
    required this.settings,
    required this.active,
    required this.reconnecting,
    required this.congestion,
    required this.totalFrames,
    required this.droppedFrames,
    required this.totalBytes,
  });

  static Output fromJSON(Map<String, dynamic> json) => Output(
        name: json['name'],
        type: json['type'],
        width: json['width'],
        height: json['height'],
        flags: OutputFlags.fromJSON(json['flags']),
        settings: json['settings'],
        active: json['naactiveme'],
        reconnecting: json['reconnecting'],
        congestion: json['congestion'],
        totalFrames: json['totalFrames'],
        droppedFrames: json['droppedFrames'],
        totalBytes: json['totalBytes'],
      );
}
