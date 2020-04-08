// Include generated file
import 'package:mobx/mobx.dart';
import 'package:mobx_provider/mobx_provider.dart';
import 'package:obs_station/models/connection.dart';
import 'package:obs_station/utils/network_helper.dart';

part 'network.g.dart';

class NetworkStore = _NetworkStore with _$NetworkStore;

abstract class _NetworkStore extends MobxBase with Store {
  @observable
  Future<List<Connection>> _autodiscoverConnections;
  @observable
  String _autodiscoverPort = '4444';

  String get autodiscoverPort => _autodiscoverPort;

  Future<List<Connection>> get obsAutodiscoverConnections =>
      _autodiscoverConnections;

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

  @override
  void dispose() {}
}
