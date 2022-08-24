import 'package:mobx/mobx.dart';

import '../../models/connection.dart';
import '../../utils/network_helper.dart';
import '../../utils/validation_helper.dart';

part 'home.g.dart';

enum ConnectMode {
  Autodiscover,
  QR,
  Manual;

  String get text => {
        ConnectMode.Autodiscover: 'Autodiscover',
        ConnectMode.QR: 'Quick Connect',
        ConnectMode.Manual: 'Manual',
      }[this]!;
}

class HomeStore = _HomeStore with _$HomeStore;

abstract class _HomeStore with Store {
  @observable
  Future<List<Connection>>? autodiscoverConnections;
  @observable
  String autodiscoverPort = '4455';

  @observable
  bool refreshable = false;
  @observable
  bool doRefresh = false;
  @observable
  ConnectMode connectMode = ConnectMode.Autodiscover;
  @observable
  bool domainMode = false;
  @observable
  String protocolScheme = 'wss://';

  Connection typedInConnection = Connection('', 4455, '');

  @action
  void setAutodiscoverPort(String autodiscoverPort) =>
      this.autodiscoverPort = autodiscoverPort;

  @action
  void updateAutodiscoverConnections() {
    if (ValidationHelper.portValidator(this.autodiscoverPort) == null) {
      this.autodiscoverConnections = NetworkHelper.getAvailableOBSIPs(
          int.tryParse(this.autodiscoverPort) ?? 4455);
    }
  }

  @action
  void setRefreshable(bool refreshable) => this.refreshable = refreshable;

  @action
  void setDomainMode(bool domainMode) => this.domainMode = domainMode;

  /// Basically just toggles the [doRefresh] value to ] just so listeners can
  /// act on that (the actual value has no meaning) - used to know when the
  /// user initiated a refresh
  @action
  void initiateRefresh() {
    this.doRefresh = !this.doRefresh;
  }

  @action
  void setProtocolScheme(String protocolScheme) =>
      this.protocolScheme = protocolScheme;

  @action
  void setConnectMode(ConnectMode connectMode) =>
      this.connectMode = connectMode;
}
