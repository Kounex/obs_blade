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
  bool _fetchingObsNetworkAddresses = false;
  @observable
  ObservableList<NetworkAddress> _obsNetworkAddresses;

  bool get refreshable => _refreshable;

  bool get fetchingObsNetworkAddresses => _fetchingObsNetworkAddresses;

  List<NetworkAddress> get obsNetworkAddresses => _obsNetworkAddresses.toList();

  @action
  void setRefreshable(bool refreshable) => _refreshable = refreshable;

  @action
  void setFetchingObsNetworkAddresses(bool fetchingObsNetworkAddresses) =>
      _fetchingObsNetworkAddresses = fetchingObsNetworkAddresses;

  @action
  Future<void> updateObsNetworkAddresses() async {
    _fetchingObsNetworkAddresses = true;
    _obsNetworkAddresses = ObservableList<NetworkAddress>.of(
        await NetworkHelper.getOBSNetworkAddresses());
    _fetchingObsNetworkAddresses = false;
  }

  @override
  void dispose() {}
}
