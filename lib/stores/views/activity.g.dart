// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ActivityStore on _ActivityStore, Store {
  Computed<List<ActivityEvent>>? _$allEventsComputed;

  @override
  List<ActivityEvent> get allEvents =>
      (_$allEventsComputed ??= Computed<List<ActivityEvent>>(
        () => super.allEvents,
        name: '_ActivityStore.allEvents',
      )).value;
  Computed<int>? _$unseenCountComputed;

  @override
  int get unseenCount => (_$unseenCountComputed ??= Computed<int>(
    () => super.unseenCount,
    name: '_ActivityStore.unseenCount',
  )).value;
  Computed<int>? _$toThankCountComputed;

  @override
  int get toThankCount => (_$toThankCountComputed ??= Computed<int>(
    () => super.toThankCount,
    name: '_ActivityStore.toThankCount',
  )).value;
  Computed<List<ActivityEvent>>? _$visibleEventsComputed;

  @override
  List<ActivityEvent> get visibleEvents =>
      (_$visibleEventsComputed ??= Computed<List<ActivityEvent>>(
        () => super.visibleEvents,
        name: '_ActivityStore.visibleEvents',
      )).value;
  Computed<List<ActivityGroup>>? _$groupsComputed;

  @override
  List<ActivityGroup> get groups =>
      (_$groupsComputed ??= Computed<List<ActivityGroup>>(
        () => super.groups,
        name: '_ActivityStore.groups',
      )).value;

  late final _$youTubeOwnStateAtom = Atom(
    name: '_ActivityStore.youTubeOwnState',
    context: context,
  );

  @override
  YouTubeOwnActivityState get youTubeOwnState {
    _$youTubeOwnStateAtom.reportRead();
    return super.youTubeOwnState;
  }

  @override
  set youTubeOwnState(YouTubeOwnActivityState value) {
    _$youTubeOwnStateAtom.reportWrite(value, super.youTubeOwnState, () {
      super.youTubeOwnState = value;
    });
  }

  late final _$youTubeQuotaResetAtAtom = Atom(
    name: '_ActivityStore.youTubeQuotaResetAt',
    context: context,
  );

  @override
  DateTime? get youTubeQuotaResetAt {
    _$youTubeQuotaResetAtAtom.reportRead();
    return super.youTubeQuotaResetAt;
  }

  @override
  set youTubeQuotaResetAt(DateTime? value) {
    _$youTubeQuotaResetAtAtom.reportWrite(value, super.youTubeQuotaResetAt, () {
      super.youTubeQuotaResetAt = value;
    });
  }

  late final _$obsLiveAtom = Atom(
    name: '_ActivityStore.obsLive',
    context: context,
  );

  @override
  bool get obsLive {
    _$obsLiveAtom.reportRead();
    return super.obsLive;
  }

  @override
  set obsLive(bool value) {
    _$obsLiveAtom.reportWrite(value, super.obsLive, () {
      super.obsLive = value;
    });
  }

  late final _$obsLivePlatformAtom = Atom(
    name: '_ActivityStore.obsLivePlatform',
    context: context,
  );

  @override
  ActivityPlatform? get obsLivePlatform {
    _$obsLivePlatformAtom.reportRead();
    return super.obsLivePlatform;
  }

  @override
  set obsLivePlatform(ActivityPlatform? value) {
    _$obsLivePlatformAtom.reportWrite(value, super.obsLivePlatform, () {
      super.obsLivePlatform = value;
    });
  }

  late final _$revisionAtom = Atom(
    name: '_ActivityStore.revision',
    context: context,
  );

  @override
  int get revision {
    _$revisionAtom.reportRead();
    return super.revision;
  }

  @override
  set revision(int value) {
    _$revisionAtom.reportWrite(value, super.revision, () {
      super.revision = value;
    });
  }

  late final _$loadedAtom = Atom(
    name: '_ActivityStore.loaded',
    context: context,
  );

  @override
  bool get loaded {
    _$loadedAtom.reportRead();
    return super.loaded;
  }

  @override
  set loaded(bool value) {
    _$loadedAtom.reportWrite(value, super.loaded, () {
      super.loaded = value;
    });
  }

  late final _$visitMarksAtom = Atom(
    name: '_ActivityStore.visitMarks',
    context: context,
  );

  @override
  ObservableMap<String, int>? get visitMarks {
    _$visitMarksAtom.reportRead();
    return super.visitMarks;
  }

  @override
  set visitMarks(ObservableMap<String, int>? value) {
    _$visitMarksAtom.reportWrite(value, super.visitMarks, () {
      super.visitMarks = value;
    });
  }

  late final _$filterAtom = Atom(
    name: '_ActivityStore.filter',
    context: context,
  );

  @override
  ActivityFilter get filter {
    _$filterAtom.reportRead();
    return super.filter;
  }

  @override
  set filter(ActivityFilter value) {
    _$filterAtom.reportWrite(value, super.filter, () {
      super.filter = value;
    });
  }

  late final _$toThankOnlyAtom = Atom(
    name: '_ActivityStore.toThankOnly',
    context: context,
  );

  @override
  bool get toThankOnly {
    _$toThankOnlyAtom.reportRead();
    return super.toThankOnly;
  }

  @override
  set toThankOnly(bool value) {
    _$toThankOnlyAtom.reportWrite(value, super.toThankOnly, () {
      super.toThankOnly = value;
    });
  }

  late final _$relayStateAtom = Atom(
    name: '_ActivityStore.relayState',
    context: context,
  );

  @override
  KickRelayState get relayState {
    _$relayStateAtom.reportRead();
    return super.relayState;
  }

  @override
  set relayState(KickRelayState value) {
    _$relayStateAtom.reportWrite(value, super.relayState, () {
      super.relayState = value;
    });
  }

  late final _$relaySubscribedAtom = Atom(
    name: '_ActivityStore.relaySubscribed',
    context: context,
  );

  @override
  bool get relaySubscribed {
    _$relaySubscribedAtom.reportRead();
    return super.relaySubscribed;
  }

  @override
  set relaySubscribed(bool value) {
    _$relaySubscribedAtom.reportWrite(value, super.relaySubscribed, () {
      super.relaySubscribed = value;
    });
  }

  late final _$coverageRevisionAtom = Atom(
    name: '_ActivityStore.coverageRevision',
    context: context,
  );

  @override
  int get coverageRevision {
    _$coverageRevisionAtom.reportRead();
    return super.coverageRevision;
  }

  @override
  set coverageRevision(int value) {
    _$coverageRevisionAtom.reportWrite(value, super.coverageRevision, () {
      super.coverageRevision = value;
    });
  }

  late final _$clockTickAtom = Atom(
    name: '_ActivityStore.clockTick',
    context: context,
  );

  @override
  int get clockTick {
    _$clockTickAtom.reportRead();
    return super.clockTick;
  }

  @override
  set clockTick(int value) {
    _$clockTickAtom.reportWrite(value, super.clockTick, () {
      super.clockTick = value;
    });
  }

  late final _$setupRevisionAtom = Atom(
    name: '_ActivityStore.setupRevision',
    context: context,
  );

  @override
  int get setupRevision {
    _$setupRevisionAtom.reportRead();
    return super.setupRevision;
  }

  @override
  set setupRevision(int value) {
    _$setupRevisionAtom.reportWrite(value, super.setupRevision, () {
      super.setupRevision = value;
    });
  }

  late final _$clearHistoryAsyncAction = AsyncAction(
    '_ActivityStore.clearHistory',
    context: context,
  );

  @override
  Future<void> clearHistory() {
    return _$clearHistoryAsyncAction.run(() => super.clearHistory());
  }

  late final _$_ActivityStoreActionController = ActionController(
    name: '_ActivityStore',
    context: context,
  );

  @override
  void ingest(ActivityEvent event) {
    final _$actionInfo = _$_ActivityStoreActionController.startAction(
      name: '_ActivityStore.ingest',
    );
    try {
      return super.ingest(event);
    } finally {
      _$_ActivityStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _syncSession({DateTime? endedAt}) {
    final _$actionInfo = _$_ActivityStoreActionController.startAction(
      name: '_ActivityStore._syncSession',
    );
    try {
      return super._syncSession(endedAt: endedAt);
    } finally {
      _$_ActivityStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void markAllSeen() {
    final _$actionInfo = _$_ActivityStoreActionController.startAction(
      name: '_ActivityStore.markAllSeen',
    );
    try {
      return super.markAllSeen();
    } finally {
      _$_ActivityStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void beginVisit() {
    final _$actionInfo = _$_ActivityStoreActionController.startAction(
      name: '_ActivityStore.beginVisit',
    );
    try {
      return super.beginVisit();
    } finally {
      _$_ActivityStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void endVisit() {
    final _$actionInfo = _$_ActivityStoreActionController.startAction(
      name: '_ActivityStore.endVisit',
    );
    try {
      return super.endVisit();
    } finally {
      _$_ActivityStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setThanked(ActivityEvent event, bool thanked) {
    final _$actionInfo = _$_ActivityStoreActionController.startAction(
      name: '_ActivityStore.setThanked',
    );
    try {
      return super.setThanked(event, thanked);
    } finally {
      _$_ActivityStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void acknowledgeStatus(Iterable<String> ids) {
    final _$actionInfo = _$_ActivityStoreActionController.startAction(
      name: '_ActivityStore.acknowledgeStatus',
    );
    try {
      return super.acknowledgeStatus(ids);
    } finally {
      _$_ActivityStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void markThanked(Iterable<ActivityEvent> events) {
    final _$actionInfo = _$_ActivityStoreActionController.startAction(
      name: '_ActivityStore.markThanked',
    );
    try {
      return super.markThanked(events);
    } finally {
      _$_ActivityStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setFilter(ActivityFilter filter) {
    final _$actionInfo = _$_ActivityStoreActionController.startAction(
      name: '_ActivityStore.setFilter',
    );
    try {
      return super.setFilter(filter);
    } finally {
      _$_ActivityStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setToThankOnly(bool value) {
    final _$actionInfo = _$_ActivityStoreActionController.startAction(
      name: '_ActivityStore.setToThankOnly',
    );
    try {
      return super.setToThankOnly(value);
    } finally {
      _$_ActivityStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
youTubeOwnState: ${youTubeOwnState},
youTubeQuotaResetAt: ${youTubeQuotaResetAt},
obsLive: ${obsLive},
obsLivePlatform: ${obsLivePlatform},
revision: ${revision},
loaded: ${loaded},
visitMarks: ${visitMarks},
filter: ${filter},
toThankOnly: ${toThankOnly},
relayState: ${relayState},
relaySubscribed: ${relaySubscribed},
coverageRevision: ${coverageRevision},
clockTick: ${clockTick},
setupRevision: ${setupRevision},
allEvents: ${allEvents},
unseenCount: ${unseenCount},
toThankCount: ${toThankCount},
visibleEvents: ${visibleEvents},
groups: ${groups}
    ''';
  }
}
