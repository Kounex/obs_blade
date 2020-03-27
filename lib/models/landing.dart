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
  Future<List<String>> _obsAutodiscoverIPs;

  bool get refreshable => _refreshable;

  Future<List<String>> get obsAutodiscoverIPs => _obsAutodiscoverIPs;

  @action
  void setRefreshable(bool refreshable) => _refreshable = refreshable;

  @action
  void updateObsAutodiscoverIPs() {
    _obsAutodiscoverIPs = NetworkHelper.getAvailableOBSIPs();
  }

  @override
  void dispose() {}
}
