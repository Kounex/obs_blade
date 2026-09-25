import 'base.dart';

/// Gets the status of a media input.
class GetMediaInputStatusResponse extends BaseResponse {
  GetMediaInputStatusResponse(super.json);

  /// OBS_MEDIA_STATE_* (PLAYING / PAUSED / STOPPED / ENDED / ...)
  String get mediaState => this.json['mediaState'];

  /// Total duration in milliseconds, null if not playing
  int? get mediaDuration => (this.json['mediaDuration'] as num?)?.toInt();

  /// Position in milliseconds, null if not playing
  int? get mediaCursor => (this.json['mediaCursor'] as num?)?.toInt();
}
