import 'package:mobx/mobx.dart';
import 'package:mobx_provider/mobx_provider.dart';
import 'package:obs_station/utils/network_helper.dart';
import 'package:ping_discover_network/ping_discover_network.dart';

// Include generated file
part 'landing.g.dart';

class LandingStore = _LandingStore with _$LandingStore;

abstract class _LandingStore extends MobxBase with Store {
  @observable
  bool _refreshable = false;
  @observable
  Future<List<NetworkAddress>> _obsNetworkAddresses;

  bool get refreshable => _refreshable;

  Future<List<NetworkAddress>> get obsNetworkAddresses => _obsNetworkAddresses;

  @action
  void setRefreshable(bool refreshable) => _refreshable = refreshable;

  @action
  void updateObsNetworkAddresses() async {
    _obsNetworkAddresses = NetworkHelper.getOBSNetworkAddresses();
  }

  @override
  void dispose() {}
}
