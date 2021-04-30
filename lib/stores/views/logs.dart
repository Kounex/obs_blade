import 'package:mobx/mobx.dart';

import '../../models/enums/log_level.dart';

part 'logs.g.dart';

class LogsStore = _LogsStore with _$LogsStore;

abstract class _LogsStore with Store {
  @observable
  LogLevel? logLevel;

  @action
  void setLogLevel(LogLevel logLevel) => this.logLevel = logLevel;
}
