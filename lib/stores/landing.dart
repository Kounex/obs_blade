import 'package:mobx/mobx.dart';
import 'package:mobx_provider/mobx_provider.dart';

// Include generated file
part 'landing.g.dart';

class LandingStore = _LandingStore with _$LandingStore;

abstract class _LandingStore extends MobxBase with Store {
  @observable
  bool _refreshable = false;
  @observable
  bool _manualMode = false;

  bool get refreshable => _refreshable;

  bool get manualMode => _manualMode;

  @action
  void setRefreshable(bool refreshable) => _refreshable = refreshable;

  @action
  void toggleManualMode([bool manualMode]) =>
      _manualMode = manualMode != null ? manualMode : !_manualMode;

  @override
  void dispose() {}
}
