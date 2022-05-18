import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/types/classes/stream/responses/get_replay_buffer_status.dart';

import '../../models/enums/log_level.dart';
import '../../models/past_stream_data.dart';
import '../../types/classes/api/scene.dart';
import '../../types/classes/api/scene_collection.dart';
import '../../types/classes/api/scene_item.dart';
import '../../types/classes/api/source_type.dart';
import '../../types/classes/api/stream_stats.dart';
import '../../types/classes/stream/events/base.dart';
import '../../types/classes/stream/events/preview_scene_changed.dart';
import '../../types/classes/stream/events/scene_collection_changed.dart';
import '../../types/classes/stream/events/scene_collection_list_changed.dart';
import '../../types/classes/stream/events/scene_item_removed.dart';
import '../../types/classes/stream/events/scene_item_visibility_changed.dart';
import '../../types/classes/stream/events/source_mute_state_changed.dart';
import '../../types/classes/stream/events/source_renamed.dart';
import '../../types/classes/stream/events/source_volume_changed.dart';
import '../../types/classes/stream/events/studio_mode_switched.dart';
import '../../types/classes/stream/events/switch_scenes.dart';
import '../../types/classes/stream/events/switch_transition.dart';
import '../../types/classes/stream/events/transition_begin.dart';
import '../../types/classes/stream/events/transition_duration_changed.dart';
import '../../types/classes/stream/events/transition_list_changed.dart';
import '../../types/classes/stream/responses/base.dart';
import '../../types/classes/stream/responses/get_current_scene.dart';
import '../../types/classes/stream/responses/get_current_scene_collection.dart';
import '../../types/classes/stream/responses/get_current_transition.dart';
import '../../types/classes/stream/responses/get_mute.dart';
import '../../types/classes/stream/responses/get_preview_scene.dart';
import '../../types/classes/stream/responses/get_recording_status.dart';
import '../../types/classes/stream/responses/get_scene_list.dart';
import '../../types/classes/stream/responses/get_source_types_list.dart';
import '../../types/classes/stream/responses/get_special_sources.dart';
import '../../types/classes/stream/responses/get_studio_mode_status.dart';
import '../../types/classes/stream/responses/get_transition_list.dart';
import '../../types/classes/stream/responses/get_version.dart';
import '../../types/classes/stream/responses/get_volume.dart';
import '../../types/classes/stream/responses/list_scene_collections.dart';
import '../../types/classes/stream/responses/take_source_screenshot.dart';
import '../../types/enums/event_type.dart';
import '../../types/enums/hive_keys.dart';
import '../../types/enums/request_type.dart';
import '../../types/enums/settings_keys.dart';
import '../../utils/general_helper.dart';
import '../../utils/network_helper.dart';
import '../../utils/overlay_handler.dart';
import '../shared/network.dart';

part 'dashboard.g.dart';

class DashboardStore = _DashboardStore with _$DashboardStore;

abstract class _DashboardStore with Store {
  @observable
  bool isLive = false;
  @observable
  bool isRecording = false;
  @observable
  bool isRecordingPaused = false;
  @observable
  bool isReplayBufferActive = false;
  @observable
  int? latestStreamTimeDurationMS;
  @observable
  int? latestRecordTimeDurationMS;
  @observable
  PastStreamData? streamData;
  @observable
  StreamStats? latestStreamStats;

  @observable
  String? currentSceneCollectionName;
  @observable
  ObservableList<SceneCollection>? sceneCollections;
  @observable
  String? activeSceneName;
  @observable
  ObservableList<Scene>? scenes;

  /// WebSocket API will return all top level scene items for
  /// the current scene and elements of groups are inside the
  /// separate [SceneItem.groupChildren]. To better maintain and work
  /// with scene items, I flatten these so all scene items, even
  /// the children of groups are on top level and a custom
  /// [SceneItem.displayGroup] propertry toggles whether they
  /// will be displayed or not, but this makes searching and
  /// updating scene items easier
  @observable
  ObservableList<SceneItem>? currentSceneItems;

  /// Not used currently as the WebSocket API does not expose working
  /// with such sources (playing, stopping, etc.) right now. This will likely
  /// be supported in the near future which therefore enables Soundboard support!
  @computed
  ObservableList<SceneItem> get currentSoundboardSceneItems =>
      this.currentSceneItems != null
          ? ObservableList.of(this.currentSceneItems!.where((sceneItem) =>
              sceneItem.type == 'ffmpeg_source' && sceneItem.render!))
          : ObservableList();

