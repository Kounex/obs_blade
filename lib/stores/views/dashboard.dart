import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/types/classes/stream/responses/get_studio_mode_status.dart';
import '../../types/classes/stream/events/preview_scene_changed.dart';

import '../../models/past_stream_data.dart';
import '../../types/classes/api/scene.dart';
import '../../types/classes/api/scene_item.dart';
import '../../types/classes/api/source_type.dart';
import '../../types/classes/api/stream_stats.dart';
import '../../types/classes/stream/events/base.dart';
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
import '../../types/classes/stream/responses/get_current_transition.dart';
import '../../types/classes/stream/responses/get_mute.dart';
import '../../types/classes/stream/responses/get_scene_list.dart';
import '../../types/classes/stream/responses/get_source_types_list.dart';
import '../../types/classes/stream/responses/get_special_sources.dart';
import '../../types/classes/stream/responses/get_transition_list.dart';
import '../../types/classes/stream/responses/get_version.dart';
import '../../types/classes/stream/responses/get_volume.dart';
import '../../types/classes/stream/responses/take_source_screenshot.dart';
import '../../types/enums/event_type.dart';
import '../../types/enums/hive_keys.dart';
import '../../types/enums/request_type.dart';
import '../../utils/network_helper.dart';
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
  int? goneLiveMS;
  @observable
  int? startedRecordingMS;
  @observable
  PastStreamData? streamData;
  @observable
  StreamStats? latestStreamStats;

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

  /// Currently I hold a reference to the [NetworkStore] object to be able
  /// to listen to the WebSocket stream and toggle some stuff. [NetworkStore]
  /// is one of the shared stores, indicate that those kind of stores are not
  /// bound to specific views but are rather "global". Those can be seen as
  /// the "real" app states / stores. Therefore they are used in several views /
  /// widgets but also in other stores. I don't have a better solution right now
  /// other than passing a reference to the [NetworkStore] as soon as this store
  /// [DashboardStore] gets instantiated in the Provider create property.
  ///
  /// I want to avoid having such things as global entities at all because global
  /// stuff (as the name already indicates) is not bound to anything really and it
  /// could be accessed from everywhere and "controlling" those stuff can get out
  /// of hand quickly.
  NetworkStore? networkStore;

  List<SourceType>? sourceTypes;

  Timer? checkConnectionTimer;

  String previewFileFormat = 'jpeg';

  @action
  void setupNetworkStoreHandling(NetworkStore networkStore) {
    this.networkStore = networkStore;
    this.handleStream();
    this.initialRequests();

    /// Since [setupNetworkStoreHandling] gets called as soon as we connect
    /// to an OBS instance, we trigger this [Timer] which will check if
    /// the connection is still alive periodically - see [_checkOBSConnection]
    /// for more information
    this.checkConnectionTimer = Timer(
      Duration(seconds: 5),
      () => _checkOBSConnection(),
    );
  }

  void initialRequests() {
    NetworkHelper.makeRequest(
        this.networkStore!.activeSession!.socket, RequestType.GetVersion);
    NetworkHelper.makeRequest(
        this.networkStore!.activeSession!.socket, RequestType.GetSceneList);
    NetworkHelper.makeRequest(this.networkStore!.activeSession!.socket,
        RequestType.GetSourceTypesList);
    NetworkHelper.makeRequest(this.networkStore!.activeSession!.socket,
        RequestType.GetTransitionList);
    NetworkHelper.makeRequest(this.networkStore!.activeSession!.socket,
        RequestType.GetCurrentTransition);
    NetworkHelper.makeRequest(this.networkStore!.activeSession!.socket,
        RequestType.GetStudioModeStatus);
    // NetworkHelper.makeRequest(
    //     this.networkStore.activeSession.socket, RequestType.GetSourcesList);
    // NetworkHelper.makeRequest(
    //     this.networkStore.activeSession.socket, RequestType.ListOutputs);
  }

  void handleStream() {
    this.networkStore!.watchOBSStream().listen((message) {
      if (message is BaseEvent) {
        _handleEvent(message);
      } else {
        _handleResponse(message as BaseResponse);
      }
    });
  }

  void requestPreviewImage() => NetworkHelper.makeRequest(
        this.networkStore!.activeSession!.socket,
        RequestType.TakeSourceScreenshot,
        {
          'sourceName': this.activeSceneName,
          'embedPictureFormat': this.previewFileFormat,
          'compressionQuality': -1,
        },
      );

  /// Check if we have ongoing statistics (!= null) and set it
  /// to null to indicate that we are done with this one and can start
  /// a new one
  Future<void> finishPastStreamData() async {
    if (this.streamData != null) {
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
    sceneItems.forEach((sceneItem) {
      tmpSceneItems.add(sceneItem);
      if (sceneItem.groupChildren != null &&
          sceneItem.groupChildren!.length > 0) {
        tmpSceneItems.addAll(sceneItem.groupChildren!);
      }
    });
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
    if (tmp.length > 0 &&
        DateTime.now().millisecondsSinceEpoch -
                this.latestStreamStats!.totalStreamTime * 1000 <=
            tmp.last.listEntryDateMS.last) {
      this.streamData = tmp.last;
    } else {
      this.streamData = PastStreamData();
      await pastStreamDataBox.add(this.streamData!);
    }
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
    if (this.networkStore!.activeSession?.socket.closeCode != null) {
      this.reconnecting = true;
      BaseResponse? response;
      int tries = 0;

      while (tries < 5 && response?.status != BaseResponse.ok) {
        response = await this.networkStore!.setOBSWebSocket(
              this.networkStore!.activeSession!.connection,
              reconnect: true,
            );
        tries++;
      }
      if (response?.status != BaseResponse.ok) {
        this.networkStore!.obsTerminated = true;
      } else {
        this.reconnecting = false;
        this.handleStream();
        this.initialRequests();
        this.checkConnectionTimer = Timer(
          Duration(seconds: 3),
          () => _checkOBSConnection(),
        );
      }
    } else {
      this.checkConnectionTimer = Timer(
        Duration(seconds: 3),
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
  Future<void> _handleEvent(BaseEvent event) async {
    print(event.json['update-type']);
    switch (event.eventType) {
      case EventType.StreamStarted:
        this.isLive = true;
        this.goneLiveMS = DateTime.now().millisecondsSinceEpoch;
        break;
      case EventType.StreamStopping:
        this.isLive = false;
        this.finishPastStreamData();
        break;
      case EventType.RecordingStarted:
        this.isRecording = true;
        this.startedRecordingMS = DateTime.now().millisecondsSinceEpoch;
        break;
      case EventType.RecordingStopping:
        this.isRecording = false;
        this.isRecordingPaused = false;
        break;
      case EventType.RecordingPaused:
        this.isRecordingPaused = true;
        break;
      case EventType.RecordingResumed:
        this.isRecordingPaused = false;
        break;
      case EventType.StreamStatus:
        this.latestStreamStats = StreamStats.fromJSON(event.json);

        /// This case happens if we connect to an OBS session which already streams
        if (this.goneLiveMS == null) {
          this.isLive = true;
          this.goneLiveMS = DateTime.now().millisecondsSinceEpoch -
              (this.latestStreamStats!.totalStreamTime * 1000);
        }
        if (this.latestStreamStats!.recording &&
            this.startedRecordingMS == null) {
          this.isRecording = true;
        }
        if (this.streamData == null) {
          _manageStreamDataInit();
        }
        this.streamData!.addStreamStats(this.latestStreamStats!);
        await this.streamData!.save();
        break;
      case EventType.ScenesChanged:
        NetworkHelper.makeRequest(
            this.networkStore!.activeSession!.socket, RequestType.GetSceneList);
        break;
      case EventType.SwitchScenes:
        SwitchScenesEvent switchSceneEvent = SwitchScenesEvent(event.json);
        this.currentSceneItems =
            ObservableList.of(_flattenSceneItems(switchSceneEvent.sources));
        this.currentSceneItems!.forEach((sceneItem) =>
            NetworkHelper.makeRequest(this.networkStore!.activeSession!.socket,
                RequestType.GetMute, {'source': sceneItem.name}));
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
        NetworkHelper.makeRequest(this.networkStore!.activeSession!.socket,
            RequestType.GetTransitionList);
        NetworkHelper.makeRequest(this.networkStore!.activeSession!.socket,
            RequestType.GetCurrentTransition);
        break;
      case EventType.StudioModeSwitched:
        StudioModeSwitchedEvent studioModeSwitchedEvent =
            StudioModeSwitchedEvent(event.json);
        this.studioMode = studioModeSwitchedEvent.newState;
        break;
      case EventType.PreviewSceneChanged:
        PreviewSceneChangedEvent previewSceneChangedEvent =
            PreviewSceneChangedEvent(event.json);
        this.studioModePreviewSceneName = previewSceneChangedEvent.sceneName;
        break;
      case EventType.SceneItemAdded:
        // SceneItemAddedEvent sceneItemAddedEvent =
        //     SceneItemAddedEvent(event.json);
        NetworkHelper.makeRequest(this.networkStore!.activeSession!.socket,
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
        this
            .currentSceneItems!
            .firstWhere((sceneItem) =>
                sceneItem.name == sourceRenamedEvent.previousName)
            .name = sourceRenamedEvent.newName;
        this.currentSceneItems = ObservableList.of(this.currentSceneItems!);
        break;
      case EventType.SourceOrderChanged:
        // SourceOrderChangedEvent sourceOrderChangedEvent =
        //     SourceOrderChangedEvent(event.json);
        NetworkHelper.makeRequest(this.networkStore!.activeSession!.socket,
            RequestType.GetCurrentScene);
        break;
      case EventType.SourceVolumeChanged:
        SourceVolumeChangedEvent sourceVolumeChangedEvent =
            SourceVolumeChangedEvent(event.json);
        [...this.currentSceneItems!, ...this.globalAudioSceneItems]
            .firstWhere((audioSceneItem) =>
                audioSceneItem.name == sourceVolumeChangedEvent.sourceName)
            .volume = sourceVolumeChangedEvent.volume;
        this.currentSceneItems = ObservableList.of(this.currentSceneItems!);
        this.globalAudioSceneItems =
            ObservableList.of(this.globalAudioSceneItems);
        break;
      case EventType.SourceMuteStateChanged:
        SourceMuteStateChangedEvent sourceMuteStateChangedEvent =
            SourceMuteStateChangedEvent(event.json);
        [...this.currentSceneItems!, ...this.globalAudioSceneItems]
            .firstWhere((audioSceneItem) =>
                audioSceneItem.name == sourceMuteStateChangedEvent.sourceName)
            .muted = sourceMuteStateChangedEvent.muted;
        this.currentSceneItems = ObservableList.of(this.currentSceneItems!);
        this.globalAudioSceneItems =
            ObservableList.of(this.globalAudioSceneItems);
        break;
      case EventType.SceneItemVisibilityChanged:
        SceneItemVisibilityChangedEvent sceneItemVisibilityChangedEvent =
            SceneItemVisibilityChangedEvent(event.json);
        this
            .currentSceneItems!
            .firstWhere((sceneItem) =>
                sceneItem.name == sceneItemVisibilityChangedEvent.itemName)
            .render = sceneItemVisibilityChangedEvent.itemVisible;

        this.currentSceneItems = ObservableList.of(this.currentSceneItems!);
        break;
      case EventType.Exiting:
        await this.finishPastStreamData();
        this.networkStore!.obsTerminated = true;
        break;
      default:
        break;
    }
  }

  @action
  void _handleResponse(BaseResponse response) {
    switch (response.requestType) {
      case RequestType.GetVersion:
        GetVersionResponse getVersionResponse =
            GetVersionResponse(response.json);

        if (!getVersionResponse.supportedImageExportFormats.contains('jpg') &&
            !getVersionResponse.supportedImageExportFormats.contains('jpeg'))
          this.previewFileFormat = 'png';
        break;
      case RequestType.GetSceneList:
        GetSceneListResponse getSceneListResponse =
            GetSceneListResponse(response.json);
        this.activeSceneName = getSceneListResponse.currentScene;
        this.scenes = ObservableList.of(getSceneListResponse.scenes);
        this.scenes!.forEach((scene) => scene.sources.forEach(
            (item) => print('${scene.name} | ${item.id} | ${item.name}')));
        break;
      case RequestType.GetCurrentScene:
        GetCurrentSceneResponse getCurrentSceneResponse =
            GetCurrentSceneResponse(response.json);

        this.currentSceneItems = ObservableList.of(
            _flattenSceneItems(getCurrentSceneResponse.sources));
        this.currentSceneItems!.forEach((sceneItem) =>
            NetworkHelper.makeRequest(this.networkStore!.activeSession!.socket,
                RequestType.GetMute, {'source': sceneItem.name}));
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
        break;
      case RequestType.GetSpecialSources:
        GetSpecialSourcesResponse getSpecialSourcesResponse =
            GetSpecialSourcesResponse(response.json);
        if (getSpecialSourcesResponse.desktop1 != null) {
          NetworkHelper.makeRequest(
              this.networkStore!.activeSession!.socket,
              RequestType.GetVolume,
              {'source': getSpecialSourcesResponse.desktop1});
        }
        if (getSpecialSourcesResponse.desktop2 != null) {
          NetworkHelper.makeRequest(
              this.networkStore!.activeSession!.socket,
              RequestType.GetVolume,
              {'source': getSpecialSourcesResponse.desktop2});
        }
        if (getSpecialSourcesResponse.mic1 != null) {
          NetworkHelper.makeRequest(
              this.networkStore!.activeSession!.socket,
              RequestType.GetVolume,
              {'source': getSpecialSourcesResponse.mic1});
        }
        if (getSpecialSourcesResponse.mic2 != null) {
          NetworkHelper.makeRequest(
              this.networkStore!.activeSession!.socket,
              RequestType.GetVolume,
              {'source': getSpecialSourcesResponse.mic2});
        }
        if (getSpecialSourcesResponse.mic3 != null) {
          NetworkHelper.makeRequest(
              this.networkStore!.activeSession!.socket,
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
        NetworkHelper.makeRequest(this.networkStore!.activeSession!.socket,
            RequestType.GetCurrentScene);
        NetworkHelper.makeRequest(this.networkStore!.activeSession!.socket,
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
        } catch (e) {}
        this.currentSceneItems = ObservableList.of(this.currentSceneItems!);
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
