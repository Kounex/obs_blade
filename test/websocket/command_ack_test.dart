import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/types/classes/obs_request_ack.dart';
import 'package:obs_blade/types/enums/request_batch_type.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/types/enums/web_socket_codes/request_status.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/utils/network_helper.dart';

import 'support/fake_obs_peer.dart';

/// Command-ack layer protocol tests against a loopback fake OBS v5 peer.
/// The store drives the real dispatch path: responses arrive on the socket,
/// `NetworkStore.watchOBSStream` decodes them and completes the pending acks.
void main() {
  late FakeObsPeer peer;
  late NetworkStore networkStore;

  const shortAckTimeout = Duration(milliseconds: 200);

  Future<void> connect() async {
    final closeCode = await networkStore.setOBSWebSocket(peer.connection);
    expect(closeCode, WebSocketCloseCode.DontClose);
  }

  setUp(() async {
    NetworkHelper.requestAckTimeout = const Duration(seconds: 10);
    peer = await FakeObsPeer.start();
    networkStore = NetworkStore();
    GetIt.instance.registerSingleton<NetworkStore>(networkStore);
  });

  tearDown(() async {
    NetworkHelper.failAllPendingAcks();
    NetworkHelper.requestAckTimeout = const Duration(seconds: 10);
    networkStore.closeSession();
    await peer.close();
    await GetIt.instance.reset();
  });

  test('handshake against fake peer succeeds', () async {
    await connect();
    expect(networkStore.activeSession, isNotNull);
  });

  group('makeRequest ack', () {
    test('success: completes when OBS acks', () async {
      await connect();

      final ack = await NetworkHelper.makeRequest(
        networkStore.activeSession!.socket,
        RequestType.GetVersion,
      );

      expect(ack.success, isTrue);
      expect(ack.failureKind, isNull);
      expect(ack.requestType, RequestType.GetVersion);
      expect(NetworkHelper.pendingAckCount, 0);
    });

    test('rejection: surfaces OBS requestStatus code and comment', () async {
      await connect();
      peer.rejections['SetCurrentProgramScene'] =
          RequestStatus.InvalidResourceType.identifier;
      peer.rejectionComment = 'No source with that name';

      final ack = await NetworkHelper.makeRequest(
        networkStore.activeSession!.socket,
        RequestType.SetCurrentProgramScene,
        {'sceneName': 'Nope'},
      );

      expect(ack.success, isFalse);
      expect(ack.failureKind, ObsRequestFailureKind.rejected);
      expect(ack.statusCode, RequestStatus.InvalidResourceType.identifier);
      expect(ack.statusComment, 'No source with that name');
      expect(ack.status, RequestStatus.InvalidResourceType);
      expect(NetworkHelper.pendingAckCount, 0);
    });

    test('timeout: dropped ack resolves as timeout failure', () async {
      await connect();
      NetworkHelper.requestAckTimeout = shortAckTimeout;
      peer.droppedRequestTypes.add('SetInputMute');

      final ack = await NetworkHelper.makeRequest(
        networkStore.activeSession!.socket,
        RequestType.SetInputMute,
        {'inputName': 'Mic', 'inputMuted': true},
      );

      expect(ack.success, isFalse);
      expect(ack.failureKind, ObsRequestFailureKind.timeout);
      expect(NetworkHelper.pendingAckCount, 0);
    });

    test(
      'late ack after timeout is dropped and cannot misroute a later request',
      () async {
        await connect();
        NetworkHelper.requestAckTimeout = shortAckTimeout;
        peer.ackDelay = const Duration(milliseconds: 600);

        final timedOutAck = await NetworkHelper.makeRequest(
          networkStore.activeSession!.socket,
          RequestType.SetInputVolume,
          {'inputName': 'Mic', 'inputVolumeMul': 0.5},
        );
        expect(timedOutAck.failureKind, ObsRequestFailureKind.timeout);
        expect(NetworkHelper.pendingAckCount, 0);

        /// The delayed ack for the first request arrives while a second one
        /// is in flight - it must be dropped, not complete the second one
        peer.ackDelay = null;
        final secondAckFuture = NetworkHelper.makeRequest(
          networkStore.activeSession!.socket,
          RequestType.SetInputVolume,
          {'inputName': 'Mic', 'inputVolumeMul': 0.8},
        );

        /// Wait until the late ack of the first request had its chance to
        /// (wrongly) complete something
        await Future<void>.delayed(const Duration(milliseconds: 700));

        final secondAck = await secondAckFuture;
        expect(secondAck.success, isTrue);
        expect(NetworkHelper.pendingAckCount, 0);
      },
    );

    test('disconnect mid-flight fails all pending acks at once', () async {
      await connect();
      peer.droppedRequestTypes.addAll(['SetInputMute', 'SetInputVolume']);

      final ackOne = NetworkHelper.makeRequest(
        networkStore.activeSession!.socket,
        RequestType.SetInputMute,
        {'inputName': 'Mic', 'inputMuted': true},
      );
      final ackTwo = NetworkHelper.makeRequest(
        networkStore.activeSession!.socket,
        RequestType.SetInputVolume,
        {'inputName': 'Mic', 'inputVolumeMul': 0.5},
      );
      expect(NetworkHelper.pendingAckCount, 2);

      await peer.closeSockets();

      final results = await Future.wait([ackOne, ackTwo]);
      expect(
        results.map((ack) => ack.failureKind),
        everyElement(ObsRequestFailureKind.connectionLost),
      );
      expect(NetworkHelper.pendingAckCount, 0);
    });
  });

  group('makeBatchRequest ack', () {
    test('success: all per-request results succeed', () async {
      await connect();

      final ack = await NetworkHelper.makeBatchRequest(
        networkStore.activeSession!.socket,
        RequestBatchType.Stats,
        [
          RequestBatchObject(RequestType.GetStreamStatus),
          RequestBatchObject(RequestType.GetRecordStatus),
          RequestBatchObject(RequestType.GetStats),
        ],
      );

      expect(ack.success, isTrue);
      expect(ack.results, hasLength(3));
      expect(ack.failures, isEmpty);
      expect(NetworkHelper.pendingAckCount, 0);
    });

    test('partial failure: single rejected entry is surfaced', () async {
      await connect();
      peer.rejections['GetRecordStatus'] =
          RequestStatus.InvalidResourceState.identifier;

      final ack = await NetworkHelper.makeBatchRequest(
        networkStore.activeSession!.socket,
        RequestBatchType.Stats,
        [
          RequestBatchObject(RequestType.GetStreamStatus),
          RequestBatchObject(RequestType.GetRecordStatus),
          RequestBatchObject(RequestType.GetStats),
        ],
      );

      expect(ack.success, isFalse);
      expect(ack.results, hasLength(3));
      expect(ack.failures, hasLength(1));
      expect(ack.failures.single.failureKind, ObsRequestFailureKind.rejected);
      expect(
        ack.failures.single.statusCode,
        RequestStatus.InvalidResourceState.identifier,
      );
      expect(ack.failures.single.requestType, RequestType.GetRecordStatus);
      expect(NetworkHelper.pendingAckCount, 0);
    });

    test('batch timeout resolves as batch-level failure', () async {
      await connect();
      NetworkHelper.requestAckTimeout = shortAckTimeout;
      peer.droppedRequestTypes.add('GetStreamStatus');

      final ack = await NetworkHelper.makeBatchRequest(
        networkStore.activeSession!.socket,
        RequestBatchType.Stats,
        [
          RequestBatchObject(RequestType.GetStreamStatus),
          RequestBatchObject(RequestType.GetRecordStatus),
        ],
      );

      expect(ack.success, isFalse);
      expect(ack.failureKind, ObsRequestFailureKind.timeout);
      expect(NetworkHelper.pendingAckCount, 0);
    });

    test(
      'empty batch: never hits the wire, resolves as empty success',
      () async {
        await connect();

        final ack = await NetworkHelper.makeBatchRequest(
          networkStore.activeSession!.socket,
          RequestBatchType.FilterList,
          const <RequestBatchObject>[],
        );

        expect(ack.success, isTrue);
        expect(ack.results, isEmpty);
        expect(peer.batches, isEmpty);
        expect(NetworkHelper.pendingAckCount, 0);
      },
    );
  });
}
