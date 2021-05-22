class OutputFlags {
  ///Raw flags value
  int rawValue;

  ///Output uses audio
  bool audio;

  ///Output uses video
  bool video;

  ///Output is encoded
  bool encoded;

  ///Output uses several audio tracks
  bool multiTrack;

  ///Output uses a service
  bool service;

  OutputFlags({
    required this.rawValue,
    required this.audio,
    required this.video,
    required this.encoded,
    required this.multiTrack,
    required this.service,
  });

  static OutputFlags fromJSON(Map<String, dynamic> json) => OutputFlags(
        rawValue: json['rawValue'],
        audio: json['audio'],
        video: json['video'],
        encoded: json['encoded'],
        multiTrack: json['multiTrack'],
        service: json['service'],
      );
}
