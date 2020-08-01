import 'package:connectivity/connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/utils/validation_helper.dart';

import '../../models/connection.dart';
import '../../utils/network_helper.dart';

part 'home.g.dart';

class HomeStore = _HomeStore with _$HomeStore;

abstract class _HomeStore with Store {
  @observable
  Future<List<Connection>> autodiscoverConnections;
  @observable
  String autodiscoverPort = '4444';

  @observable
  bool refreshable = false;
  @observable
  bool manualMode = false;

  Connection typedInConnection = Connection('', 4444, '');

  @action
  void setAutodiscoverPort(String autodiscoverPort) =>
      this.autodiscoverPort = autodiscoverPort;

  @action
  void updateAutodiscoverConnections() {
    if (ValidationHelper.portValidation(this.autodiscoverPort) == null) {
      this.autodiscoverConnections = compute(NetworkHelper.getAvailableOBSIPs,
          int.tryParse(this.autodiscoverPort));
    }
  }

  @action
  void setRefreshable(bool refreshable) => this.refreshable = refreshable;

  @action
  void toggleManualMode([bool manualMode]) =>
      this.manualMode = manualMode != null ? manualMode : !this.manualMode;
}
