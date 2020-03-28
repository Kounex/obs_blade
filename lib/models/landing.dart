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
  @observable
  bool _manualMode = false;

  bool get refreshable => _refreshable;

  Future<List<String>> get obsAutodiscoverIPs => _obsAutodiscoverIPs;

  bool get manualMode => _manualMode;

  @action
  void setRefreshable(bool refreshable) => _refreshable = refreshable;

  @action
  void updateObsAutodiscoverIPs() {
    _obsAutodiscoverIPs = NetworkHelper.getAvailableOBSIPs();
  }

  @action
  void toggleManualMode([bool manualMode]) =>
      _manualMode = manualMode != null ? manualMode : !_manualMode;

  @override
  void dispose() {}
}
