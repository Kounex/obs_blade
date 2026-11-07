import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';

import '../../models/connection.dart';
import '../../models/enums/log_level.dart';
import '../../types/enums/request_type.dart';
import '../../utils/general_helper.dart';
import '../../utils/network_helper.dart';
import '../../utils/remote/remote_relay_client.dart';
import '../pro_store.dart';
import '../shared/network.dart';

part 'remote_access.g.dart';

enum RemotePairingPhase { idle, starting, waitingForBridge, paired, failed }

enum RemotePairingFailure {
  /// No RevenueCat account id to prove Pro with
  noAccount,
  proRequired,
  verifyUnavailable,
  rateLimited,
  network,

  /// The code expired without a bridge redeeming it: nothing installed,
  /// or OBS Blade Remote switched off on the PC
  noBridge,
}

/// Hands the pairing code to the bridge through OBS. Returns true when the
/// plugin acknowledged it (vendor request) - then it isn't sent again;
/// false when it went out as a CustomEvent (the standalone), which is
/// fire-and-forget and gets repeated.
typedef RemoteCodeSender = Future<bool> Function(String code);

/// Remote access (Pro) for the dashboard's sheet: pairing this device with
/// the bridge next to OBS while connected on the LAN, and the paired
/// bridge's state / devices. Protocol: `tool/remote_relay/README.md`.
class RemoteAccessStore = _RemoteAccessStore with _$RemoteAccessStore;

abstract class _RemoteAccessStore with Store {
  final RemoteRelayClient _relay;
  final Future<String?> Function() _appUserId;
  final RemoteCodeSender _sendCode;
  final Duration _pollInterval;
  final Duration _resendInterval;

  _RemoteAccessStore({
    RemoteRelayClient? relay,
    Future<String?> Function()? appUserId,
    RemoteCodeSender? sendCode,
    Duration pollInterval = const Duration(seconds: 2),
    Duration resendInterval = const Duration(seconds: 2),
  }) : _relay = relay ?? RemoteRelayClient(),
       _appUserId = appUserId ?? (() => GetIt.instance<ProStore>().appUserId()),
       _sendCode = sendCode ?? sendPairCodeThroughObs,
       _pollInterval = pollInterval,
       _resendInterval = resendInterval;

  @observable
  RemotePairingPhase phase = RemotePairingPhase.idle;

  @observable
  RemotePairingFailure? failure;

  /// Shown while waiting, so the user can match it with the PC's log
  @observable
  String? code;

  @observable
  RemoteBridgeInfo? info;

  @observable
  bool infoLoading = false;

  @observable
  RemoteRelayException? infoError;

  /// Bumped by [cancel] / a new [pair]: a running loop of an older run stops
  int _generation = 0;

  @action
  void cancel() {
    _generation++;
    if (this.phase == RemotePairingPhase.starting ||
        this.phase == RemotePairingPhase.waitingForBridge) {
      this.phase = RemotePairingPhase.idle;
    }
    this.code = null;
  }

  /// Pairs [connection] (a saved one) with the bridge next to the OBS this
  /// device is connected to right now.
  @action
  Future<void> pair(
    Connection connection, {
    required String deviceName,
    required String platform,
  }) async {
    final int generation = ++_generation;
    this.phase = RemotePairingPhase.starting;
    this.failure = null;
    this.code = null;

    final String? appUserId = await _appUserId();
    if (generation != _generation) return;
    if (appUserId == null || appUserId.isEmpty) {
      return _fail(RemotePairingFailure.noAccount);
    }

    final RemotePairingTicket ticket;
    try {
      ticket = await _relay.createPairing(
        appUserId: appUserId,
        deviceName: deviceName,
        platform: platform,
      );
    } on RemoteRelayException catch (e) {
      if (generation != _generation) return;
      GeneralHelper.logFailure('Remote access: pairing refused', e);
      return _fail(_failureOf(e));
    }
    if (generation != _generation) return;
    runInAction(() {
      this.code = ticket.code;
      this.phase = RemotePairingPhase.waitingForBridge;
    });

    final DateTime deadline = DateTime.now().add(ticket.expiresIn);
    bool acknowledged = false;
    DateTime? lastSent;
    while (generation == _generation && DateTime.now().isBefore(deadline)) {
      if (!acknowledged &&
          (lastSent == null ||
              DateTime.now().difference(lastSent) >= _resendInterval)) {
        lastSent = DateTime.now();
        try {
          acknowledged = await _sendCode(ticket.code);
        } catch (_) {
          // OBS connection hiccup: the next round sends again
        }
      }
      try {
        final RemotePairing? pairing = await _relay.collectPairing(
          ticket.pairingId,
        );
        if (generation != _generation) return;
        if (pairing != null) {
          _store(connection, pairing);
          runInAction(() => this.phase = RemotePairingPhase.paired);
          GeneralHelper.advLog(
            'Remote access: paired with ${pairing.bridgeName} '
            '(${pairing.bridgeKind})',
            includeInLogs: true,
          );
          unawaited(this.refresh(connection));
          return;
        }
      } on RemoteRelayException catch (e) {
        if (generation != _generation) return;
        if (!e.isNetwork) {
          // Expired (404) or refused: no point in polling on
          GeneralHelper.logFailure('Remote access: pairing ended', e);
          return _fail(
            e.statusCode == 404
                ? RemotePairingFailure.noBridge
                : _failureOf(e),
          );
        }
      }
      await Future<void>.delayed(_pollInterval);
    }
    if (generation == _generation) {
      GeneralHelper.logFailure(
        'Remote access: pairing',
        'no bridge redeemed the code before it expired',
      );
      _fail(RemotePairingFailure.noBridge);
    }
  }

