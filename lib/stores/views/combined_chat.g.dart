// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'combined_chat.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$CombinedChatStore on _CombinedChatStore, Store {
  Computed<CombinedCombo?>? _$selectedComboComputed;

  @override
  CombinedCombo? get selectedCombo =>
      (_$selectedComboComputed ??= Computed<CombinedCombo?>(
        () => super.selectedCombo,
        name: '_CombinedChatStore.selectedCombo',
      )).value;
  Computed<List<CombinedSource>>? _$activeSourcesComputed;

  @override
  List<CombinedSource> get activeSources =>
      (_$activeSourcesComputed ??= Computed<List<CombinedSource>>(
        () => super.activeSources,
        name: '_CombinedChatStore.activeSources',
      )).value;
  Computed<List<CombinedSource>>? _$mySourcesComputed;

  @override
  List<CombinedSource> get mySources =>
      (_$mySourcesComputed ??= Computed<List<CombinedSource>>(
        () => super.mySources,
        name: '_CombinedChatStore.mySources',
      )).value;
  Computed<List<CombinedSource>>? _$availableSourcesComputed;

  @override
  List<CombinedSource> get availableSources =>
      (_$availableSourcesComputed ??= Computed<List<CombinedSource>>(
        () => super.availableSources,
        name: '_CombinedChatStore.availableSources',
      )).value;
  Computed<Map<ChatType, CombinedSourceStatus>>? _$sourceStatusComputed;

  @override
  Map<ChatType, CombinedSourceStatus> get sourceStatus =>
      (_$sourceStatusComputed ??= Computed<Map<ChatType, CombinedSourceStatus>>(
        () => super.sourceStatus,
        name: '_CombinedChatStore.sourceStatus',
      )).value;
  Computed<List<CombinedItem>>? _$timelineComputed;

  @override
  List<CombinedItem> get timeline =>
      (_$timelineComputed ??= Computed<List<CombinedItem>>(
        () => super.timeline,
        name: '_CombinedChatStore.timeline',
      )).value;
  Computed<List<ChatType>>? _$writableTargetsComputed;

  @override
  List<ChatType> get writableTargets =>
      (_$writableTargetsComputed ??= Computed<List<ChatType>>(
        () => super.writableTargets,
        name: '_CombinedChatStore.writableTargets',
      )).value;
  Computed<ChatType?>? _$replyPlatformComputed;

  @override
  ChatType? get replyPlatform =>
      (_$replyPlatformComputed ??= Computed<ChatType?>(
        () => super.replyPlatform,
        name: '_CombinedChatStore.replyPlatform',
      )).value;
  Computed<ChatType?>? _$sendTargetComputed;

  @override
  ChatType? get sendTarget => (_$sendTargetComputed ??= Computed<ChatType?>(
    () => super.sendTarget,
    name: '_CombinedChatStore.sendTarget',
  )).value;
  Computed<bool>? _$sendingChatComputed;

  @override
  bool get sendingChat => (_$sendingChatComputed ??= Computed<bool>(
    () => super.sendingChat,
    name: '_CombinedChatStore.sendingChat',
  )).value;
  Computed<String?>? _$sendChatErrorComputed;

  @override
  String? get sendChatError => (_$sendChatErrorComputed ??= Computed<String?>(
    () => super.sendChatError,
    name: '_CombinedChatStore.sendChatError',
  )).value;

  late final _$activeAtom = Atom(
    name: '_CombinedChatStore.active',
    context: context,
  );

  @override
  bool get active {
    _$activeAtom.reportRead();
    return super.active;
  }

  @override
  set active(bool value) {
    _$activeAtom.reportWrite(value, super.active, () {
      super.active = value;
    });
  }

  late final _$disabledPlatformsAtom = Atom(
    name: '_CombinedChatStore.disabledPlatforms',
    context: context,
  );

  @override
  ObservableSet<ChatType> get disabledPlatforms {
    _$disabledPlatformsAtom.reportRead();
    return super.disabledPlatforms;
  }

  @override
  set disabledPlatforms(ObservableSet<ChatType> value) {
    _$disabledPlatformsAtom.reportWrite(value, super.disabledPlatforms, () {
      super.disabledPlatforms = value;
    });
  }

  late final _$selectedComboIdAtom = Atom(
    name: '_CombinedChatStore.selectedComboId',
    context: context,
  );

  @override
  String get selectedComboId {
    _$selectedComboIdAtom.reportRead();
    return super.selectedComboId;
  }

  @override
  set selectedComboId(String value) {
    _$selectedComboIdAtom.reportWrite(value, super.selectedComboId, () {
      super.selectedComboId = value;
    });
  }

  late final _$focusedPlatformAtom = Atom(
    name: '_CombinedChatStore.focusedPlatform',
    context: context,
  );

  @override
  ChatType? get focusedPlatform {
    _$focusedPlatformAtom.reportRead();
    return super.focusedPlatform;
  }

  @override
  set focusedPlatform(ChatType? value) {
    _$focusedPlatformAtom.reportWrite(value, super.focusedPlatform, () {
      super.focusedPlatform = value;
    });
  }

  late final _$sendTargetChoiceAtom = Atom(
    name: '_CombinedChatStore.sendTargetChoice',
    context: context,
  );

  @override
  ChatType? get sendTargetChoice {
    _$sendTargetChoiceAtom.reportRead();
    return super.sendTargetChoice;
  }

  @override
  set sendTargetChoice(ChatType? value) {
    _$sendTargetChoiceAtom.reportWrite(value, super.sendTargetChoice, () {
      super.sendTargetChoice = value;
    });
  }

  late final _$activateAsyncAction = AsyncAction(
    '_CombinedChatStore.activate',
    context: context,
  );

  @override
  Future<void> activate() {
    return _$activateAsyncAction.run(() => super.activate());
  }

  late final _$deactivateAsyncAction = AsyncAction(
    '_CombinedChatStore.deactivate',
    context: context,
  );

  @override
  Future<void> deactivate() {
    return _$deactivateAsyncAction.run(() => super.deactivate());
  }

  late final _$setPlatformEnabledAsyncAction = AsyncAction(
    '_CombinedChatStore.setPlatformEnabled',
    context: context,
  );

  @override
  Future<void> setPlatformEnabled(ChatType platform, bool enabled) {
    return _$setPlatformEnabledAsyncAction.run(
      () => super.setPlatformEnabled(platform, enabled),
    );
  }

  late final _$selectComboAsyncAction = AsyncAction(
    '_CombinedChatStore.selectCombo',
    context: context,
  );

  @override
  Future<void> selectCombo(String comboId) {
    return _$selectComboAsyncAction.run(() => super.selectCombo(comboId));
  }

  late final _$saveComboAsyncAction = AsyncAction(
    '_CombinedChatStore.saveCombo',
    context: context,
  );

  @override
  Future<void> saveCombo(CombinedCombo combo) {
    return _$saveComboAsyncAction.run(() => super.saveCombo(combo));
  }

  late final _$deleteComboAsyncAction = AsyncAction(
    '_CombinedChatStore.deleteCombo',
    context: context,
  );

  @override
  Future<void> deleteCombo(String comboId) {
    return _$deleteComboAsyncAction.run(() => super.deleteCombo(comboId));
  }

  late final _$_CombinedChatStoreActionController = ActionController(
    name: '_CombinedChatStore',
    context: context,
  );

  @override
  void selectSendTarget(ChatType platform) {
    final _$actionInfo = _$_CombinedChatStoreActionController.startAction(
      name: '_CombinedChatStore.selectSendTarget',
    );
    try {
      return super.selectSendTarget(platform);
    } finally {
      _$_CombinedChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setReplyTarget(Object payload) {
    final _$actionInfo = _$_CombinedChatStoreActionController.startAction(
      name: '_CombinedChatStore.setReplyTarget',
    );
    try {
      return super.setReplyTarget(payload);
    } finally {
      _$_CombinedChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearReplyTarget() {
    final _$actionInfo = _$_CombinedChatStoreActionController.startAction(
      name: '_CombinedChatStore.clearReplyTarget',
    );
    try {
      return super.clearReplyTarget();
    } finally {
      _$_CombinedChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void focus(ChatType platform) {
    final _$actionInfo = _$_CombinedChatStoreActionController.startAction(
      name: '_CombinedChatStore.focus',
    );
    try {
      return super.focus(platform);
    } finally {
      _$_CombinedChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void returnToCombined() {
    final _$actionInfo = _$_CombinedChatStoreActionController.startAction(
      name: '_CombinedChatStore.returnToCombined',
    );
    try {
      return super.returnToCombined();
    } finally {
      _$_CombinedChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
active: ${active},
disabledPlatforms: ${disabledPlatforms},
selectedComboId: ${selectedComboId},
focusedPlatform: ${focusedPlatform},
sendTargetChoice: ${sendTargetChoice},
selectedCombo: ${selectedCombo},
activeSources: ${activeSources},
mySources: ${mySources},
availableSources: ${availableSources},
sourceStatus: ${sourceStatus},
timeline: ${timeline},
writableTargets: ${writableTargets},
replyPlatform: ${replyPlatform},
sendTarget: ${sendTarget},
sendingChat: ${sendingChat},
sendChatError: ${sendChatError}
    ''';
  }
}