  /// [SceneItem] works as the master object for all kind of sources
  /// inside a scene. Therefore "special" kind of scene items like audio sources
  /// are computed from the master list [currentSceneItems] of the current active
  /// scene
  @computed
  ObservableList<SceneItem> get currentAudioSceneItems =>
      this.currentSceneItems != null
          ? ObservableList.of(currentSceneItems!.where((sceneItem) => this
              .sourceTypes!
              .any((sourceType) =>
                  sourceType.caps.hasAudio &&
                  sourceType.typeID == sceneItem.type)))
          : ObservableList();

  /// "Special" Audio sources produced by global entities like Desktop or Mic
  @observable
  ObservableList<SceneItem> globalAudioSceneItems = ObservableList();

  @observable
  String? currentTransitionName;

  @observable
  int? sceneTransitionDurationMS;

  @observable
  List<String>? availableTransitionsNames;

  /// Indicates whether the the [requestPreviewImage] method should be called.
  /// Will do so as long as it stays true and stops once its false again
  @observable
  bool shouldRequestPreviewImage = false;

  /// Will hold the current image (screenshot) for the active scene - will be
  /// set and updated as fast as possible with new screenshots while [shouldRequestPreviewImage]
  /// is true and will therefore be used as the workaround of a live preview of the
  /// active scene
  @observable
  Uint8List? scenePreviewImageBytes;

  /// Checks whether the user is trying to scroll while the pointer (finger) is
  /// on the chat - this means the user probably wants to scroll the chat.
  /// If the user wants to scroll inside the app, the pointer (finger) may not
  /// be on the chat but above or underneath (UI wise)
  @observable
  bool isPointerOnChat = false;

  /// Indicator (which is used in [_checkOBSConnection]) whether we attempt a
  /// reconnect since the WebSocket connection closed. Can and is currently listened
  /// to in [ReconnectToast] to show the user that a reconnect attempt is ongoing
  @observable
  bool reconnecting = false;

  /// Toggles the visibility of the hide/show sliding pane of the scene items
  @observable
  bool editSceneItemVisibility = false;

  /// Toggles the visibility of the hide/show sliding pane of the audios
  @observable
  bool editAudioVisibility = false;

  /// Whether studio mode is active
  @observable
  bool studioMode = false;

  /// Currently selected preview scene (only in studio mode)
  @observable
  String? studioModePreviewSceneName;

  @observable
  bool editSceneVisibility = false;

  List<SourceType>? sourceTypes;

  Timer? checkConnectionTimer;

  String previewFileFormat = 'jpeg';

  /// Will be used internally while switching scene collections.
  /// Since this operation takes time and "random" events are coming
  /// in while we dont even have all the new information from the
  /// new scene collection, we need to stop handling those events /requests
  /// while waiting until we actually changed the scene collection
  /// (getting the response from [SetCurrentSceneCollection]) and then
  /// call [sceneCollectionRequests]
  bool handleRequestsEvents = true;

