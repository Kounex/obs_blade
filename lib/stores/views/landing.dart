import 'package:mobx/mobx.dart';
import 'package:obs_station/models/connection.dart';
import 'package:obs_station/types/mixins/short_provider.dart';
import 'package:obs_station/utils/network_helper.dart';

// Include generated file
part 'landing.g.dart';

class LandingStore = _LandingStore with _$LandingStore, ShortProvider;

abstract class _LandingStore with Store {
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
