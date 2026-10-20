import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:obs_blade/utils/kick/kick_channel_service.dart';
import 'package:obs_blade/utils/renewing_http_client.dart';

/// The Pusher app a Kick chat rides: key + cluster
class KickPusherApp {
  final String key;
  final String cluster;

  const KickPusherApp(this.key, this.cluster);

  /// What `web.kick.com` answered on 2026-10-20 (every channel probed)
  static const KickPusherApp fallback = KickPusherApp(
    '34bf7a0ff419a2a775b9',
    'us2',
  );

  @override
  bool operator ==(Object other) =>
      other is KickPusherApp &&
      other.key == this.key &&
      other.cluster == this.cluster;

  @override
  int get hashCode => Object.hash(this.key, this.cluster);
}

/// Asks Kick which Pusher app a channel's chat is on - what kick.com's
/// own page asks before it connects (its JS bundle, read 2026-10-20).
/// Kick moved the chat to a new app key that day: the key compiled in
/// since 2023 answered `pusher:error` 4001 "App key ... not in this
/// cluster", and the chat sat in "Reconnecting...".
///
/// `POST web.kick.com/api/v1/realtime/channels/{channelId}/chat/connection`,
/// no auth. Offered Pusher and Centrifugo, Kick picks Centrifugo; offered
/// Pusher alone it still names its Pusher app (probed live: 187 chat
/// events in 15 s on the new key, same `chatrooms.{id}.v2` channel and
/// event names).
class KickRealtimeConfigService {
  final http.Client _client;

  /// Kick's page sends its own client id; any id is answered
  final String _clientId;

  KickRealtimeConfigService({http.Client? client})
    : _client = client ?? RenewingHttpClient(),
      _clientId = List.generate(
        16,
        (_) => Random.secure().nextInt(16).toRadixString(16),
      ).join();

  /// Null: Kick named no Pusher app
  Future<KickPusherApp?> pusherApp(int channelId) async {
    final response = await this._client.post(
      Uri.parse(
        'https://web.kick.com/api/v1/realtime/channels/$channelId/chat/connection',
      ),
      headers: const {
        'User-Agent': kKickUserAgent,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'client': {'id': this._clientId, 'type': 'web'},
        'capabilities': {
          'accepted_providers': [
            {'provider': 'pusher'},
          ],
        },
      }),
    );
    if (response.statusCode != 200) {
      throw KickApiException(
        'Kick realtime config: HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    final body = json.decode(response.body);
    final data = body is Map ? body['data'] : null;
    final connections = data is Map ? data['connections'] : null;
    if (connections is! List) return null;
    for (final connection in connections) {
      if (connection is! Map || connection['provider'] != 'pusher') continue;
      final credentials = connection['credentials'];
      if (credentials is! Map) continue;
      final key = credentials['app_key'];
      final cluster = credentials['cluster'];
      if (key is String &&
          key.isNotEmpty &&
          cluster is String &&
          cluster.isNotEmpty) {
        return KickPusherApp(key, cluster);
      }
    }
    return null;
  }
}
