import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// The network the device is on, without connectivity_plus's stale first
/// answer on iOS.
///
/// connectivity_plus 7.3 answers `checkConnectivity` from an
/// `NWPathMonitor` it creates on demand and cancels when the last
/// `onConnectivityChanged` listener goes (the dashboard's, on leaving it).
/// A fresh monitor's `currentPath` is unsatisfied until its first update,
/// so the first check after that reads [ConnectivityResult.none] while on
/// Wi-Fi (dogfood 2026-11-08: a paired connection went relay-only at home).
/// A `none` answer therefore waits up to [wait] for the monitor's first
/// real update.
Future<List<ConnectivityResult>> settledConnectivity({
  Connectivity? connectivity,
  Duration wait = const Duration(seconds: 1),
}) async {
  final Connectivity source = connectivity ?? Connectivity();
  final List<ConnectivityResult> first = await source.checkConnectivity();
  if (!first.contains(ConnectivityResult.none)) return first;
  try {
    return await source.onConnectivityChanged
        .firstWhere((results) => !results.contains(ConnectivityResult.none))
        .timeout(wait);
  } on TimeoutException {
    return first;
  } catch (_) {
    return first;
  }
}

/// Only cellular (or satellite) for sure - no Wi-Fi, no ethernet, nothing
/// unknown. The one case where a LAN host can't answer.
bool mobileDataOnly(List<ConnectivityResult> results) =>
    results.isNotEmpty &&
    results.every(
      (r) =>
          r == ConnectivityResult.mobile || r == ConnectivityResult.satellite,
    );
