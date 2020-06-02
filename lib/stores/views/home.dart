import 'package:mobx/mobx.dart';

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
    int port = int.tryParse(autodiscoverPort);
    if (port != null && port > 0 && port <= 65535) {
      this.autodiscoverConnections =
          NetworkHelper.getAvailableOBSIPs(port: port);
    }
  }

  @action
  void setRefreshable(bool refreshable) => this.refreshable = refreshable;

  @action
  void toggleManualMode([bool manualMode]) =>
      this.manualMode = manualMode != null ? manualMode : !this.manualMode;
}
