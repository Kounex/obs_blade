// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$DashboardStore on _DashboardStore, Store {
  Computed<ObservableList<Input>>? _$currentInputsComputed;

  @override
  ObservableList<Input> get currentInputs => (_$currentInputsComputed ??=
          Computed<ObservableList<Input>>(() => super.currentInputs,
              name: '_DashboardStore.currentInputs'))
      .value;
  Computed<ObservableList<Input>>? _$globalInputsComputed;

  @override
  ObservableList<Input> get globalInputs => (_$globalInputsComputed ??=
          Computed<ObservableList<Input>>(() => super.globalInputs,
              name: '_DashboardStore.globalInputs'))
      .value;

  late final _$isLiveAtom =
      Atom(name: '_DashboardStore.isLive', context: context);

  @override
  bool get isLive {
    _$isLiveAtom.reportRead();
    return super.isLive;
  }

  @override
  set isLive(bool value) {
    _$isLiveAtom.reportWrite(value, super.isLive, () {
      super.isLive = value;
    });
  }

  late final _$isRecordingAtom =
      Atom(name: '_DashboardStore.isRecording', context: context);

  @override
  bool get isRecording {
    _$isRecordingAtom.reportRead();
    return super.isRecording;
  }

  @override
  set isRecording(bool value) {
    _$isRecordingAtom.reportWrite(value, super.isRecording, () {
      super.isRecording = value;
    });
  }

  late final _$isRecordingPausedAtom =
      Atom(name: '_DashboardStore.isRecordingPaused', context: context);

  @override
  bool get isRecordingPaused {
    _$isRecordingPausedAtom.reportRead();
    return super.isRecordingPaused;
  }

  @override
  set isRecordingPaused(bool value) {
    _$isRecordingPausedAtom.reportWrite(value, super.isRecordingPaused, () {
      super.isRecordingPaused = value;
    });
  }

  late final _$isReplayBufferActiveAtom =
      Atom(name: '_DashboardStore.isReplayBufferActive', context: context);

  @override
  bool get isReplayBufferActive {
    _$isReplayBufferActiveAtom.reportRead();
    return super.isReplayBufferActive;
  }

  @override
  set isReplayBufferActive(bool value) {
    _$isReplayBufferActiveAtom.reportWrite(value, super.isReplayBufferActive,
        () {
      super.isReplayBufferActive = value;
    });
  }

  late final _$isVirtualCamActiveAtom =
      Atom(name: '_DashboardStore.isVirtualCamActive', context: context);

  @override
  bool get isVirtualCamActive {
    _$isVirtualCamActiveAtom.reportRead();
    return super.isVirtualCamActive;
  }

  @override
  set isVirtualCamActive(bool value) {
    _$isVirtualCamActiveAtom.reportWrite(value, super.isVirtualCamActive, () {
      super.isVirtualCamActive = value;
    });
  }

  late final _$latestStreamTimeDurationMSAtom = Atom(
      name: '_DashboardStore.latestStreamTimeDurationMS', context: context);

  @override
  int? get latestStreamTimeDurationMS {
    _$latestStreamTimeDurationMSAtom.reportRead();
    return super.latestStreamTimeDurationMS;
  }

  @override
  set latestStreamTimeDurationMS(int? value) {
    _$latestStreamTimeDurationMSAtom
        .reportWrite(value, super.latestStreamTimeDurationMS, () {
      super.latestStreamTimeDurationMS = value;
    });
  }

  late final _$latestRecordTimeDurationMSAtom = Atom(
      name: '_DashboardStore.latestRecordTimeDurationMS', context: context);

  @override
  int? get latestRecordTimeDurationMS {
    _$latestRecordTimeDurationMSAtom.reportRead();
    return super.latestRecordTimeDurationMS;
  }

  @override
  set latestRecordTimeDurationMS(int? value) {
    _$latestRecordTimeDurationMSAtom
        .reportWrite(value, super.latestRecordTimeDurationMS, () {
      super.latestRecordTimeDurationMS = value;
    });
  }

  late final _$streamDataAtom =
      Atom(name: '_DashboardStore.streamData', context: context);

  @override
  PastStreamData? get streamData {
    _$streamDataAtom.reportRead();
    return super.streamData;
  }

  @override
  set streamData(PastStreamData? value) {
    _$streamDataAtom.reportWrite(value, super.streamData, () {
      super.streamData = value;
    });
  }

  late final _$latestStreamStatsAtom =
      Atom(name: '_DashboardStore.latestStreamStats', context: context);

  @override
  StreamStats? get latestStreamStats {
    _$latestStreamStatsAtom.reportRead();
    return super.latestStreamStats;
  }

  @override
  set latestStreamStats(StreamStats? value) {
    _$latestStreamStatsAtom.reportWrite(value, super.latestStreamStats, () {
      super.latestStreamStats = value;
    });
  }

  late final _$recordDataAtom =
      Atom(name: '_DashboardStore.recordData', context: context);

  @override
  PastRecordData? get recordData {
    _$recordDataAtom.reportRead();
    return super.recordData;
  }

  @override
  set recordData(PastRecordData? value) {
    _$recordDataAtom.reportWrite(value, super.recordData, () {
      super.recordData = value;
    });
  }

  late final _$latestRecordStatsAtom =
      Atom(name: '_DashboardStore.latestRecordStats', context: context);

  @override
  RecordStats? get latestRecordStats {
    _$latestRecordStatsAtom.reportRead();
    return super.latestRecordStats;
  }

  @override
  set latestRecordStats(RecordStats? value) {
    _$latestRecordStatsAtom.reportWrite(value, super.latestRecordStats, () {
      super.latestRecordStats = value;
    });
  }

  late final _$latestOBSStatsAtom =
      Atom(name: '_DashboardStore.latestOBSStats', context: context);

  @override
  GetStatsResponse? get latestOBSStats {
    _$latestOBSStatsAtom.reportRead();
    return super.latestOBSStats;
  }

  @override
  set latestOBSStats(GetStatsResponse? value) {
    _$latestOBSStatsAtom.reportWrite(value, super.latestOBSStats, () {
      super.latestOBSStats = value;
    });
  }

  late final _$currentSceneCollectionNameAtom = Atom(
      name: '_DashboardStore.currentSceneCollectionName', context: context);

  @override
  String? get currentSceneCollectionName {
    _$currentSceneCollectionNameAtom.reportRead();
    return super.currentSceneCollectionName;
  }

  @override
  set currentSceneCollectionName(String? value) {
    _$currentSceneCollectionNameAtom
        .reportWrite(value, super.currentSceneCollectionName, () {
      super.currentSceneCollectionName = value;
    });
  }

  late final _$sceneCollectionsAtom =
      Atom(name: '_DashboardStore.sceneCollections', context: context);

  @override
  ObservableList<String>? get sceneCollections {
    _$sceneCollectionsAtom.reportRead();
    return super.sceneCollections;
  }

  @override
  set sceneCollections(ObservableList<String>? value) {
    _$sceneCollectionsAtom.reportWrite(value, super.sceneCollections, () {
      super.sceneCollections = value;
    });
  }

  late final _$activeSceneNameAtom =
      Atom(name: '_DashboardStore.activeSceneName', context: context);

  @override
  String? get activeSceneName {
    _$activeSceneNameAtom.reportRead();
    return super.activeSceneName;
  }

  @override
  set activeSceneName(String? value) {
    _$activeSceneNameAtom.reportWrite(value, super.activeSceneName, () {
      super.activeSceneName = value;
    });
  }

  late final _$scenesAtom =
      Atom(name: '_DashboardStore.scenes', context: context);

  @override
  ObservableList<Scene>? get scenes {
    _$scenesAtom.reportRead();
    return super.scenes;
  }

  @override
  set scenes(ObservableList<Scene>? value) {
    _$scenesAtom.reportWrite(value, super.scenes, () {
      super.scenes = value;
    });
  }

  late final _$currentSceneItemsAtom =
      Atom(name: '_DashboardStore.currentSceneItems', context: context);

  @override
  ObservableList<SceneItem>? get currentSceneItems {
    _$currentSceneItemsAtom.reportRead();
    return super.currentSceneItems;
  }

  @override
  set currentSceneItems(ObservableList<SceneItem>? value) {
    _$currentSceneItemsAtom.reportWrite(value, super.currentSceneItems, () {
      super.currentSceneItems = value;
    });
  }

  late final _$allInputsAtom =
      Atom(name: '_DashboardStore.allInputs', context: context);

  @override
  ObservableList<Input> get allInputs {
    _$allInputsAtom.reportRead();
    return super.allInputs;
  }

  @override
  set allInputs(ObservableList<Input> value) {
    _$allInputsAtom.reportWrite(value, super.allInputs, () {
      super.allInputs = value;
    });
  }

  late final _$globalInputNamesAtom =
      Atom(name: '_DashboardStore.globalInputNames', context: context);

  @override
  ObservableList<String> get globalInputNames {
    _$globalInputNamesAtom.reportRead();
    return super.globalInputNames;
  }

  @override
  set globalInputNames(ObservableList<String> value) {
    _$globalInputNamesAtom.reportWrite(value, super.globalInputNames, () {
      super.globalInputNames = value;
    });
  }

  late final _$currentTransitionAtom =
      Atom(name: '_DashboardStore.currentTransition', context: context);

  @override
  Transition? get currentTransition {
    _$currentTransitionAtom.reportRead();
    return super.currentTransition;
  }

  @override
  set currentTransition(Transition? value) {
    _$currentTransitionAtom.reportWrite(value, super.currentTransition, () {
      super.currentTransition = value;
    });
  }

  late final _$availableTransitionsAtom =
      Atom(name: '_DashboardStore.availableTransitions', context: context);

  @override
  List<Transition>? get availableTransitions {
    _$availableTransitionsAtom.reportRead();
    return super.availableTransitions;
  }

  @override
  set availableTransitions(List<Transition>? value) {
    _$availableTransitionsAtom.reportWrite(value, super.availableTransitions,
        () {
      super.availableTransitions = value;
    });
  }

  late final _$shouldRequestPreviewImageAtom =
      Atom(name: '_DashboardStore.shouldRequestPreviewImage', context: context);

  @override
  bool get shouldRequestPreviewImage {
    _$shouldRequestPreviewImageAtom.reportRead();
    return super.shouldRequestPreviewImage;
  }

  @override
  set shouldRequestPreviewImage(bool value) {
    _$shouldRequestPreviewImageAtom
        .reportWrite(value, super.shouldRequestPreviewImage, () {
      super.shouldRequestPreviewImage = value;
    });
  }

  late final _$scenePreviewImageBytesAtom =
      Atom(name: '_DashboardStore.scenePreviewImageBytes', context: context);

  @override
  Uint8List? get scenePreviewImageBytes {
    _$scenePreviewImageBytesAtom.reportRead();
    return super.scenePreviewImageBytes;
  }

  @override
  set scenePreviewImageBytes(Uint8List? value) {
    _$scenePreviewImageBytesAtom
        .reportWrite(value, super.scenePreviewImageBytes, () {
      super.scenePreviewImageBytes = value;
    });
  }

  late final _$isPointerOnChatAtom =
      Atom(name: '_DashboardStore.isPointerOnChat', context: context);

  @override
  bool get isPointerOnChat {
    _$isPointerOnChatAtom.reportRead();
    return super.isPointerOnChat;
  }

  @override
  set isPointerOnChat(bool value) {
    _$isPointerOnChatAtom.reportWrite(value, super.isPointerOnChat, () {
      super.isPointerOnChat = value;
    });
  }

  late final _$reconnectingAtom =
      Atom(name: '_DashboardStore.reconnecting', context: context);

  @override
  bool get reconnecting {
    _$reconnectingAtom.reportRead();
    return super.reconnecting;
  }

  @override
  set reconnecting(bool value) {
    _$reconnectingAtom.reportWrite(value, super.reconnecting, () {
      super.reconnecting = value;
    });
  }

  late final _$editSceneItemVisibilityAtom =
      Atom(name: '_DashboardStore.editSceneItemVisibility', context: context);

  @override
  bool get editSceneItemVisibility {
    _$editSceneItemVisibilityAtom.reportRead();
    return super.editSceneItemVisibility;
  }

  @override
  set editSceneItemVisibility(bool value) {
    _$editSceneItemVisibilityAtom
        .reportWrite(value, super.editSceneItemVisibility, () {
      super.editSceneItemVisibility = value;
    });
  }

  late final _$editAudioVisibilityAtom =
      Atom(name: '_DashboardStore.editAudioVisibility', context: context);

  @override
  bool get editAudioVisibility {
    _$editAudioVisibilityAtom.reportRead();
    return super.editAudioVisibility;
  }

  @override
  set editAudioVisibility(bool value) {
    _$editAudioVisibilityAtom.reportWrite(value, super.editAudioVisibility, () {
      super.editAudioVisibility = value;
    });
  }

  late final _$studioModeAtom =
      Atom(name: '_DashboardStore.studioMode', context: context);

  @override
  bool get studioMode {
    _$studioModeAtom.reportRead();
    return super.studioMode;
  }

  @override
  set studioMode(bool value) {
    _$studioModeAtom.reportWrite(value, super.studioMode, () {
      super.studioMode = value;
    });
  }

  late final _$studioModePreviewSceneNameAtom = Atom(
      name: '_DashboardStore.studioModePreviewSceneName', context: context);

  @override
  String? get studioModePreviewSceneName {
    _$studioModePreviewSceneNameAtom.reportRead();
    return super.studioModePreviewSceneName;
  }

  @override
  set studioModePreviewSceneName(String? value) {
    _$studioModePreviewSceneNameAtom
        .reportWrite(value, super.studioModePreviewSceneName, () {
      super.studioModePreviewSceneName = value;
    });
  }

  late final _$editSceneVisibilityAtom =
      Atom(name: '_DashboardStore.editSceneVisibility', context: context);

  @override
  bool get editSceneVisibility {
    _$editSceneVisibilityAtom.reportRead();
    return super.editSceneVisibility;
  }

  @override
  set editSceneVisibility(bool value) {
    _$editSceneVisibilityAtom.reportWrite(value, super.editSceneVisibility, () {
      super.editSceneVisibility = value;
    });
  }

  late final _$_checkOBSConnectionAsyncAction =
      AsyncAction('_DashboardStore._checkOBSConnection', context: context);

  @override
  Future<void> _checkOBSConnection() {
    return _$_checkOBSConnectionAsyncAction
        .run(() => super._checkOBSConnection());
  }

  late final _$_handleEventAsyncAction =
      AsyncAction('_DashboardStore._handleEvent', context: context);

  @override
  Future<void> _handleEvent(BaseEvent event) {
    return _$_handleEventAsyncAction.run(() => super._handleEvent(event));
  }

  late final _$_handleBatchResponseAsyncAction =
      AsyncAction('_DashboardStore._handleBatchResponse', context: context);

  @override
  Future<void> _handleBatchResponse(BaseBatchResponse batchResponse) {
    return _$_handleBatchResponseAsyncAction
        .run(() => super._handleBatchResponse(batchResponse));
  }

  late final _$_DashboardStoreActionController =
      ActionController(name: '_DashboardStore', context: context);

  @override
  void init() {
    final _$actionInfo = _$_DashboardStoreActionController.startAction(
        name: '_DashboardStore.init');
    try {
      return super.init();
    } finally {
      _$_DashboardStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setShouldRequestPreviewImage(bool shouldRequestPreviewImage) {
    final _$actionInfo = _$_DashboardStoreActionController.startAction(
        name: '_DashboardStore.setShouldRequestPreviewImage');
    try {
      return super.setShouldRequestPreviewImage(shouldRequestPreviewImage);
    } finally {
      _$_DashboardStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPointerOnChat(bool isPointerOnChat) {
    final _$actionInfo = _$_DashboardStoreActionController.startAction(
        name: '_DashboardStore.setPointerOnChat');
    try {
      return super.setPointerOnChat(isPointerOnChat);
    } finally {
      _$_DashboardStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleSceneItemGroupVisibility(SceneItem sceneItem) {
    final _$actionInfo = _$_DashboardStoreActionController.startAction(
        name: '_DashboardStore.toggleSceneItemGroupVisibility');
    try {
      return super.toggleSceneItemGroupVisibility(sceneItem);
    } finally {
      _$_DashboardStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setEditSceneItemVisibility(bool editSceneItemVisibility) {
    final _$actionInfo = _$_DashboardStoreActionController.startAction(
        name: '_DashboardStore.setEditSceneItemVisibility');
    try {
      return super.setEditSceneItemVisibility(editSceneItemVisibility);
    } finally {
      _$_DashboardStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setEditAudioVisibility(bool editAudioVisibility) {
    final _$actionInfo = _$_DashboardStoreActionController.startAction(
        name: '_DashboardStore.setEditAudioVisibility');
    try {
      return super.setEditAudioVisibility(editAudioVisibility);
    } finally {
      _$_DashboardStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setEditSceneVisibility(bool editSceneVisibility) {
    final _$actionInfo = _$_DashboardStoreActionController.startAction(
        name: '_DashboardStore.setEditSceneVisibility');
    try {
      return super.setEditSceneVisibility(editSceneVisibility);
    } finally {
      _$_DashboardStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setActiveSceneName(String activeSceneName) {
    final _$actionInfo = _$_DashboardStoreActionController.startAction(
        name: '_DashboardStore.setActiveSceneName');
    try {
      return super.setActiveSceneName(activeSceneName);
    } finally {
      _$_DashboardStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setStudioModePreviewSceneName(String studioModePreviewSceneName) {
    final _$actionInfo = _$_DashboardStoreActionController.startAction(
        name: '_DashboardStore.setStudioModePreviewSceneName');
    try {
      return super.setStudioModePreviewSceneName(studioModePreviewSceneName);
    } finally {
      _$_DashboardStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _handleResponse(BaseResponse response) {
    final _$actionInfo = _$_DashboardStoreActionController.startAction(
        name: '_DashboardStore._handleResponse');
    try {
      return super._handleResponse(response);
    } finally {
      _$_DashboardStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLive: ${isLive},
isRecording: ${isRecording},
isRecordingPaused: ${isRecordingPaused},
isReplayBufferActive: ${isReplayBufferActive},
isVirtualCamActive: ${isVirtualCamActive},
latestStreamTimeDurationMS: ${latestStreamTimeDurationMS},
latestRecordTimeDurationMS: ${latestRecordTimeDurationMS},
streamData: ${streamData},
latestStreamStats: ${latestStreamStats},
recordData: ${recordData},
latestRecordStats: ${latestRecordStats},
latestOBSStats: ${latestOBSStats},
currentSceneCollectionName: ${currentSceneCollectionName},
sceneCollections: ${sceneCollections},
activeSceneName: ${activeSceneName},
scenes: ${scenes},
currentSceneItems: ${currentSceneItems},
allInputs: ${allInputs},
globalInputNames: ${globalInputNames},
currentTransition: ${currentTransition},
availableTransitions: ${availableTransitions},
shouldRequestPreviewImage: ${shouldRequestPreviewImage},
scenePreviewImageBytes: ${scenePreviewImageBytes},
isPointerOnChat: ${isPointerOnChat},
reconnecting: ${reconnecting},
editSceneItemVisibility: ${editSceneItemVisibility},
editAudioVisibility: ${editAudioVisibility},
studioMode: ${studioMode},
studioModePreviewSceneName: ${studioModePreviewSceneName},
editSceneVisibility: ${editSceneVisibility},
currentInputs: ${currentInputs},
globalInputs: ${globalInputs}
    ''';
  }
}
