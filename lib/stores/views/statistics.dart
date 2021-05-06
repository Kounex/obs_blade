import 'package:mobx/mobx.dart';

import '../../types/enums/order.dart';

part 'statistics.g.dart';

enum FilterType {
  StatisticTime,
  Name,
  TotalTime,
  Kbits,
}

extension FilterTypeFunctions on FilterType {
  String get text => const {
        FilterType.StatisticTime: 'Date',
        FilterType.Name: 'Name',
        FilterType.TotalTime: 'Total stream time',
        FilterType.Kbits: 'kbit/s',
      }[this]!;
}

enum AmountStatisticEntries {
  Five,
  Ten,
  TwentyFive,
  Fifty,
}

extension AmountStatisticEntriesFunctions on AmountStatisticEntries {
  int get number => const {
        AmountStatisticEntries.Five: 5,
        AmountStatisticEntries.Ten: 10,
        AmountStatisticEntries.TwentyFive: 25,
        AmountStatisticEntries.Fifty: 50,
      }[this]!;
}

class StatisticsStore = _StatisticsStore with _$StatisticsStore;

abstract class _StatisticsStore with Store {
  @observable
  FilterType filterType = FilterType.StatisticTime;

  @observable
  Order filterOrder = Order.Descending;

  @observable
  AmountStatisticEntries amountStatisticEntries = AmountStatisticEntries.Five;

  @observable
  String filterName = '';

  @observable
  bool? showOnlyFavorites = false;

  @observable
  DateTime? fromDate;

  @observable
  DateTime? toDate;

  @observable
  bool? excludeUnnamedStreams = false;

  @action
  void setFilterType(FilterType filterType) => this.filterType = filterType;

  @action
  void toggleFilterOrder() => this.filterOrder =
      this.filterOrder == Order.Ascending ? Order.Descending : Order.Ascending;

  @action
  void setAmountStatisticEntries(
          AmountStatisticEntries amountStatisticEntries) =>
      this.amountStatisticEntries = amountStatisticEntries;

  @action
  void setFilterName(String filterName) => this.filterName = filterName;

  @action
  void setShowOnlyFavorites(bool? showOnlyFavorites) =>
      this.showOnlyFavorites = showOnlyFavorites;

  @action
  void setFromDate(DateTime? fromDate) => this.fromDate = fromDate;

  @action
  void setToDate(DateTime? toDate) => this.toDate = toDate;

  @action
  void setExcludeUnnamedStreams(bool? excludeUnnamedStreams) =>
      this.excludeUnnamedStreams = excludeUnnamedStreams;
}
