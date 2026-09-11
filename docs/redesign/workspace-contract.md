# Workspace presentation and session contract

D-003–005 establish independent chat/OBS availability, adjustable focus and explicit
scene commands. This contract describes the integration boundary; implementation
status is in `progress.md`. The original `WorkspaceModel` remains the fake fixture.

## Ownership

The workspace owns local focus, inspection, drafts and scroll position above pane
composition. Pane disposal/reparenting never connects or disconnects a transport.
A session owner holds one NetworkStore per connection attempt; replacing or
cancelling an attempt retires that owner and its listeners. This isolates the
existing store's asynchronous handshake from a subsequent session. Production
DashboardStore remains intact; no global DI or Hive migration accompanies this lab.

Chat owns platform, channel, engine, account/scopes, entitlement, history, draft and
send capability independently. OBS interruption must not clear these. Native Pro
gating and free WebView access remain required for real chat integration. Synthetic
chat in the development lab does not establish account/entitlement integration.

## First adapter boundary: scene operation

Read state: readiness (offline, synchronizing, ready, unavailable), available scene
names, OBS-confirmed program/preview, actual Studio Mode, inspected scene and
command result. No hardcoded camera or microphone can masquerade as a real source.
Name targeting retains compatibility with the existing v5 subset; collection
changes invalidate targets and outstanding reads. Source/group IDs and audio
input identity require their own subsequent contract.

Actions: inspect locally; set preview by explicit scene; send scene to program
outside Studio Mode; Take the current preview in Studio Mode; refresh after an
uncertain outcome. Preview and Take share a scene-output command scope because
concurrent changes could change Take's target. Future audio/source operations must
have separate resource scopes, rather than the fixture's single global busy flag.

Command replies match both request ID and type. A positive reply means accepted,
not a speculative program value. Program/preview come from events and reads; an
older read must not overwrite a newer event. A rejected command preserves the
last confirmed snapshot but does not imply no external change occurred. Timeout,
transport loss or replacement means outcome unknown; never automatically retry a
mutating request. Reads may refresh after a timeout. Collection-change windows
make controls unavailable until a complete fresh scene snapshot succeeds.

Take uses `TriggerStudioModeTransition`, available since WebSocket v5.0, to match
OBS's own Studio Mode Transition button. Direct Send uses `SetCurrentProgramScene`;
Preview uses `SetCurrentPreviewScene`. Existing production UI stays unchanged.
The server selects preview at execution time: there is no atomic comparison with
the preview label last seen on the phone. External operators can change it.
Source: [official OBS protocol](https://github.com/obsproject/obs-websocket/blob/master/docs/generated/protocol.md#triggerstudiomodetransition), verified 2026-09-11.

## Later integration requirements

Honor existing saved-connection, studio-control visibility, local hidden-item,
confirmation, wakelock and retry preferences before replacing production routes.
The isolated live lab may expose actual Studio Mode for validation without reading
or changing preferences. A complete production adapter must integrate the existing
DashboardStore lifecycle, telemetry/history and chat stores; the scene adapter is
an additive, bounded confirmed-state projection, not a replacement dashboard store.
