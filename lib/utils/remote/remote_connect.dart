import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

import '../../models/connection.dart';
import '../../stores/pro_store.dart';
import '../../types/classes/connection_attempt_result.dart';
import '../../types/enums/web_socket_codes/web_socket_close_code.dart';
import 'remote_relay_client.dart';

/// One way of reaching OBS for a connect attempt.
enum ConnectLeg { lan, remote }

/// How long the LAN gets when the relay comes next ("smart" fallback,
/// decided with the user 2026-11-07): long enough for a LAN host to
/// answer, short enough not to stall someone on 5G behind the home Wi-Fi.
const Duration kLanProbeTimeout = Duration(seconds: 3);

/// The legs of a connect, in order.
///
/// - No pairing, or no Pro: the LAN only (as before remote access existed).
/// - Paired and Pro, off the local network (mobile data): the relay only.
/// - Paired and Pro on Wi-Fi / Ethernet: the LAN briefly, then the relay.
List<ConnectLeg> connectPlan({
  required bool hasRemote,
  required bool isPro,
  required bool onLocalNetwork,
}) {
  if (!hasRemote || !isPro) return const [ConnectLeg.lan];
  if (!onLocalNetwork) return const [ConnectLeg.remote];
  return const [ConnectLeg.lan, ConnectLeg.remote];
}

/// A LAN attempt that never reached OBS (no socket, nothing answered) -
/// the only case that moves on to the relay. OBS answering with a wrong
/// password or a protocol error is the user's real answer and stays.
bool lanUnreachable(ConnectionAttemptResult? result) =>
    result != null &&
    result.stage == ConnectionStage.connecting &&
    (result.closeCode == WebSocketCloseCode.HandshakeTimeout ||
        result.closeCode == WebSocketCloseCode.UnknownReason);

/// What a remote connect needs from the rest of the app - injectable for
/// tests (`NetworkStore(remote: ...)`).
class RemoteConnectEnvironment {
  final bool Function() isPro;
  final Future<bool> Function() onLocalNetwork;
  final Future<String?> Function() appUserId;
  final RemoteRelayClient relay;

  RemoteConnectEnvironment({
    required this.isPro,
    required this.onLocalNetwork,
    required this.appUserId,
    RemoteRelayClient? relay,
  }) : relay = relay ?? RemoteRelayClient();

  factory RemoteConnectEnvironment.live() => RemoteConnectEnvironment(
    isPro: () =>
        GetIt.instance.isRegistered<ProStore>() &&
        GetIt.instance<ProStore>().isPro,
    onLocalNetwork: () async {
      final results = await Connectivity().checkConnectivity();
      return results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);
    },
    appUserId: () async => GetIt.instance.isRegistered<ProStore>()
        ? GetIt.instance<ProStore>().appUserId()
        : null,
  );

  Future<List<ConnectLeg>> planFor(Connection connection) async {
    if (!connection.hasRemote || !this.isPro()) return const [ConnectLeg.lan];
    bool local;
    try {
      local = await this.onLocalNetwork();
    } catch (_) {
      local = true; // unknown: try both
    }
    return connectPlan(hasRemote: true, isPro: true, onLocalNetwork: local);
  }

  /// URL + headers of the relay socket for a paired [connection].
  Future<RemoteSocketTarget> socketTarget(Connection connection) async {
    final appUserId = await this.appUserId();
    return RemoteSocketTarget(
      uri: this.relay.appSocketUri(connection.relayBridgeId!),
      headers: {
        'Authorization': 'Bearer ${connection.relayAppToken}',
        if (appUserId != null && appUserId.isNotEmpty)
          'X-RC-App-User-Id': appUserId,
      },
    );
  }
}

class RemoteSocketTarget {
  final Uri uri;
  final Map<String, String> headers;

  const RemoteSocketTarget({required this.uri, required this.headers});
}