  void _store(Connection connection, RemotePairing pairing) {
    connection
      ..relayBridgeId = pairing.bridgeId
      ..relayAppToken = pairing.appToken
      ..relayDeviceId = pairing.deviceId
      ..relayBridgeName = pairing.bridgeName
      ..relayBridgeKind = pairing.bridgeKind;
    if (connection.isInBox) connection.save();
  }

  @action
  void _fail(RemotePairingFailure failure) {
    this.failure = failure;
    this.phase = RemotePairingPhase.failed;
    this.code = null;
  }

  RemotePairingFailure _failureOf(RemoteRelayException e) {
    if (e.isNetwork) return RemotePairingFailure.network;
    switch (e.error) {
      case 'pro_required':
        return RemotePairingFailure.proRequired;
      case 'verify_unavailable':
        return RemotePairingFailure.verifyUnavailable;
      case 'rate_limited':
      case 'too_many_pairings':
        return RemotePairingFailure.rateLimited;
      default:
        return RemotePairingFailure.network;
    }
  }

  /// The paired bridge's state and devices.
  @action
  Future<void> refresh(Connection connection) async {
    if (!connection.hasRemote) {
      this.info = null;
      return;
    }
    this.infoLoading = true;
    try {
      final RemoteBridgeInfo info = await _relay.bridgeInfo(
        connection.relayBridgeId!,
        connection.relayAppToken!,
      );
      runInAction(() {
        this.info = info;
        this.infoError = null;
        if (info.name.isNotEmpty && info.name != connection.relayBridgeName) {
          connection.relayBridgeName = info.name;
          connection.relayBridgeKind = info.kind;
          if (connection.isInBox) connection.save();
        }
      });
    } on RemoteRelayException catch (e) {
      runInAction(() => this.infoError = e);
      if (e.isUnpaired) _forgetLocally(connection);
    } finally {
      runInAction(() => this.infoLoading = false);
    }
  }

  /// Removes [deviceId] from the bridge; this device's own id also forgets
  /// the pairing here. Returns false when the relay couldn't be reached.
  @action
  Future<bool> removeDevice(Connection connection, String deviceId) async {
    if (!connection.hasRemote) return false;
    final bool self = deviceId == connection.relayDeviceId;
    try {
      await _relay.removeDevice(deviceId, connection.relayAppToken!);
    } on RemoteRelayException catch (e) {
      // Turning it off here must work offline too: the relay drops a
      // device nobody uses after 180 days, and its token is gone with us
      if (!e.isUnpaired && !(self && (e.statusCode == 404 || e.isNetwork))) {
        GeneralHelper.logFailure('Remote access: removing a device failed', e);
        return false;
      }
    }
    if (self) {
      _forgetLocally(connection);
    } else {
      await this.refresh(connection);
    }
    return true;
  }

  /// Turns remote access off for this device (removes it on the relay).
  Future<bool> forget(Connection connection) async {
    if (!connection.hasRemote) return true;
    final String? self = connection.relayDeviceId;
    if (self == null) {
      _forgetLocally(connection);
      return true;
    }
    return this.removeDevice(connection, self);
  }

  /// Asks a standalone bridge to start OBS.
  Future<bool> startObs(Connection connection) async {
    if (!connection.hasRemote) return false;
    try {
      await _relay.startObs(
        connection.relayBridgeId!,
        connection.relayAppToken!,
      );
      return true;
    } on RemoteRelayException catch (e) {
      GeneralHelper.logFailure('Remote access: Start OBS failed', e);
      return false;
    }
  }

  /// Start OBS on a standalone bridge and wait until the relay reports it
  /// running (OBS needs a few seconds to load). False on refusal / timeout.
  Future<bool> startObsAndWait(
    Connection connection, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    if (!await this.startObs(connection)) return false;
    final DateTime deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(_pollInterval);
      await this.refresh(connection);
      final RemoteBridgeInfo? info = this.info;
      if (info != null && info.online && info.obsState == 'running') {
        return true;
      }
      if (!connection.hasRemote) return false;
    }
    return false;
  }

  @action
  void _forgetLocally(Connection connection) {
    connection.clearRemote();
    if (connection.isInBox) connection.save();
    this.info = null;
    if (this.phase == RemotePairingPhase.paired) {
      this.phase = RemotePairingPhase.idle;
    }
  }
}

/// [RemoteCodeSender] over the active OBS session: the plugin's vendor
/// request first (it answers), else a CustomEvent for the standalone.
Future<bool> sendPairCodeThroughObs(String code) async {
  final socket = GetIt.instance<NetworkStore>().activeSession?.socket;
  if (socket == null) return false;
  final vendor = await NetworkHelper.makeRequest(
    socket,
    RequestType.CallVendorRequest,
    {
      'vendorName': kRemoteBridgeVendor,
      'requestType': 'Pair',
      'requestData': {'code': code},
    },
  );
  if (vendor.success) return true;
  final event = await NetworkHelper.makeRequest(
    socket,
    RequestType.BroadcastCustomEvent,
    {
      'eventData': {
        kRemotePairEventKey: {'code': code},
      },
    },
  );
  if (!event.success) {
    GeneralHelper.advLog(
      'Remote access: sending the pairing code through OBS failed '
      '(${event.failureKind})',
      level: LogLevel.Warning,
      includeInLogs: true,
    );
  }
  return false;
}
