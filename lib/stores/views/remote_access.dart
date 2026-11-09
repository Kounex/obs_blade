import 'dart:async';
import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';

import '../../models/connection.dart';
import '../../models/enums/log_level.dart';
import '../../types/classes/stream/events/base.dart';
import '../../types/enums/request_type.dart';
import '../../utils/general_helper.dart';
import '../../utils/network_helper.dart';
import '../../utils/remote/device_label.dart';
import '../../utils/remote/noise_ik.dart';
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

  /// The relay paired, but the bridge's key never came back through OBS
  /// (an OBS Blade Remote from before end-to-end encryption, or OBS
  /// dropped the event): nothing is stored
  noConfirmation,
}

/// Hands the pairing code and this device's end-to-end key (base64) to the
/// bridge through OBS - repeated until the bridge's ack arrives.
typedef RemoteCodeSender = Future<void> Function(String code, String appKey);

/// The bridge's answer through OBS: its end-to-end key for [code].
typedef RemotePairAck = ({String code, String bridgeKey});

/// The acks arriving on the OBS connection while pairing.
typedef RemotePairAcks = Stream<RemotePairAck> Function();

/// Remote access (Pro) for the dashboard's sheet: pairing this device with
/// the bridge next to OBS while connected on the LAN, and the paired
/// bridge's state / devices. Protocol: `tool/remote_relay/README.md`.
class RemoteAccessStore = _RemoteAccessStore with _$RemoteAccessStore;

abstract class _RemoteAccessStore with Store {
  final RemoteRelayClient _relay;
  final Future<String?> Function() _appUserId;
  final RemoteCodeSender _sendCode;
  final RemotePairAcks _acks;
  final Duration _pollInterval;
  final Duration _resendInterval;

  /// The model / device name sent at pairing (null: the sheet's generic
  /// label)
  final Future<String?> Function() _deviceLabel;

  /// A pairing named before the model name is renamed once per sheet
  bool _upgradedGenericName = false;

  _RemoteAccessStore({
    RemoteRelayClient? relay,
    Future<String?> Function()? appUserId,
    RemoteCodeSender? sendCode,
    RemotePairAcks? acks,
    Duration pollInterval = const Duration(seconds: 2),
    Duration resendInterval = const Duration(seconds: 2),
    Future<String?> Function()? deviceLabel,
  }) : _deviceLabel = deviceLabel ?? currentDeviceLabel,
       _relay = relay ?? RemoteRelayClient(),
       _appUserId = appUserId ?? (() => GetIt.instance<ProStore>().appUserId()),
       _sendCode = sendCode ?? sendPairCodeThroughObs,
       _acks = acks ?? pairAcksThroughObs,
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
    final String name = await _deviceLabel() ?? deviceName;
    if (generation != _generation) return;