  /// Set of initial requests to call in order to get all the basic
  /// information / configuration for the OBS session
  void initialRequests() {
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetVersion,
    );
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.ListSceneCollections,
    );
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetCurrentSceneCollection,
    );
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetStudioModeStatus,
    );
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetRecordingStatus,
    );
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetReplayBufferStatus,
    );

    sceneCollectionRequests();
    // NetworkHelper.makeRequest(
    //     this.networkStore.activeSession.socket, RequestType.GetSourcesList);
    // NetworkHelper.makeRequest(
    //     this.networkStore.activeSession.socket, RequestType.ListOutputs);
  }

  /// Requests dedicated to get all the information from the current
  /// scene collection (can be called independently after switching the
  /// scene collection or if we want to refresh the information for the
  /// current scene collection)
  void sceneCollectionRequests() {
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetSceneList,
    );
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetSourceTypesList,
    );
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetTransitionList,
    );
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetCurrentTransition,
    );
  }

  void handleStream() {
    GetIt.instance<NetworkStore>().watchOBSStream().listen((message) {
      if (handleRequestsEvents ||
          (message is BaseEvent &&
              message.eventType == EventType.SceneCollectionChanged)) {
        if (message is BaseEvent) {
          _handleEvent(message);
        } else {
          _handleResponse(message as BaseResponse);
        }
      }
    });
  }

  void requestPreviewImage() => NetworkHelper.makeRequest(
        GetIt.instance<NetworkStore>().activeSession!.socket,
        RequestType.TakeSourceScreenshot,
        {
          'sourceName': Hive.box(HiveKeys.Settings.name).get(
                      SettingsKeys.ExposeStudioControls.name,
                      defaultValue: false) &&
                  this.studioMode
              ? this.studioModePreviewSceneName
              : this.activeSceneName,
          'embedPictureFormat': this.previewFileFormat,
          'compressionQuality': -1,
        },
      );

  /// Check if we have ongoing statistics (!= null) and set it
  /// to null to indicate that we are done with this one and can start
  /// a new one
  Future<void> finishPastStreamData() async {
    if (this.streamData != null) {
      /// Check if [streamData] is even "legit" - if [totalStreamTime]
      /// is not greater than 0, it's not worth the statistic entry and
      /// will probably cause problems anyway. We will delete it therefore
      if (this.streamData!.isInBox &&
          (this.streamData!.totalStreamTime == null ||
              this.streamData!.totalStreamTime! <= 0)) {
        await this.streamData!.delete();
      }
      this.streamData = null;
    }
  }

  /// SceneItems which type is 'group' can have children which are
  /// SceneItems again - this would lead to checking those children
  /// in many cases (a lot of work and extra code). So instead I flatten
  /// this by adding those children to the general list and since
  /// those children have their parent name as a property I can easily
  /// identify them in the flat list
  List<SceneItem> _flattenSceneItems(Iterable<SceneItem> sceneItems) {
    List<SceneItem> tmpSceneItems = [];
    for (var sceneItem in sceneItems) {
      tmpSceneItems.add(sceneItem);
      if (sceneItem.groupChildren != null &&
          sceneItem.groupChildren!.isNotEmpty) {
        tmpSceneItems.addAll(sceneItem.groupChildren!);
      }
    }
    return tmpSceneItems;
  }

  /// If we get a [StreamStatus] event and we have no [PastStreamData]
  /// instance (null) we need to check if we create a completely new
  /// instance (indicating new stream) or we use the last one since it
  /// seems as this is the same stream we already were connected to
  Future<void> _manageStreamDataInit() async {
    Box<PastStreamData> pastStreamDataBox =
        Hive.box<PastStreamData>(HiveKeys.PastStreamData.name);
    List<PastStreamData> tmp = pastStreamDataBox.values.toList();

    /// Sort ascending so the last entry is the latest stream
    tmp.sort((a, b) => a.listEntryDateMS.last - b.listEntryDateMS.last);

    /// Check if the latest stream has its last entry (based on [listEntryDateMS]
    ///  set later than current time - [totalStreamTime] which means that we
    /// connected to an OBS session we already were connected to
    if (tmp.isNotEmpty &&
        DateTime.now().millisecondsSinceEpoch -
                this.latestStreamStats!.totalStreamTime * 1000 <=
            tmp.last.listEntryDateMS.last) {
      this.streamData = tmp.last;
    } else {
      this.streamData = PastStreamData();
      await pastStreamDataBox.add(this.streamData!);
    }
  }

  int? _timecodeToMS(String? timecode) {
    if (timecode != null) {
      List<String> recTimeFragments = timecode.split(':');

      return Duration(
        hours: int.parse(recTimeFragments[0]),
        minutes: int.parse(recTimeFragments[1]),
        seconds: int.parse(recTimeFragments[2].split('.')[0]),
      ).inMilliseconds;
    }
    return null;
  }

  @action
  void init() {
    this.handleStream();
    this.initialRequests();

    /// Since [setupNetworkStoreHandling] gets called as soon as we connect
    /// to an OBS instance, we trigger this [Timer] which will check if
    /// the connection is still alive periodically - see [_checkOBSConnection]
    /// for more information
    this.checkConnectionTimer = Timer(
      const Duration(seconds: 5),
      () => _checkOBSConnection(),
    );
  }

  /// While using the device this app is running on while connected to an OBS
  /// instance, it may happen that we lose the connection due to OS background
  /// behaviour or because we lose network connection or other reasons. This function
  /// intents to check if the connection (in this case a WebSocket connection) is
  /// still active (no [closeCode] present) - if so, we try to establish a new connection.
  /// If we still have a [closeCode] after trying to establish a new connection, we
  /// set the [obsTerminated] flag to initiate that we can't reach OBS anymore and
  /// we get back to our [HomeView]
  @action
  Future<void> _checkOBSConnection() async {
    if (GetIt.instance<NetworkStore>().activeSession?.socket.closeCode !=
            null &&
        !GetIt.instance<NetworkStore>().obsTerminated) {
      this.reconnecting = true;
      BaseResponse? response;
      int tries = 0;

      GeneralHelper.advLog(
        'Lost active connection to OBS, trying to reconnect',
        level: LogLevel.Warning,
        includeInLogs: true,
      );

      while ((Hive.box(HiveKeys.Settings.name).get(
                  SettingsKeys.UnlimitedReconnects.name,
                  defaultValue: false) ||
              tries < 5) &&
          response?.status != BaseResponse.ok) {
        response = await GetIt.instance<NetworkStore>().setOBSWebSocket(
          GetIt.instance<NetworkStore>().activeSession!.connection,
          reconnect: true,
        );
        tries++;
        GeneralHelper.advLog(
          '$tries. attempt to reconnect...',
          level: LogLevel.Warning,
          includeInLogs: true,
        );
      }
      if (response?.status != BaseResponse.ok) {
        GeneralHelper.advLog(
          'Not able to reconnect to OBS, initiating termination process!',
          level: LogLevel.Warning,
          includeInLogs: true,
        );
        GetIt.instance<NetworkStore>().obsTerminated = true;
      } else {
        GeneralHelper.advLog(
          'Successfully reconnected to OBS!',
          level: LogLevel.Warning,
          includeInLogs: true,
        );

        this.reconnecting = false;
        this.handleStream();
        this.initialRequests();
        this.checkConnectionTimer = Timer(
          const Duration(seconds: 3),
          () => _checkOBSConnection(),
        );
      }
    } else {
      this.checkConnectionTimer = Timer(
        const Duration(seconds: 3),
        () => _checkOBSConnection(),
      );
    }
  }

  @action
  void setShouldRequestPreviewImage(bool shouldRequestPreviewImage) {
    this.shouldRequestPreviewImage = shouldRequestPreviewImage;
    if (shouldRequestPreviewImage) {
      this.scenePreviewImageBytes = null;
      this.requestPreviewImage();
    }
  }

  @action
  void setPointerOnChat(bool isPointerOnChat) =>
      this.isPointerOnChat = isPointerOnChat;

  @action
  void toggleSceneItemGroupVisibility(SceneItem sceneItem) {
    sceneItem.displayGroup = !sceneItem.displayGroup;
    this.currentSceneItems = ObservableList.of(this.currentSceneItems!);
  }

  @action
  void setEditSceneItemVisibility(bool editSceneItemVisibility) =>
      this.editSceneItemVisibility = editSceneItemVisibility;

  @action
  void setEditAudioVisibility(bool editAudioVisibility) =>
      this.editAudioVisibility = editAudioVisibility;

  @action
  void setEditSceneVisibility(bool editSceneVisibility) =>
      this.editSceneVisibility = editSceneVisibility;

  @action
  Future<void> _handleEvent(BaseEvent event) async {
    if (event.eventType != null) {
      GeneralHelper.advLog(
        'Event Incoming: ${event.eventType}',
      );
    }
    this.latestRecordTimeDurationMS = _timecodeToMS(event.recTimecode);
    this.latestStreamTimeDurationMS = _timecodeToMS(event.streamTimecode);
    switch (event.eventType) {
      case EventType.StreamStarted:
        this.isLive = true;
        break;
      case EventType.StreamStopped:
        this.isLive = false;
        this.latestStreamTimeDurationMS = null;
        this.finishPastStreamData();
        break;
      case EventType.RecordingStarted:
        this.isRecording = true;
        GeneralHelper.advLog(event.recTimecode);
        break;
      case EventType.RecordingStopped:
        this.isRecording = false;
        this.isRecordingPaused = false;
        this.latestRecordTimeDurationMS = null;
        break;
      case EventType.RecordingPaused:
        this.isRecordingPaused = true;
        break;
      case EventType.RecordingResumed:
        this.isRecordingPaused = false;
        break;
      case EventType.ReplayStarted:
        this.isReplayBufferActive = true;
        break;
      case EventType.ReplayStopped:
        this.isReplayBufferActive = false;
        OverlayHandler.closeAnyOverlay(immediately: false);
        break;
      case EventType.StreamStatus:
        this.latestStreamStats = StreamStats.fromJSON(event.json);

        /// This case happens if we connect to an OBS session which already streams
        if (!this.isLive) {
          this.isLive = true;
        }
        if (this.latestStreamStats!.recording && !this.isRecording) {
          NetworkHelper.makeRequest(
            GetIt.instance<NetworkStore>().activeSession!.socket,
            RequestType.GetRecordingStatus,
          );
        }
        if (this.streamData == null) {
          _manageStreamDataInit();
        }
        this.streamData!.addStreamStats(this.latestStreamStats!);
        await this.streamData!.save();
        break;
      case EventType.SceneCollectionChanged:
        OverlayHandler.closeAnyOverlay(immediately: false);
        SceneCollectionChangedEvent sceneCollectionChangedEvent =
            SceneCollectionChangedEvent(event.json);

        this.currentSceneCollectionName =
            sceneCollectionChangedEvent.sceneCollection;

        this.handleRequestsEvents = true;
        this.sceneCollectionRequests();
        break;
      case EventType.SceneCollectionListChanged:
        SceneCollectionListChangedEvent sceneCollectionListChangedEvent =
            SceneCollectionListChangedEvent(event.json);

        this.sceneCollections =
            ObservableList.of(sceneCollectionListChangedEvent.sceneCollections);

        break;
      case EventType.ScenesChanged:
        NetworkHelper.makeRequest(
            GetIt.instance<NetworkStore>().activeSession!.socket,
            RequestType.GetSceneList);
        break;
      case EventType.SwitchScenes:
        SwitchScenesEvent switchSceneEvent = SwitchScenesEvent(event.json);
        if (!Hive.box(HiveKeys.Settings.name).get(
                SettingsKeys.ExposeStudioControls.name,
                defaultValue: false) ||
            !this.studioMode) {
          this.currentSceneItems =
              ObservableList.of(_flattenSceneItems(switchSceneEvent.sources));
          for (var sceneItem in this.currentSceneItems!) {
            NetworkHelper.makeRequest(
                GetIt.instance<NetworkStore>().activeSession!.socket,
                RequestType.GetMute,
                {'source': sceneItem.name});
          }
        }
        break;
      case EventType.TransitionBegin:
        TransitionBeginEvent transitionBeginEvent =
            TransitionBeginEvent(event.json);
        this.sceneTransitionDurationMS = transitionBeginEvent.duration >= 0
            ? transitionBeginEvent.duration
            : 0;
        this.activeSceneName = transitionBeginEvent.toScene;
        break;
      case EventType.TransitionListChanged:
        TransitionListChangedEvent transitionListChangedEvent =
            TransitionListChangedEvent(event.json);
        GeneralHelper.advLog(
            'CHANGED:' + transitionListChangedEvent.json.toString());
        this.availableTransitionsNames = transitionListChangedEvent.transitions;
        break;
      case EventType.TransitionDurationChanged:
        TransitionDurationChangedEvent transitionDurationChangedEvent =
            TransitionDurationChangedEvent(event.json);

        this.sceneTransitionDurationMS =
            transitionDurationChangedEvent.newDuration;
        break;
      case EventType.SwitchTransition:
        SwitchTransitionEvent switchTransitionEventEvent =
            SwitchTransitionEvent(event.json);
        this.currentTransitionName = switchTransitionEventEvent.transitionName;
        NetworkHelper.makeRequest(
            GetIt.instance<NetworkStore>().activeSession!.socket,
            RequestType.GetTransitionList);
        NetworkHelper.makeRequest(
            GetIt.instance<NetworkStore>().activeSession!.socket,
            RequestType.GetCurrentTransition);
        break;
      case EventType.StudioModeSwitched:
        StudioModeSwitchedEvent studioModeSwitchedEvent =
            StudioModeSwitchedEvent(event.json);

        this.studioMode = studioModeSwitchedEvent.newState;

        NetworkHelper.makeRequest(
          GetIt.instance<NetworkStore>().activeSession!.socket,
          Hive.box(HiveKeys.Settings.name).get(
                      SettingsKeys.ExposeStudioControls.name,
                      defaultValue: false) &&
                  this.studioMode
              ? RequestType.GetPreviewScene
              : RequestType.GetCurrentScene,
        );
        break;
      case EventType.PreviewSceneChanged:
        PreviewSceneChangedEvent previewSceneChangedEvent =
            PreviewSceneChangedEvent(event.json);

        if (Hive.box(HiveKeys.Settings.name).get(
                SettingsKeys.ExposeStudioControls.name,
                defaultValue: false) &&
            this.studioMode) {
          this.studioModePreviewSceneName = previewSceneChangedEvent.sceneName;
          this.currentSceneItems = ObservableList.of(
              _flattenSceneItems(previewSceneChangedEvent.sources));
          for (var sceneItem in this.currentSceneItems!) {
            NetworkHelper.makeRequest(
                GetIt.instance<NetworkStore>().activeSession!.socket,
                RequestType.GetMute,
                {'source': sceneItem.name});
          }
        }
        break;
      case EventType.SceneItemAdded:
        // SceneItemAddedEvent sceneItemAddedEvent =
        //     SceneItemAddedEvent(event.json);
        NetworkHelper.makeRequest(
            GetIt.instance<NetworkStore>().activeSession!.socket,
            RequestType.GetCurrentScene);
        break;
      case EventType.SceneItemRemoved:
        SceneItemRemovedEvent sceneItemRemovedEvent =
            SceneItemRemovedEvent(event.json);
        this.currentSceneItems!.removeWhere(
            (sceneItem) => sceneItem.id == sceneItemRemovedEvent.itemID);
        break;
      case EventType.SourceRenamed:
        SourceRenamedEvent sourceRenamedEvent = SourceRenamedEvent(event.json);
        try {
          this
              .currentSceneItems!
              .firstWhere((sceneItem) =>
                  sceneItem.name == sourceRenamedEvent.previousName)
              .name = sourceRenamedEvent.newName;
          this.currentSceneItems = ObservableList.of(this.currentSceneItems!);
        } catch (e) {}
        break;
      case EventType.SourceOrderChanged:
        // SourceOrderChangedEvent sourceOrderChangedEvent =
        //     SourceOrderChangedEvent(event.json);
        NetworkHelper.makeRequest(
            GetIt.instance<NetworkStore>().activeSession!.socket,
            RequestType.GetCurrentScene);
        break;
      case EventType.SourceVolumeChanged:
        SourceVolumeChangedEvent sourceVolumeChangedEvent =
            SourceVolumeChangedEvent(event.json);
        try {
          [...this.currentSceneItems!, ...this.globalAudioSceneItems]
              .firstWhere((audioSceneItem) =>
                  audioSceneItem.name == sourceVolumeChangedEvent.sourceName)
              .volume = sourceVolumeChangedEvent.volume;
          this.currentSceneItems = ObservableList.of(this.currentSceneItems!);
          this.globalAudioSceneItems =
              ObservableList.of(this.globalAudioSceneItems);
        } catch (e) {}
        break;
      case EventType.SourceMuteStateChanged:
        SourceMuteStateChangedEvent sourceMuteStateChangedEvent =
            SourceMuteStateChangedEvent(event.json);
        try {
          [...this.currentSceneItems!, ...this.globalAudioSceneItems]
              .firstWhere((audioSceneItem) =>
                  audioSceneItem.name == sourceMuteStateChangedEvent.sourceName)
              .muted = sourceMuteStateChangedEvent.muted;
          this.currentSceneItems = ObservableList.of(this.currentSceneItems!);
          this.globalAudioSceneItems =
              ObservableList.of(this.globalAudioSceneItems);
        } catch (e) {}
        break;
      case EventType.SceneItemVisibilityChanged:
        SceneItemVisibilityChangedEvent sceneItemVisibilityChangedEvent =
            SceneItemVisibilityChangedEvent(event.json);
        try {
          this
              .currentSceneItems!
              .firstWhere((sceneItem) =>
                  sceneItem.name == sceneItemVisibilityChangedEvent.itemName)
              .render = sceneItemVisibilityChangedEvent.itemVisible;

          this.currentSceneItems = ObservableList.of(this.currentSceneItems!);
        } catch (e) {}
        break;
      case EventType.Exiting:
        await this.finishPastStreamData();
        GetIt.instance<NetworkStore>().obsTerminated = true;
        break;
      default:
        break;
    }
  }

  @action
  void _handleResponse(BaseResponse response) {
    GeneralHelper.advLog(
      'Response Incoming: ${response.requestType}',
    );
    switch (response.requestType) {
      case RequestType.GetVersion:
        GetVersionResponse getVersionResponse =
            GetVersionResponse(response.json);

        if (!getVersionResponse.supportedImageExportFormats.contains('jpg') &&
            !getVersionResponse.supportedImageExportFormats.contains('jpeg')) {
          this.previewFileFormat = 'png';
        }
        break;
      case RequestType.GetSceneList:
        GetSceneListResponse getSceneListResponse =
            GetSceneListResponse(response.json);

        this.activeSceneName = getSceneListResponse.currentScene;
        this.scenes = ObservableList.of(getSceneListResponse.scenes);
        break;
      case RequestType.ListSceneCollections:
        ListSceneCollectionsResponse listSceneCollectionsResponse =
            ListSceneCollectionsResponse(response.json);

        this.sceneCollections =
            ObservableList.of(listSceneCollectionsResponse.sceneCollections);
        break;
      case RequestType.GetCurrentSceneCollection:
        GetCurrentSceneCollectionResponse getCurrentSceneCollectionResponse =
            GetCurrentSceneCollectionResponse(response.json);

        this.currentSceneCollectionName =
            getCurrentSceneCollectionResponse.scName;
        break;
      case RequestType.GetCurrentScene:
        GetCurrentSceneResponse getCurrentSceneResponse =
            GetCurrentSceneResponse(response.json);

        this.currentSceneItems = ObservableList.of(
            _flattenSceneItems(getCurrentSceneResponse.sources));
        for (var sceneItem in this.currentSceneItems!) {
          NetworkHelper.makeRequest(
              GetIt.instance<NetworkStore>().activeSession!.socket,
              RequestType.GetMute,
              {'source': sceneItem.name});
        }
        break;
      case RequestType.GetPreviewScene:
        GetPreviewSceneResponse getPreviewSceneResponse =
            GetPreviewSceneResponse(response.json);

        this.studioModePreviewSceneName = getPreviewSceneResponse.name;
        this.currentSceneItems = ObservableList.of(
            _flattenSceneItems(getPreviewSceneResponse.sources));
        for (var sceneItem in this.currentSceneItems!) {
          NetworkHelper.makeRequest(
              GetIt.instance<NetworkStore>().activeSession!.socket,
              RequestType.GetMute,
              {'source': sceneItem.name});
        }
        break;
      case RequestType.GetTransitionList:
        GetTransitionListResponse getTransitionListResponse =
            GetTransitionListResponse(response.json);

        this.availableTransitionsNames = getTransitionListResponse.transitions;
        break;
      case RequestType.GetCurrentTransition:
        GetCurrentTransitionResponse getCurrentTransitionResponse =
            GetCurrentTransitionResponse(response.json);

        this.currentTransitionName = getCurrentTransitionResponse.name;
        this.sceneTransitionDurationMS = getCurrentTransitionResponse.duration;
        break;
      case RequestType.GetStudioModeStatus:
        GetStudioModeStatusResponse getStudioModeStatusResponse =
            GetStudioModeStatusResponse(response.json);

        this.studioMode = getStudioModeStatusResponse.studioMode;

        if (Hive.box(HiveKeys.Settings.name).get(
                SettingsKeys.ExposeStudioControls.name,
                defaultValue: false) &&
            this.studioMode) {
          NetworkHelper.makeRequest(
            GetIt.instance<NetworkStore>().activeSession!.socket,
            RequestType.GetPreviewScene,
          );
        }
        break;
      case RequestType.GetRecordingStatus:
        GetRecordingStatusResponse getRecordingStatusResponse =
            GetRecordingStatusResponse(response.json);

        this.isRecording = getRecordingStatusResponse.isRecording;
        this.isRecordingPaused = getRecordingStatusResponse.isRecordingPaused;

        if (this.isRecording) {
          this.latestRecordTimeDurationMS =
              _timecodeToMS(getRecordingStatusResponse.recordTimecode);
        }
        break;
      case RequestType.GetReplayBufferStatus:
        GetReplayBufferStatusResponse getReplayBufferStatusResponse =
            GetReplayBufferStatusResponse(response.json);

        this.isReplayBufferActive =
            getReplayBufferStatusResponse.isReplayBufferActive;

        break;
      case RequestType.GetSpecialSources:
        this.globalAudioSceneItems = ObservableList.of([]);
        GetSpecialSourcesResponse getSpecialSourcesResponse =
            GetSpecialSourcesResponse(response.json);
        if (getSpecialSourcesResponse.desktop1 != null) {
          NetworkHelper.makeRequest(
              GetIt.instance<NetworkStore>().activeSession!.socket,
              RequestType.GetVolume,
              {'source': getSpecialSourcesResponse.desktop1});
        }
        if (getSpecialSourcesResponse.desktop2 != null) {
          NetworkHelper.makeRequest(
              GetIt.instance<NetworkStore>().activeSession!.socket,
              RequestType.GetVolume,
              {'source': getSpecialSourcesResponse.desktop2});
        }
        if (getSpecialSourcesResponse.mic1 != null) {
          NetworkHelper.makeRequest(
              GetIt.instance<NetworkStore>().activeSession!.socket,
              RequestType.GetVolume,
              {'source': getSpecialSourcesResponse.mic1});
        }
        if (getSpecialSourcesResponse.mic2 != null) {
          NetworkHelper.makeRequest(
              GetIt.instance<NetworkStore>().activeSession!.socket,
              RequestType.GetVolume,
              {'source': getSpecialSourcesResponse.mic2});
        }
        if (getSpecialSourcesResponse.mic3 != null) {
          NetworkHelper.makeRequest(
              GetIt.instance<NetworkStore>().activeSession!.socket,
              RequestType.GetVolume,
              {'source': getSpecialSourcesResponse.mic3});
        }
        break;
      case RequestType.GetSourcesList:
        // GetSourcesListResponse getSourcesListResponse =
        //     GetSourcesListResponse(response.json);
        // getSourcesListResponse.sources.forEach((source) {
        //   print(response.json);
        // print('${source.name}: ${source.typeID}');
        // NetworkHelper.makeRequest(this.networkStore.activeSession.socket,
        //     RequestType.GetSourceSettings, {'sourceName': source.name});
        // });
        break;
      case RequestType.GetSourceTypesList:
        GetSourceTypesList getSourceTypesList =
            GetSourceTypesList(response.json);
        this.sourceTypes = getSourceTypesList.types;
        // (response.json['types'] as List<dynamic>)
        //     .forEach((type) => print(type['typeId']));
        NetworkHelper.makeRequest(
            GetIt.instance<NetworkStore>().activeSession!.socket,
            RequestType.GetCurrentScene);
        NetworkHelper.makeRequest(
            GetIt.instance<NetworkStore>().activeSession!.socket,
            RequestType.GetSpecialSources);
        break;
      case RequestType.GetVolume:
        GetVolumeResponse getVolumeResponse = GetVolumeResponse(response.json);
        if (this.globalAudioSceneItems.every((globalAudioItem) =>
            globalAudioItem.name != getVolumeResponse.name)) {
          this.globalAudioSceneItems.add(SceneItem.audio(
                name: getVolumeResponse.name,
                volume: getVolumeResponse.volume,
                muted: getVolumeResponse.muted,
              ));
        }
        break;
      case RequestType.GetMute:
        GetMuteResponse getMuteResponse = GetMuteResponse(response.json);
        try {
          this
              .currentSceneItems!
              .firstWhere((sceneItem) => sceneItem.name == getMuteResponse.name)
              .muted = getMuteResponse.muted;
          this.currentSceneItems = ObservableList.of(this.currentSceneItems!);
        } catch (e) {}
        break;
      case RequestType.GetSourceSettings:
        // GetSourceSettingsResponse getSourceSettingsResponse =
        //     GetSourceSettingsResponse(response.json);
        // print(
        //     '${getSourceSettingsResponse.sourceName}: ${getSourceSettingsResponse.sourceSettings}');
        break;
      case RequestType.ListOutputs:
        // ListOutputsResponse listOutputsResponse =
        //     ListOutputsResponse(response.json);
        // listOutputsResponse.outputs.forEach(
        //     (output) => print('${output.name}: ${output.flags.audio}'));
        break;
      case RequestType.TakeSourceScreenshot:
        TakeSourceScreenshotResponse takeSourceScreenshotResponse =
            TakeSourceScreenshotResponse(response.json);

        this.scenePreviewImageBytes =
            base64Decode(takeSourceScreenshotResponse.img.split(',')[1]);

        if (this.shouldRequestPreviewImage) this.requestPreviewImage();
        break;
      default:
        break;
    }
  }
}
