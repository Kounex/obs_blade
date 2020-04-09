import 'package:mobx/mobx.dart';
import 'package:obs_station/types/mixins/short_provider.dart';

// Include generated file
part 'landing.g.dart';

class LandingStore = _LandingStore with _$LandingStore, ShortProvider;

abstract class _LandingStore with Store {
  @observable
  bool refreshable = false;
  @observable
  bool manualMode = false;

  @action
  void setRefreshable(bool refreshable) => this.refreshable = refreshable;

  @action
  void toggleManualMode([bool manualMode]) =>
      this.manualMode = manualMode != null ? manualMode : !this.manualMode;
}
