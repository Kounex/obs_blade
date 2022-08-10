// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$StatisticsStore on _StatisticsStore, Store {
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

  late final _$excludeUnnamedStreamsAtom =
      Atom(name: '_StatisticsStore.excludeUnnamedStreams', context: context);

  @override
  bool? get excludeUnnamedStreams {
    _$excludeUnnamedStreamsAtom.reportRead();
    return super.excludeUnnamedStreams;
  }

  @override
  set excludeUnnamedStreams(bool? value) {
    _$excludeUnnamedStreamsAtom.reportWrite(value, super.excludeUnnamedStreams,
        () {
      super.excludeUnnamedStreams = value;
    });
  }

  late final _$_StatisticsStoreActionController =
      ActionController(name: '_StatisticsStore', context: context);

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
  void setExcludeUnnamedStreams(bool? excludeUnnamedStreams) {
    final _$actionInfo = _$_StatisticsStoreActionController.startAction(
        name: '_StatisticsStore.setExcludeUnnamedStreams');
    try {
      return super.setExcludeUnnamedStreams(excludeUnnamedStreams);
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
excludeUnnamedStreams: ${excludeUnnamedStreams}
    ''';
  }
}