    final RemotePairingTicket ticket;
    try {
      ticket = await _relay.createPairing(
        appUserId: appUserId,
        deviceName: name,
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

    /// This pairing's end-to-end key; the bridge's comes back through OBS
    /// (never via the relay, which could swap it)
    final NoiseKeyPair appKey = await NoiseKeyPair.generate();
    final String appKeyText = base64Encode(appKey.publicKey);
    String? bridgeKey;
    final StreamSubscription<RemotePairAck> acks = _acks().listen((ack) {
      if (_sameCode(ack.code, ticket.code) && _isKey(ack.bridgeKey)) {
        bridgeKey = ack.bridgeKey;
      }
    });

    final DateTime deadline = DateTime.now().add(ticket.expiresIn);
    RemotePairing? collected;
    DateTime? lastSent;
    try {
      while (generation == _generation && DateTime.now().isBefore(deadline)) {
        if (bridgeKey == null &&
            (lastSent == null ||
                DateTime.now().difference(lastSent) >= _resendInterval)) {
          lastSent = DateTime.now();
          try {
            await _sendCode(ticket.code, appKeyText);
          } catch (_) {
            // OBS connection hiccup: the next round sends again
          }
        }
        if (collected == null) {
          try {
            collected = await _relay.collectPairing(ticket.pairingId);
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
        }
        if (generation != _generation) return;
        final RemotePairing? pairing = collected;
        final String? key = bridgeKey;
        if (pairing != null && key != null) {
          _store(connection, pairing, base64Encode(appKey.privateKey), key);
          runInAction(() => this.phase = RemotePairingPhase.paired);
          GeneralHelper.advLog(
            'Remote access: paired with ${pairing.bridgeName} '
            '(${pairing.bridgeKind}), end-to-end encrypted',
            includeInLogs: true,
          );
          unawaited(this.refresh(connection));
          return;
        }
        await Future<void>.delayed(_pollInterval);
      }
    } finally {
      await acks.cancel();
    }
    if (generation != _generation) return;
    final RemotePairing? orphan = collected;
    if (orphan != null) {
      // Paired at the relay, but no key from the bridge: don't keep a
      // device there that can never open a session
      GeneralHelper.logFailure(
        'Remote access: pairing',
        'the bridge did not send its key back through OBS',
      );
      unawaited(
        _relay
            .removeDevice(orphan.deviceId, orphan.appToken)
            .catchError((_) {}),
      );
      return _fail(RemotePairingFailure.noConfirmation);
    }
    GeneralHelper.logFailure(
      'Remote access: pairing',
      'no bridge redeemed the code before it expired',
    );
    _fail(RemotePairingFailure.noBridge);
  }

  static String _normalizedCode(String code) =>
      code.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();

  static bool _sameCode(String a, String b) =>
      _normalizedCode(a) == _normalizedCode(b);

  static bool _isKey(String text) {
    try {
      return base64Decode(text).length == 32;
    } on FormatException {
      return false;
    }
  }

  void _store(
    Connection connection,
    RemotePairing pairing,
    String appKey,
    String bridgeKey,
  ) {
    connection
      ..relayBridgeId = pairing.bridgeId
      ..relayAppToken = pairing.appToken
      ..relayDeviceId = pairing.deviceId
      ..relayBridgeName = pairing.bridgeName
      ..relayBridgeKind = pairing.bridgeKind
      ..relayAppKey = appKey
      ..relayBridgeKey = bridgeKey;
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
      unawaited(_upgradeGenericName(connection, info));
    } on RemoteRelayException catch (e) {
      runInAction(() => this.infoError = e);
      if (e.isUnpaired) _forgetLocally(connection);
    } finally {
      runInAction(() => this.infoLoading = false);
    }
  }

  /// Renames [deviceId] (the name the PC lists it under). Returns false
  /// when the relay couldn't be reached or refused it.
  Future<bool> renameDevice(
    Connection connection,
    String deviceId,
    String name,
  ) async {
    final String trimmed = name.trim();
    if (!connection.hasRemote || trimmed.isEmpty) return false;
    try {
      await _relay.renameDevice(
        deviceId,
        trimmed.length > kDeviceNameMaxLength
            ? trimmed.substring(0, kDeviceNameMaxLength)
            : trimmed,
        connection.relayAppToken!,
      );
    } on RemoteRelayException catch (e) {
      if (e.isUnpaired) {
        _forgetLocally(connection);
      } else {
        GeneralHelper.logFailure('Remote access: renaming a device failed', e);
      }
      return false;
    }
    await this.refresh(connection);
    return true;
  }

  /// Pairings from before the model name are listed as "iPhone" on the PC:
  /// renamed to the model the first time the sheet sees one
  Future<void> _upgradeGenericName(
    Connection connection,
    RemoteBridgeInfo info,
  ) async {
    if (_upgradedGenericName) return;
    final RemoteDevice? self = info.devices
        .where((d) => d.isThisDevice)
        .firstOrNull;
    if (self == null || !kGenericDeviceNames.contains(self.name)) return;
    _upgradedGenericName = true;
    final String? label = await _deviceLabel();
    if (label == null || label == self.name) return;
    await this.renameDevice(connection, self.id, label);
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
/// request (it takes the code), else a CustomEvent for the standalone.
/// Either way the bridge answers with the `obs-blade-pair-ack` CustomEvent
/// ([pairAcksThroughObs]).
Future<void> sendPairCodeThroughObs(String code, String appKey) async {
  final socket = GetIt.instance<NetworkStore>().activeSession?.socket;
  if (socket == null) return;
  final Map<String, String> pair = {'code': code, 'app_key': appKey};
  final vendor = await NetworkHelper.makeRequest(
    socket,
    RequestType.CallVendorRequest,
    {
      'vendorName': kRemoteBridgeVendor,
      'requestType': 'Pair',
      'requestData': pair,
    },
  );
  if (vendor.success) return;
  final event = await NetworkHelper.makeRequest(
    socket,
    RequestType.BroadcastCustomEvent,
    {
      'eventData': {kRemotePairEventKey: pair},
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
}

/// [RemotePairAcks] from the active OBS session (CustomEvents reach the
/// app: it subscribes to General events).
Stream<RemotePairAck> pairAcksThroughObs() => GetIt.instance<NetworkStore>()
    .watchOBSStream()
    .where((message) => message is BaseEvent)
    .map((message) => (message as BaseEvent).jsonRAW['d'])
    .where((d) => d is Map && d['eventType'] == 'CustomEvent')
    .map((d) => (d as Map)['eventData'])
    .where((data) => data is Map && data[kRemotePairAckEventKey] is Map)
    .map((data) => (data as Map)[kRemotePairAckEventKey] as Map)
    .where((ack) => ack['code'] is String && ack['bridge_key'] is String)
    .map(
      (ack) =>
          (code: ack['code'] as String, bridgeKey: ack['bridge_key'] as String),
    );
