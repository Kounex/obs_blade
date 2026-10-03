import '../../types/classes/activity/activity_event.dart';

/// Where OBS streams to, from a `GetStreamServiceSettings` answer - the
/// feed's "you're live on YouTube but it isn't set up" hint.
///
/// `rtmp_common` names the service (obs-studio
/// `plugins/rtmp-services/data/services.json`: `Twitch`, `YouTube - RTMPS`,
/// `YouTube - HLS`); `rtmp_custom` only has the server URL. Kick has no
/// preset (a custom Amazon IVS server shared with other services), so it
/// isn't recognized. Multistream plugins send elsewhere unseen - null.
///
/// The settings also carry the stream **key**: read the two fields, never
/// log or keep the answer.
ActivityPlatform? obsStreamPlatform(Map<String, dynamic>? response) {
  if (response == null) return null;
  final settings = response['streamServiceSettings'];
  if (settings is! Map) return null;
  final type = response['streamServiceType'];
  final service = '${settings['service'] ?? ''}'.toLowerCase();
  final server = '${settings['server'] ?? ''}'.toLowerCase();
  if (type == 'rtmp_common') {
    if (service.startsWith('youtube')) return ActivityPlatform.youtube;
    if (service.startsWith('twitch')) return ActivityPlatform.twitch;
  }
  final host = Uri.tryParse(server)?.host ?? '';
  if (host.endsWith('youtube.com')) return ActivityPlatform.youtube;
  if (host.endsWith('twitch.tv')) return ActivityPlatform.twitch;
  return null;
}
