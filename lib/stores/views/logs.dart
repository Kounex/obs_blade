import 'package:mobx/mobx.dart';
import '../../types/enums/order.dart';

import '../../models/enums/log_level.dart';

part 'logs.g.dart';

enum AmountLogEntries {
  Ten,
  TwentyFive,
  Fifty,
}

extension AmountLogEntriesFunctions on AmountLogEntries {
  int get number => {
        AmountLogEntries.Ten: 10,
        AmountLogEntries.TwentyFive: 25,
        AmountLogEntries.Fifty: 50,
      }[this]!;
}

class LogsStore = _LogsStore with _$LogsStore;

abstract class _LogsStore with Store {
  @observable
  LogLevel? logLevel;

  @observable
  DateTime? fromDate;

  @observable
  DateTime? toDate;

  @observable
  AmountLogEntries? amountLogEntries = AmountLogEntries.Ten;

  @observable
  Order filterOrder = Order.Descending;

  @action
  void setLogLevel(LogLevel? logLevel) => this.logLevel = logLevel;

  @action
  void setFromDate(DateTime? fromDate) => this.fromDate = fromDate;

  @action
  void setToDate(DateTime? toDate) => this.toDate = toDate;

  @action
  void setAmountLogEntries(AmountLogEntries? amountLogEntries) =>
      this.amountLogEntries = amountLogEntries;

  @action
  void toggleFilterOrder() => this.filterOrder =
      this.filterOrder == Order.Ascending ? Order.Descending : Order.Ascending;
}
