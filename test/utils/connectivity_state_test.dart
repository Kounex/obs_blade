import 'dart:async';

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/connectivity_state.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// connectivity_plus 7.3 on iOS, after the dashboard's listener went away:
/// the first check reads a fresh NWPathMonitor (unsatisfied -> none), the
/// monitor's first update then reports the real path.
class _StaleFirstAnswer extends ConnectivityPlatform
    with MockPlatformInterfaceMixin {
  final List<ConnectivityResult> first;
  final List<ConnectivityResult>? update;
  final StreamController<List<ConnectivityResult>> _changes =
      StreamController.broadcast();

  _StaleFirstAnswer(this.first, this.update);

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => first;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    final List<ConnectivityResult>? update = this.update;
    if (update != null) {
      Timer(const Duration(milliseconds: 30), () => _changes.add(update));
    }
    return _changes.stream;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<List<ConnectivityResult>> settle(
    List<ConnectivityResult> first, [
    List<ConnectivityResult>? update,
  ]) {
    ConnectivityPlatform.instance = _StaleFirstAnswer(first, update);
    return settledConnectivity(wait: const Duration(milliseconds: 200));
  }

  test('a stale "none" waits for the monitor\'s real answer', () async {
    expect(await settle([ConnectivityResult.none], [ConnectivityResult.wifi]), [
      ConnectivityResult.wifi,
    ]);
  });

  test('a clear first answer is taken as is', () async {
    expect(await settle([ConnectivityResult.mobile]), [
      ConnectivityResult.mobile,
    ]);
  });

  test('really offline: "none" after the wait', () async {
    expect(await settle([ConnectivityResult.none]), [ConnectivityResult.none]);
  });

  test('only mobile data for sure skips the LAN', () {
    expect(mobileDataOnly([ConnectivityResult.mobile]), isTrue);
    expect(mobileDataOnly([ConnectivityResult.satellite]), isTrue);
    for (final unclearOrLocal in [
      [ConnectivityResult.wifi],
      [ConnectivityResult.wifi, ConnectivityResult.mobile],
      [ConnectivityResult.none],
      [ConnectivityResult.vpn, ConnectivityResult.mobile],
      [ConnectivityResult.other],
      <ConnectivityResult>[],
    ]) {
      expect(
        mobileDataOnly(unclearOrLocal),
        isFalse,
        reason: '$unclearOrLocal',
      );
    }
  });
}
