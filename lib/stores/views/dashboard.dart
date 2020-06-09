import 'dart:convert';

import 'package:mobx/mobx.dart';

import '../../types/classes/api/scene.dart';
import '../../types/classes/api/scene_item.dart';
import '../../types/classes/api/source_type.dart';
import '../../types/classes/api/stream_stats.dart';
import '../../types/classes/session.dart';
import '../../types/classes/stream/events/base.dart';
import '../../types/classes/stream/events/source_mute_state_changed.dart';
import '../../types/classes/stream/events/source_volume_changed.dart';
import '../../types/classes/stream/events/switch_scenes.dart';
import '../../types/classes/stream/events/transition_begin.dart';
import '../../types/classes/stream/responses/base.dart';
import '../../types/classes/stream/responses/get_current_scene.dart';
import '../../types/classes/stream/responses/get_mute.dart';
import '../../types/classes/stream/responses/get_scene_list.dart';
import '../../types/classes/stream/responses/get_source_types_list.dart';
import '../../types/classes/stream/responses/get_special_sources.dart';
import '../../types/classes/stream/responses/get_volume.dart';
import '../../types/enums/event_type.dart';
import '../../types/enums/request_type.dart';
import '../../utils/network_helper.dart';

part 'dashboard.g.dart';

class DashboardStore = _DashboardStore with _$DashboardStore;

abstract class _DashboardStore with Store {
  @observable
  bool isLive = false;
  @observable
  int goneLiveInMS;
  @observable
  StreamStats streamStats;

  @observable
  String activeSceneName;
  @observable
  ObservableList<Scene> scenes;
  @observable
  ObservableList<SceneItem> currentSceneItems;

  @computed
  ObservableList<SceneItem> get currentAudioSceneItems =>
      this.currentSceneItems != null
          ? ObservableList.of(currentSceneItems?.where((sceneItem) => this
              .sourceTypes
              .any((sourceType) =>
                  sourceType.caps.hasAudio &&
                  sourceType.typeID == sceneItem.type)))
          : ObservableList();

  @observable
  ObservableList<SceneItem> globalAudioSceneItems = ObservableList();

  @observable
  int sceneTransitionDurationMS;

  Session activeSession;

  List<SourceType> sourceTypes;

  setActiveSession(Session activeSession) {
    this.activeSession = activeSession;
    this.initialRequests();
    this.handleStream();
  }

  initialRequests() {
    NetworkHelper.makeRequest(
        this.activeSession.socket.sink, RequestType.GetSceneList);
    // NetworkHelper.makeRequest(
    //     this.activeSession.socket.sink, RequestType.GetSourcesList);
    NetworkHelper.makeRequest(
        this.activeSession.socket.sink, RequestType.GetSourceTypesList);
    // NetworkHelper.makeRequest(
    //     this.activeSession.socket.sink, RequestType.ListOutputs);
  }

  handleStream() {
    this.activeSession.socketStream.listen((event) {
      Map<String, dynamic> fullJSON = json.decode(event);
      if (fullJSON['update-type'] != null) {
        _handleEvent(BaseEvent(fullJSON));
      } else {
        _handleResponse(BaseResponse(fullJSON));
      }
    });
  }

