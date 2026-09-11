# Isolated live OBS workspace lab

`lib/main_redesign_obs.dart` binds the validated workspace composition to the
existing OBS WebSocket v5 handshake/transport. It is a development entrypoint;
production navigation, Hive, saved connections, accounts and purchases are not
initialized. Chat and activity are explicitly simulated. Scene operations, scoped source visibility and
actual input mute/volume are integrated. Fake uptime is hidden.

## Run on a native target

```sh
flutter run --target lib/main_redesign_obs.dart \
  --dart-define=OBS_HOST=<hostname> --dart-define=OBS_PORT=4455
```

Select the intended simulator/native target with Flutter's `-d` option if needed.
Enter the OBS WebSocket password in the connection pane. Do not put credentials in
build defines or tracked files. Nothing connects automatically. Connect then inspect
scenes, Preview, and Take (or Send live outside Studio Mode). These buttons affect
that OBS instance. Use a test collection when exercising output actions.

The host/port defines are temporary lab configuration, not the intended product's
connection flow. Native transport uses `dart:io`; the existing browser preview at
`lib/main_redesign.dart` remains fully simulated. Automatic retries, endpoint editing,
discovery/QR and saved preferences are not implemented in this live lab.

## Implementation boundary

- `obs_workspace_session.dart`: owns each identified attempt and retires listeners.
- `obs_request_client.dart`: request correlation, timeout/disconnect outcomes.
- `obs_scene_controller.dart`: confirmed scene list/output, local inspection,
  collection-change suspension, event/read ordering, explicit scene commands.
- `obs_source_controller.dart`: inspected scene/group item identity, hierarchy,
  per-item confirmation and collection invalidation.
- `obs_audio_controller.dart`: audio capability discovery, actual input identity,
  independent mute/volume confirmation and event/read ordering.
- `live_workspace_model.dart`: transitional development binding to the prototype;
  inherits only local focus/chat fixture behavior. It is not the real chat adapter.
- `workspace-contract.md`: canonical state/actions, ownership and remaining seams.

GetSceneList ordering uses the existing Scene DTO and descending `sceneIndex`, as
master does. Requests reuse NetworkHelper's custom envelope support; such envelopes
skip its legacy Get-request context cache, since the correlated client owns them.
The existing production helper call path and DashboardStore remain unchanged.

## Validation

The focused request/controller/session tests include real loopback WebSocket I/O
with a synthetic peer. They establish handshake, reply correlation, Preview/Take,
event/read ordering, failure handling, cancellation and chat-context retention.
They do not establish behavior against an installed OBS build or real chat APIs.

Native checkpoint runner (use an isolated simulator):

```sh
flutter test integration_test/workspace_scene_lab_test.dart \
  -d <simulator-id> --no-uninstall
```

It starts a synthetic peer inside the test, initializes only the lab, and captures
PNG files under the app's temporary `workspace_scene_shots/` directory. It never
starts OBS, loads real accounts or opens production Hive boxes. See `progress.md`
for the latest executed checks; a runnable test is not itself a passing result.

## Source/audio native checkpoint — 2026-09-11

Passed on temporary iPhone 17 Pro and iPad Pro 13-inch simulators (iOS 26.5).
The test exercises scene inspection, Preview/Take, grouped Logo visibility without
changing another item with the same numeric ID, Desk mic mute, Music volume, and
quick audio from chat focus. Chat draft/reply survive the sheet and OBS disconnect.
Both temporary simulators were removed after capture.

Screenshots with synthetic OBS/chat data:
[phone source/audio](prototype-shots/phone-native-source-audio.png),
[tablet source/audio](prototype-shots/tablet-native-source-audio.png),
[phone quick audio](prototype-shots/phone-native-chat-quick-audio.png),
[tablet quick audio](prototype-shots/tablet-native-chat-quick-audio.png),
[phone scenes](prototype-shots/phone-native-scene-control.png),
[tablet scenes](prototype-shots/tablet-native-scene-control.png),
[phone chat after disconnect](prototype-shots/phone-native-chat-after-disconnect.png),
[tablet chat after disconnect](prototype-shots/tablet-native-chat-after-disconnect.png).

The phone review exposed a scrolling return action; Back to scenes now stays above
the inspector. The duplicate wide-pane Disconnect was removed. Tablet source/audio
and conversation coexist; phone quick audio retains the chat context beneath it.
The controller preserves reported levels above 100%; the slider retains master's
0–100% adjustment range and labels an out-of-range OBS value explicitly. A refresh
cancels local drag presentation rather than retaining an unconfirmed level.

These checks do not validate an installed OBS server, Android, real chat APIs,
authentication/Pro, final content density or complete accessibility. Advanced audio
(meters, sync offset), source filters and app-only hidden-item preferences remain
unintegrated. Production routing and lifecycle remain unchanged.
