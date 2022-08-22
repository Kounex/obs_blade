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
        FilterType.TotalTime: 'Session Time',
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

enum StatType {
  Stream,
  Recording;

  String get name => {
        StatType.Stream: 'Stream',
        StatType.Recording: 'Recording',
      }[this]!;
}

enum TimeUnit {
  Seconds,
  Minutes,
  Hours;

  int get factorToS => {
        TimeUnit.Seconds: 1,
        TimeUnit.Minutes: 60,
        TimeUnit.Hours: 3600,
      }[this]!;
}

enum DurationFilter {
  Shorter,
  Longer,
  Between;

  String get text => {
        DurationFilter.Shorter: 'Shorter than...',
        DurationFilter.Longer: 'Longer than...',
        DurationFilter.Between: 'Between...',
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
  bool? excludeUnnamedStats = false;

  @observable
  StatType? statType;

  @observable
  DurationFilter? durationFilter;

  @observable
  String durationFilterAmount = '';

  @observable
  TimeUnit durationFilterTimeUnit = TimeUnit.Minutes;

  @observable
  bool triggeredDefault = false;

  @computed
  bool get isFilterSortActive =>
      this.filterType != FilterType.StatisticTime ||
      this.filterOrder != Order.Descending ||
      this.amountStatisticEntries != AmountStatisticEntries.Five ||
      this.filterName != '' ||
      this.showOnlyFavorites != false ||
      this.fromDate != null ||
      this.toDate != null ||
      this.excludeUnnamedStats != false ||
      this.statType != null ||
      this.durationFilter != null;

  @action
  void setDefaults() {
    this.filterType = FilterType.StatisticTime;
    this.filterOrder = Order.Descending;
    this.amountStatisticEntries = AmountStatisticEntries.Five;
    this.filterName = '';
    this.showOnlyFavorites = false;
    this.fromDate = null;
    this.toDate = null;
    this.excludeUnnamedStats = false;
    this.statType = null;
    this.durationFilter = null;
    this.durationFilterAmount = '';
    this.durationFilterTimeUnit = TimeUnit.Minutes;

    /// Used as a toggle (only listen for change, not value) to exactly determine
    /// that the user set everything to default (because just setting the value
    /// to the original value might not be enough)
    this.triggeredDefault = !this.triggeredDefault;
  }

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
  void setExcludeUnnamedStats(bool? excludeUnnamedStats) =>
      this.excludeUnnamedStats = excludeUnnamedStats;

  @action
  void setStatType(StatType? statType) => this.statType = statType;

  @action
  void setDurationFilter(DurationFilter? durationFilter) =>
      this.durationFilter = durationFilter;

  @action
  void setDurationFilterAmount(String durationFilterAmount) =>
      this.durationFilterAmount = durationFilterAmount;

  @action
  void setDurationFilterTimeUnit(TimeUnit durationFilterTimeUnit) =>
      this.durationFilterTimeUnit = durationFilterTimeUnit;
}