  @action
  _handleEvent(BaseEvent event) {
    switch (event.updateType) {
      case EventType.StreamStarted:
        this.isLive = true;
        this.goneLiveInMS = DateTime.now().millisecondsSinceEpoch;
        break;
      case EventType.StreamStopping:
        this.isLive = false;
        break;
      case EventType.StreamStatus:
        this.streamStats = StreamStats.fromJSON(event.json);
        if (this.goneLiveInMS == null) {
          this.isLive = true;
          this.goneLiveInMS = DateTime.now().millisecondsSinceEpoch -
              (this.streamStats.totalStreamTime * 1000);
        }
        break;
      case EventType.ScenesChanged:
        NetworkHelper.makeRequest(
            this.activeSession.socket.sink, RequestType.GetSceneList);
        break;
      case EventType.SwitchScenes:
        SwitchScenesEvent switchSceneEvent = SwitchScenesEvent(event.json);
        this.currentSceneItems = ObservableList.of(switchSceneEvent.sources);
        currentSceneItems.forEach((sceneItem) => NetworkHelper.makeRequest(
            this.activeSession.socket.sink,
            RequestType.GetMute,
            {'source': sceneItem.name}));

        break;
      case EventType.TransitionBegin:
        TransitionBeginEvent transitionBeginEvent =
            TransitionBeginEvent(event.json);
        this.sceneTransitionDurationMS = transitionBeginEvent.duration;
        this.activeSceneName = transitionBeginEvent.toScene;
        break;
      case EventType.SourceVolumeChanged:
        SourceVolumeChangedEvent sourceVolumeChangedEvent =
            SourceVolumeChangedEvent(event.json);
        [...this.currentSceneItems, ...this.globalAudioSceneItems]
            .firstWhere((audioSceneItem) =>
                audioSceneItem.name == sourceVolumeChangedEvent.sourceName)
            .volume = sourceVolumeChangedEvent.volume;
        this.currentSceneItems = ObservableList.of(this.currentSceneItems);
        this.globalAudioSceneItems =
            ObservableList.of(this.globalAudioSceneItems);
        break;
      case EventType.SourceMuteStateChanged:
        SourceMuteStateChangedEvent sourceMuteStateChangedEvent =
            SourceMuteStateChangedEvent(event.json);
        [...this.currentSceneItems, ...this.globalAudioSceneItems]
            .firstWhere((audioSceneItem) =>
                audioSceneItem.name == sourceMuteStateChangedEvent.sourceName)
            .muted = sourceMuteStateChangedEvent.muted;
        this.currentSceneItems = ObservableList.of(this.currentSceneItems);
        this.globalAudioSceneItems =
            ObservableList.of(this.globalAudioSceneItems);
        break;
      case EventType.Exiting:
        // TODO: OBS has been closed while being connected to the WebSocket
        // need to go back to landing and inform the user with a dialog etc.
        break;
      default:
        break;
    }
  }

  @action
  _handleResponse(BaseResponse response) {
    switch (RequestType.values[response.messageID]) {
      case RequestType.GetSceneList:
        GetSceneListResponse getSceneListResponse =
            GetSceneListResponse(response.json);
        this.activeSceneName = getSceneListResponse.currentScene;
        this.scenes = ObservableList.of(getSceneListResponse.scenes);
        break;
      case RequestType.GetCurrentScene:
        GetCurrentSceneResponse getCurrentSceneResponse =
            GetCurrentSceneResponse(response.json);
        this.currentSceneItems =
            ObservableList.of(getCurrentSceneResponse.sources);
        currentSceneItems.forEach((sceneItem) => NetworkHelper.makeRequest(
            this.activeSession.socket.sink,
            RequestType.GetMute,
            {'source': sceneItem.name}));
        break;
      case RequestType.GetSpecialSources:
        GetSpecialSourcesResponse getSpecialSourcesResponse =
            GetSpecialSourcesResponse(response.json);
        if (getSpecialSourcesResponse.mic1 != null) {
          NetworkHelper.makeRequest(
              this.activeSession.socket.sink,
              RequestType.GetVolume,
              {'source': getSpecialSourcesResponse.mic1});
        }
        if (getSpecialSourcesResponse.mic2 != null) {
          NetworkHelper.makeRequest(
              this.activeSession.socket.sink,
              RequestType.GetVolume,
              {'source': getSpecialSourcesResponse.mic2});
        }
        if (getSpecialSourcesResponse.mic3 != null) {
          NetworkHelper.makeRequest(
              this.activeSession.socket.sink,
              RequestType.GetVolume,
              {'source': getSpecialSourcesResponse.mic3});
        }
        break;
      case RequestType.GetSourcesList:
        // GetSourcesListResponse getSourcesListResponse =
        //     GetSourcesListResponse(response.json);
        // getSourcesListResponse.sources.forEach((source) {
        //   print('${source.name}: ${source.typeID}');
        //   NetworkHelper.makeRequest(this.activeSession.socket.sink,
        //       RequestType.GetSourceSettings, {'sourceName': source.name});
        // });
        break;
      case RequestType.GetSourceTypesList:
        GetSourceTypesList getSourceTypesList =
            GetSourceTypesList(response.json);
        this.sourceTypes = getSourceTypesList.types;
        NetworkHelper.makeRequest(
            this.activeSession.socket.sink, RequestType.GetCurrentScene);
        NetworkHelper.makeRequest(
            this.activeSession.socket.sink, RequestType.GetSpecialSources);
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
        this
            .currentSceneItems
            .firstWhere((sceneItem) => sceneItem.name == getMuteResponse.name)
            .muted = getMuteResponse.muted;
        this.currentSceneItems = ObservableList.of(this.currentSceneItems);
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
      default:
        break;
    }
  }
}
