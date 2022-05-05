import 'package:mobx/mobx.dart';

import '../../models/connection.dart';
import '../../utils/network_helper.dart';
import '../../utils/validation_helper.dart';

part 'home.g.dart';

class HomeStore = _HomeStore with _$HomeStore;

abstract class _HomeStore with Store {
  @observable
  Future<List<Connection>>? autodiscoverConnections;
  @observable
  String autodiscoverPort = '4444';

  @observable
  bool refreshable = false;
  @observable
  bool manualMode = false;
  @observable
  bool domainMode = false;

  Connection typedInConnection = Connection('', 4444, '');

  @action
  void setAutodiscoverPort(String autodiscoverPort) =>
      this.autodiscoverPort = autodiscoverPort;

  @action
  void updateAutodiscoverConnections() {
    if (ValidationHelper.portValidation(this.autodiscoverPort) == null) {
      this.autodiscoverConnections = NetworkHelper.getAvailableOBSIPs(
          int.tryParse(this.autodiscoverPort) ?? 4444);
    }
  }

  @action
  void setRefreshable(bool refreshable) => this.refreshable = refreshable;

  @action
  void setDomainMode(bool domainMode) => this.domainMode = domainMode;

  @action
  void toggleManualMode([bool? manualMode]) =>
      this.manualMode = manualMode ?? !this.manualMode;
}
