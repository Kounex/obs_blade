# Product model

Evidence baseline: master commit recorded in [README](README.md), inspected
2026-09-10. This describes implemented capabilities, not usage frequency or a
chosen interface. See [business-logic-map](business-logic-map.md) for source seams.

## Purpose and user goals

OBS Blade remotely operates and observes an OBS Studio instance through OBS
WebSocket v5. Users can connect to a production, change what OBS presents and
captures, manage sound, follow or participate in chat, and review locally recorded
telemetry. iOS and Android phones and tablets are first-party targets.

The source supports both active operation and prolonged monitoring. It does not
establish which dominates, how many users moderate chat, or which controls are
frequent. Do not invent personas or usage percentages to settle design choices.

## Entities and state

| Concept | Meaning and important distinctions |
|---|---|
| Saved connection | Endpoint, optional name/password/SSID, port and domain flag. Discovery, manual entry and QR are ways to obtain an endpoint, not different products. |
| OBS session | One active transport and connection. Transport existence does not mean authenticated or synchronized. Initial failure, retrying, manual exit and OBS termination differ. |
| Production configuration | OBS profile and scene collection; changing collection temporarily suspends event/response application and polling. |
| Scene | Program is what OBS outputs; preview is the staged scene in studio mode. Local hidden-scene preference is not an OBS deletion. |
| Scene item | A source occurrence scoped to a scene or parent group. Local hiding differs from changing its OBS enabled state. Filters can be enabled and edited. |
| Audio input | Mute, level, volume and sync offset. Global inputs and inputs associated with scene content have different scopes. |
| Outputs | Streaming, recording (including paused), replay buffer and virtual camera. Starting a command is not confirmation that an output changed. |
| Other controls | OBS hotkeys, transitions, profile/collection changes, screenshots. A media-input model exists, but the current media-input widget renders an empty list; transport controls are not verified implemented behavior. |
| Conversation | Chat platform, destination and rendering engine are separate choices. Twitch channels and YouTube video destinations are not interchangeable identifiers. |
| Account/capability | Authentication, OAuth scope, role, platform support and Pro entitlement independently determine available actions. |
| Session history | Locally observed stream/record samples with summary/detail, naming, favorites and deletion. It is not an OBS recording file or guaranteed complete session record. |

## Persistence and customization

Hive CE stores connections; stream and recording history; custom themes; hidden
scenes/items; logs; tips; hotkeys; Twitch/YouTube authentication; and settings.
`lib/main.dart` registers models and opens boxes. `TypeIDs`, Hive field indices,
enum adapters, box names and explicit settings-key strings are compatibility
contracts. Preserve old data independently of how new widgets expose it.

Preferences include wake lock, retry policy, studio awareness, monitoring layout,
control exposure/order, app-only scene/item hiding, chat platform/engine/channel,
chat readability/decorations, suppressible confirmations, theme/brightness and
tablet override. Their intent matters; historical screen names and color slots
do not dictate the new composition. Define translation before migrating them.

Pro is evaluated by `ProStore.isPro`; the RevenueCat path observes current
entitlement state and mirrors it offline. Legacy purchase paths remain in source.
Native chat is gated in presentation; platform stores can connect independently.
WebView chat remains available without Pro. Custom themes accept legacy
Blacksmith ownership or Pro. Purchase IDs and restore behavior must survive.

## Edge cases that shape the redesign

- OBS creates a session before authentication finishes; readiness needs its own
  state. Authentication failure should preserve useful endpoint input for repair.
- Discovery currently requires Wi-Fi and available network information; an empty
  scan cannot establish that OBS is absent. Preserve manual/QR recovery paths.
  QR parsing accepts OBS Connect Info schemes and optional passwords; camera
  permission is a separate prerequisite from network access.
- OBS changes can originate elsewhere. Show authoritative state and distinguish
  stale, requested and confirmed values; the existing command API is fire-and-forget.
- Reconnecting must preserve context without implying that stale output data is
  live. Manual exit must end retry ownership deliberately.
- Studio targeting currently depends on both actual OBS studio mode and an app
  preference. Do not silently change that behavior while replacing scene buttons.
- A source in a group needs the parent group as command target. Display names
  alone are insufficient identity.
- Chat can be usable for reading but unavailable for sending; quota exhaustion,
  ended streams, missing configuration, expired login and insufficient moderation
  scope need different recoveries. YouTube destinations refer to individual videos.
- Chat drafts survive send errors; channel buffers, moderation tombstones and
  scroll position have intentional lifetime independent of their widgets.
- History excludes very short finished sessions, and paused recording skips
  samples. Describe gaps honestly.

Known baseline defects and unverified seams are in
[current-ui-assumptions](current-ui-assumptions.md); they are not preservation
requirements.
