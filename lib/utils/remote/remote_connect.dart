import 'dart:convert';
import 'dart:io';

import 'package:get_it/get_it.dart';

import '../../models/connection.dart';
import '../../stores/pro_store.dart';
import '../../types/classes/connection_attempt_result.dart';
import '../connectivity_state.dart';
import '../general_helper.dart';
import '../../types/enums/remote_reach.dart';
import '../../types/enums/web_socket_codes/web_socket_close_code.dart';
import 'noise_ik.dart';
import 'remote_relay_client.dart';

/// One way of reaching OBS for a connect attempt.
enum ConnectLeg { lan, remote }

/// How long the LAN gets when the relay comes next ("smart" fallback,
/// decided with the user 2026-11-07): long enough for a LAN host to
/// answer, short enough not to stall someone on 5G behind the home Wi-Fi.
const Duration kLanProbeTimeout = Duration(seconds: 3);

/// The legs of a connect, in order.
///
/// - No pairing, or no Pro: the saved host only (as before remote access).
/// - Paired and Pro, off the local network (mobile data) with a LAN-only
///   host: the relay only.
/// - Otherwise (on Wi-Fi, or a host reachable from anywhere - a domain,
///   a public IP, a Tailscale address): the saved host briefly, then the
///   relay. Setups that already reached OBS remotely keep working.
List<ConnectLeg> connectPlan({
  required bool hasRemote,
  required bool isPro,
  required bool onLocalNetwork,
  bool hostIsLanOnly = true,
}) {
  if (!hasRemote || !isPro) return const [ConnectLeg.lan];
  if (!onLocalNetwork && hostIsLanOnly) return const [ConnectLeg.remote];
  return const [ConnectLeg.lan, ConnectLeg.remote];
}

/// A host only reachable inside a home network: RFC 1918, link-local,
/// loopback or mDNS `.local`. Domains, public IPs and CGNAT / Tailscale
/// (100.64/10) addresses are not.
bool hostIsLanOnly(String rawHost) {
  String host = rawHost.trim().toLowerCase();
  if (host.contains('://')) host = Uri.tryParse(host)?.host ?? host;
  if (host == 'localhost' || host.endsWith('.local')) return true;
  final InternetAddress? address = InternetAddress.tryParse(host);
  if (address == null) return false; // a domain name
  if (address.isLoopback || address.isLinkLocal) return true;
  if (address.type == InternetAddressType.IPv4) {
    final List<int> b = address.rawAddress;
    return b[0] == 10 ||
        (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||
        (b[0] == 192 && b[1] == 168);
  }
  // IPv6 unique local (fc00::/7)
  return (address.rawAddress[0] & 0xfe) == 0xfc;
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

    /// "Off the local network" only when the device is on mobile data for
    /// sure - an unclear answer (none, vpn, other) tries the LAN first
    onLocalNetwork: () async {
      final results = await settledConnectivity();
      GeneralHelper.advLog(
        'Remote access: network ${results.map((r) => r.name).join('+')}',
        includeInLogs: true,
      );
      return !mobileDataOnly(results);
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
    return connectPlan(
      hasRemote: true,
      isPro: true,
      onLocalNetwork: local,
      hostIsLanOnly: hostIsLanOnly(connection.host),
    );
  }

  /// The relay's view of a paired [connection] for the saved card - null
  /// when it isn't paired, without Pro, or the relay doesn't answer within
  /// [timeout]. A revoked pairing (401) is forgotten, as on connect.
  Future<RemoteReach?> reach(
    Connection connection, {
    Duration timeout = const Duration(seconds: 6),
  }) async {
    if (!connection.hasRemote || !this.isPro()) return null;
    try {
      return RemoteReach.of(
        await this.relay
            .bridgeInfo(connection.relayBridgeId!, connection.relayAppToken!)
            .timeout(timeout),
      );
    } on RemoteRelayException catch (e) {
      if (e.isUnpaired) {
        connection.clearRemote();
        if (connection.isInBox) await connection.save();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// URL, headers and end-to-end keys of the relay socket for a paired
  /// [connection].
  Future<RemoteSocketTarget> socketTarget(Connection connection) async {
    final appUserId = await this.appUserId();
    return RemoteSocketTarget(
      uri: this.relay.appSocketUri(connection.relayBridgeId!),
      headers: {
        'Authorization': 'Bearer ${connection.relayAppToken}',
        if (appUserId != null && appUserId.isNotEmpty)
          'X-RC-App-User-Id': appUserId,
      },
      appKey: await NoiseKeyPair.fromPrivate(
        base64Decode(connection.relayAppKey!),
      ),
      bridgeKey: base64Decode(connection.relayBridgeKey!),
    );
  }
}

class RemoteSocketTarget {
  final Uri uri;
  final Map<String, String> headers;

  /// This pairing's key and the bridge's: the session is end-to-end
  /// encrypted between them ([RemoteE2eChannel])
  final NoiseKeyPair appKey;
  final List<int> bridgeKey;

  const RemoteSocketTarget({
    required this.uri,
    required this.headers,
    required this.appKey,
    required this.bridgeKey,
  });
}
