import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../../types/classes/api/scene.dart';
import '../../types/classes/api/scene_item.dart';
import '../../types/classes/api/stream_stats.dart';
import '../../types/classes/session.dart';
import '../../types/classes/stream/events/base.dart';
import '../../types/classes/stream/events/switch_scenes.dart';
import '../../types/classes/stream/events/transition_begin.dart';
import '../../types/classes/stream/responses/base.dart';
import '../../types/classes/stream/responses/get_current_scene.dart';
import '../../types/classes/stream/responses/get_scene_list.dart';
import '../../types/classes/stream/responses/get_source_types_list.dart';
import '../../types/classes/stream/responses/get_sources_list.dart';
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

  @observable
  int sceneTransitionDurationMS;

  Session activeSession;

  setActiveSession(Session activeSession) {
    this.activeSession = activeSession;
    this.initialRequests();
    this.handleStream();
  }

  initialRequests() {
    NetworkHelper.makeRequest(
        this.activeSession.socket.sink, RequestType.GetSceneList);
    NetworkHelper.makeRequest(
        this.activeSession.socket.sink, RequestType.GetCurrentScene);
    NetworkHelper.makeRequest(
        this.activeSession.socket.sink, RequestType.GetSourcesList);
    NetworkHelper.makeRequest(
        this.activeSession.socket.sink, RequestType.GetSourceTypesList);
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
        break;
      case EventType.TransitionBegin:
        TransitionBeginEvent transitionBeginEvent =
            TransitionBeginEvent(event.json);
        this.sceneTransitionDurationMS = transitionBeginEvent.duration;
        this.activeSceneName = transitionBeginEvent.toScene;
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
        break;
      case RequestType.GetSourcesList:
        print(response.json);
        GetSourcesListResponse getSourcesListResponse =
            GetSourcesListResponse(response.json);
        break;
      case RequestType.GetSourceTypesList:
        // debugPrint(response.json.toString(), wrapWidth: 1000000);
        // GetSourceTypesList getSourceTypesList =
        //     GetSourceTypesList(response.json);
        break;
      default:
        break;
    }
  }
}
