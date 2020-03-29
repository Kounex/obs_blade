import 'package:mobx/mobx.dart';
import 'package:mobx_provider/mobx_provider.dart';
import 'package:obs_station/models/connection.dart';
import 'package:obs_station/utils/network_helper.dart';

// Include generated file
part 'landing.g.dart';

class LandingStore = _LandingStore with _$LandingStore;

abstract class _LandingStore extends MobxBase with Store {
  @observable
  bool _refreshable = false;
  @observable
  Future<List<Connection>> _autodiscoverConnections;
  @observable
  String _autodiscoverPort = '4444';
  @observable
  bool _manualMode = false;

  bool get refreshable => _refreshable;

  String get autodiscoverPort => _autodiscoverPort;

  Future<List<Connection>> get obsAutodiscoverConnections =>
      _autodiscoverConnections;

  bool get manualMode => _manualMode;

  @action
  void setRefreshable(bool refreshable) => _refreshable = refreshable;

  @action
  void setAutodiscoverPort(String autodiscoverPort) =>
      _autodiscoverPort = autodiscoverPort;

  @action
  void updateAutodiscoverConnections() {
    int port = int.tryParse(autodiscoverPort);
    if (port != null && port > 0 && port <= 65535) {
      _autodiscoverConnections = NetworkHelper.getAvailableOBSIPs(port: port);
    }
  }

  @action
  void toggleManualMode([bool manualMode]) =>
      _manualMode = manualMode != null ? manualMode : !_manualMode;

  @override
  void dispose() {}
}
