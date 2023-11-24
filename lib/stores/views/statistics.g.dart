// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$StatisticsStore on _StatisticsStore, Store {
  Computed<bool>? _$isFilterSortActiveComputed;

  @override
  bool get isFilterSortActive => (_$isFilterSortActiveComputed ??=
          Computed<bool>(() => super.isFilterSortActive,
              name: '_StatisticsStore.isFilterSortActive'))
      .value;

  late final _$filterTypeAtom =
      Atom(name: '_StatisticsStore.filterType', context: context);

  @override
  FilterType get filterType {
    _$filterTypeAtom.reportRead();
    return super.filterType;
  }

  @override
  set filterType(FilterType value) {
    _$filterTypeAtom.reportWrite(value, super.filterType, () {
      super.filterType = value;
    });
  }

  late final _$filterOrderAtom =
      Atom(name: '_StatisticsStore.filterOrder', context: context);

  @override
  Order get filterOrder {
    _$filterOrderAtom.reportRead();
    return super.filterOrder;
  }

  @override
  set filterOrder(Order value) {
    _$filterOrderAtom.reportWrite(value, super.filterOrder, () {
      super.filterOrder = value;
    });
  }

  late final _$amountStatisticEntriesAtom =
      Atom(name: '_StatisticsStore.amountStatisticEntries', context: context);

  @override
  AmountStatisticEntries get amountStatisticEntries {
    _$amountStatisticEntriesAtom.reportRead();
    return super.amountStatisticEntries;
  }

  @override
  set amountStatisticEntries(AmountStatisticEntries value) {
    _$amountStatisticEntriesAtom
        .reportWrite(value, super.amountStatisticEntries, () {
      super.amountStatisticEntries = value;
    });
  }

  late final _$filterNameAtom =
      Atom(name: '_StatisticsStore.filterName', context: context);

  @override
  String get filterName {
    _$filterNameAtom.reportRead();
    return super.filterName;
  }

  @override
  set filterName(String value) {
    _$filterNameAtom.reportWrite(value, super.filterName, () {
      super.filterName = value;
    });
  }

  late final _$showOnlyFavoritesAtom =
      Atom(name: '_StatisticsStore.showOnlyFavorites', context: context);

  @override
  bool? get showOnlyFavorites {
    _$showOnlyFavoritesAtom.reportRead();
    return super.showOnlyFavorites;
  }

  @override
  set showOnlyFavorites(bool? value) {
    _$showOnlyFavoritesAtom.reportWrite(value, super.showOnlyFavorites, () {
      super.showOnlyFavorites = value;
    });
  }

  late final _$fromDateAtom =
      Atom(name: '_StatisticsStore.fromDate', context: context);

  @override
  DateTime? get fromDate {
    _$fromDateAtom.reportRead();
    return super.fromDate;
  }

  @override
  set fromDate(DateTime? value) {
    _$fromDateAtom.reportWrite(value, super.fromDate, () {
      super.fromDate = value;
    });
  }

  late final _$toDateAtom =
      Atom(name: '_StatisticsStore.toDate', context: context);

  @override
  DateTime? get toDate {
    _$toDateAtom.reportRead();
    return super.toDate;
  }

  @override
  set toDate(DateTime? value) {
    _$toDateAtom.reportWrite(value, super.toDate, () {
      super.toDate = value;
    });
  }

  late final _$excludeUnnamedStatsAtom =
      Atom(name: '_StatisticsStore.excludeUnnamedStats', context: context);

  @override
  bool? get excludeUnnamedStats {
    _$excludeUnnamedStatsAtom.reportRead();
    return super.excludeUnnamedStats;
  }

  @override
  set excludeUnnamedStats(bool? value) {
    _$excludeUnnamedStatsAtom.reportWrite(value, super.excludeUnnamedStats, () {
      super.excludeUnnamedStats = value;
    });
  }

  late final _$statTypeAtom =
      Atom(name: '_StatisticsStore.statType', context: context);

  @override
  StatType get statType {
    _$statTypeAtom.reportRead();
    return super.statType;
  }

  @override
  set statType(StatType value) {
    _$statTypeAtom.reportWrite(value, super.statType, () {
      super.statType = value;
    });
  }

  late final _$durationFilterAtom =
      Atom(name: '_StatisticsStore.durationFilter', context: context);

  @override
  DurationFilter? get durationFilter {
    _$durationFilterAtom.reportRead();
    return super.durationFilter;
  }

  @override
  set durationFilter(DurationFilter? value) {
    _$durationFilterAtom.reportWrite(value, super.durationFilter, () {
      super.durationFilter = value;
    });
  }

  late final _$durationFilterAmountAtom =
      Atom(name: '_StatisticsStore.durationFilterAmount', context: context);

  @override
  int? get durationFilterAmount {
    _$durationFilterAmountAtom.reportRead();
    return super.durationFilterAmount;
  }

  @override
  set durationFilterAmount(int? value) {
    _$durationFilterAmountAtom.reportWrite(value, super.durationFilterAmount,
        () {
      super.durationFilterAmount = value;
    });
  }

  late final _$durationFilterTimeUnitAtom =
      Atom(name: '_StatisticsStore.durationFilterTimeUnit', context: context);

  @override
  TimeUnit get durationFilterTimeUnit {
    _$durationFilterTimeUnitAtom.reportRead();
    return super.durationFilterTimeUnit;
  }

  @override
  set durationFilterTimeUnit(TimeUnit value) {
    _$durationFilterTimeUnitAtom
        .reportWrite(value, super.durationFilterTimeUnit, () {
      super.durationFilterTimeUnit = value;
    });
  }

  late final _$triggeredDefaultAtom =
      Atom(name: '_StatisticsStore.triggeredDefault', context: context);

  @override
  bool get triggeredDefault {
    _$triggeredDefaultAtom.reportRead();
    return super.triggeredDefault;
  }

  @override
  set triggeredDefault(bool value) {
    _$triggeredDefaultAtom.reportWrite(value, super.triggeredDefault, () {
      super.triggeredDefault = value;
    });
  }

  late final _$_StatisticsStoreActionController =
      ActionController(name: '_StatisticsStore', context: context);

  @override
  void setDefaults() {
    final _$actionInfo = _$_StatisticsStoreActionController.startAction(
        name: '_StatisticsStore.setDefaults');
    try {
      return super.setDefaults();
    } finally {
      _$_StatisticsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setFilterType(FilterType filterType) {
    final _$actionInfo = _$_StatisticsStoreActionController.startAction(
        name: '_StatisticsStore.setFilterType');
    try {
      return super.setFilterType(filterType);
    } finally {
      _$_StatisticsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleFilterOrder() {
    final _$actionInfo = _$_StatisticsStoreActionController.startAction(
        name: '_StatisticsStore.toggleFilterOrder');
    try {
      return super.toggleFilterOrder();
    } finally {
      _$_StatisticsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setAmountStatisticEntries(
      AmountStatisticEntries amountStatisticEntries) {
    final _$actionInfo = _$_StatisticsStoreActionController.startAction(
        name: '_StatisticsStore.setAmountStatisticEntries');
    try {
      return super.setAmountStatisticEntries(amountStatisticEntries);
    } finally {
      _$_StatisticsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setFilterName(String filterName) {
    final _$actionInfo = _$_StatisticsStoreActionController.startAction(
        name: '_StatisticsStore.setFilterName');
    try {
      return super.setFilterName(filterName);
    } finally {
      _$_StatisticsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setShowOnlyFavorites(bool? showOnlyFavorites) {
    final _$actionInfo = _$_StatisticsStoreActionController.startAction(
        name: '_StatisticsStore.setShowOnlyFavorites');
    try {
      return super.setShowOnlyFavorites(showOnlyFavorites);
    } finally {
      _$_StatisticsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setFromDate(DateTime? fromDate) {
    final _$actionInfo = _$_StatisticsStoreActionController.startAction(
        name: '_StatisticsStore.setFromDate');
    try {
      return super.setFromDate(fromDate);
    } finally {
      _$_StatisticsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setToDate(DateTime? toDate) {
    final _$actionInfo = _$_StatisticsStoreActionController.startAction(
        name: '_StatisticsStore.setToDate');
    try {
      return super.setToDate(toDate);
    } finally {
      _$_StatisticsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setExcludeUnnamedStats(bool? excludeUnnamedStats) {
    final _$actionInfo = _$_StatisticsStoreActionController.startAction(
        name: '_StatisticsStore.setExcludeUnnamedStats');
    try {
      return super.setExcludeUnnamedStats(excludeUnnamedStats);
    } finally {
      _$_StatisticsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setStatType(StatType statType) {
    final _$actionInfo = _$_StatisticsStoreActionController.startAction(
        name: '_StatisticsStore.setStatType');
    try {
      return super.setStatType(statType);
    } finally {
      _$_StatisticsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setDurationFilter(DurationFilter? durationFilter) {
    final _$actionInfo = _$_StatisticsStoreActionController.startAction(
        name: '_StatisticsStore.setDurationFilter');
    try {
      return super.setDurationFilter(durationFilter);
    } finally {
      _$_StatisticsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setDurationFilterAmount(String durationFilterAmount) {
    final _$actionInfo = _$_StatisticsStoreActionController.startAction(
        name: '_StatisticsStore.setDurationFilterAmount');
    try {
      return super.setDurationFilterAmount(durationFilterAmount);
    } finally {
      _$_StatisticsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setDurationFilterTimeUnit(TimeUnit durationFilterTimeUnit) {
    final _$actionInfo = _$_StatisticsStoreActionController.startAction(
        name: '_StatisticsStore.setDurationFilterTimeUnit');
    try {
      return super.setDurationFilterTimeUnit(durationFilterTimeUnit);
    } finally {
      _$_StatisticsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
filterType: ${filterType},
filterOrder: ${filterOrder},
amountStatisticEntries: ${amountStatisticEntries},
filterName: ${filterName},
showOnlyFavorites: ${showOnlyFavorites},
fromDate: ${fromDate},
toDate: ${toDate},
excludeUnnamedStats: ${excludeUnnamedStats},
statType: ${statType},
durationFilter: ${durationFilter},
durationFilterAmount: ${durationFilterAmount},
durationFilterTimeUnit: ${durationFilterTimeUnit},
triggeredDefault: ${triggeredDefault},
isFilterSortActive: ${isFilterSortActive}
    ''';
  }
}
