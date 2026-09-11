# Isolated live OBS scene lab

`lib/main_redesign_obs.dart` binds the validated workspace composition to the
existing OBS WebSocket v5 handshake/transport. It is a development entrypoint;
production navigation, Hive, saved connections, accounts and purchases are not
initialized. Chat and activity are explicitly simulated. Only OBS scene operations
are integrated; unsupported source/audio controls and fake uptime are hidden.

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

## Native checkpoint — 2026-09-11

Passed on temporary iPhone 17 Pro and iPad Pro 13-inch simulators (iOS 26.5).
The test tapped scene inspection, Preview and the persistent Take button through
the rendered UI. It confirmed observed program/preview and retained chat draft
and reply after disconnect. Both simulators were removed after capture.

Screenshots, with synthetic OBS/chat data:
[phone scenes](prototype-shots/phone-native-scene-control.png),
[phone chat after disconnect](prototype-shots/phone-native-chat-after-disconnect.png),
[tablet scenes with chat](prototype-shots/tablet-native-scene-control.png),
[tablet chat after disconnect](prototype-shots/tablet-native-chat-after-disconnect.png).

Visual review found and removed a remaining simulated microphone in the live
scene browser; the native test now asserts its absence. Phone retains visible
Preview/Take controls, tablet retains concurrent conversation, and draft/reply
remain visible after disconnect. The incomplete inspector is intentionally sparse
until source/audio integration; wide-pane duplicate Disconnect actions remain a
composition refinement. These screenshots do not validate final content density,
Android, actual chat authentication/Pro, or an installed OBS server.
