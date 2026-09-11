# Design direction

Status: session workspace selected, with first-class chat and user-controlled
focus (D-003). Visual style and exact interactions remain unvalidated. The
architecture comparison below records alternatives considered; it is not an
outstanding choice between A/B/C.

## Principles and rationale

- **Visible operational truth.** Distinguish inspected context, intended command
  target and OBS-confirmed state. A remote must remain understandable during
  delay, rejection, external changes and disconnection.
- **Stable context.** Session lifetime belongs above tool navigation; changes in
  viewport or selected tool must not reconnect OBS or reset drafts and filters.
- **Hierarchy before decoration.** Current state and the next useful action lead;
  typography, spacing and scope explain relationships. Visual character remains
  open until an actual journey can be evaluated.
- **Density by task.** Offer enough information for confident operation without
  making every tool compete at once. Tablet gains simultaneous work areas;
  phone gains focused access, not missing capability.
- **Intentional motion and platform adaptation.** Preserve orientation when panes
  appear; respect reduced motion, back behavior, input and accessibility on each
  platform. Do not mechanically copy another platform's components.
- **Product components after proof.** Prove scene targeting, session status,
  source control and conversation interactions before extracting reusable pieces.
  Prefer direct controls and contextual tools where they help the journey.
  Avoid decorative containment, compulsory customization and invisible gestures.

## Selected direction: one workspace, adjustable attention

The user accepted A on 2026-09-10 with a significant qualification: specialized
chat must be a first-class experience when wanted, including space for future
audience activity. A fixed scene-first hierarchy therefore does not satisfy the
accepted direction. Keep OBS objects and conversation in one stable workspace,
with explicit control over which receives attention.

Proposed first prototype behavior:

| Context | Composition and interaction |
|---|---|
| Phone, OBS focus | Scene/control workspace with a visible Chat focus action. Chat remains optional; no empty conversation panel consumes control space. |
| Phone, Chat focus | Conversation, channel context, compose/reply and contextual moderation get the main area. A compact OBS status/action area retains access to sound and scene controls. Verify its behavior with the keyboard open. |
| Tablet | OBS and chat can remain visible together. Simple emphasis presets allocate more space to either; validate a balanced arrangement as well. Preserve the same selected objects and conversation on resize. |
| Returning user | Remember explicitly chosen emphasis per device/form factor. No automatic focus change when a stream starts, an event arrives or entitlement changes. Persistence translation is deferred until the prototype proves the interaction. |
| Focus change | Preserve draft/reply, channel, scroll anchor, unread state, inspected scene and pending commands. Changing visibility does not reconnect either transport. |
| Chat unavailable | Explain entitlement, configuration, account and network state locally; retain the supported free WebView route and usable OBS controls. |

This is a small focus control, not a customizable dashboard builder. Labels,
control placement and minimum companion content need visual/interaction testing.
No new global Prepare/Operate/Review modes are introduced.

Audience activity should remain reviewable without flooding the message stream
or repeatedly taking focus. Explore a compact recent-activity surface with an
expandable history; allow a quiet presentation when the user wants conversation
alone. Existing Twitch chat notifications are verified in
`TwitchChatStore.chatNotifications` and its merged timeline. Broader event
coverage, categorization, retention and alert policy are future requirements,
not implemented capabilities or confirmed cross-platform parity. Prototype
examples must distinguish existing notices from future simulated events.

**Selected entry behavior (D-004):** users can enter and use chat before
connecting OBS. The user directed continuation after this recommendation. The
stores already manage chat transport independently; an OBS setup problem should
not make audience interaction inaccessible. Integration still needs deliberate
navigation/lifecycle work: the current dashboard wrapper depends on
`DashboardStore`.

## Architecture alternatives considered

The common scenario: already streaming from a saved connection, inspect another
scene, stage a studio preview, adjust global microphone audio, read chat, respond
to an external OBS change, then recover from a lost connection. Each concept
must handle the same scenario and both form factors.

### A — Session workspace (selected with the qualification above)

The original proposal made the active OBS session the main context. Scenes are
navigable objects; an inspector exposes their sources, while global sound and conversations are tools
available alongside that context. Inspecting an object is distinct from sending
it to preview or program. Explicit actions make those targets clear.

```text
Phone                               Tablet
Session + observed output           Session + observed output
Scene browser                       Scene browser | Scene inspector | Companion
  -> scene inspector                Program/preview remain identified
  -> Preview / Program action       Global sound or conversation alongside
Sound / Chat tools retain context   Connection recovery in the same context
```

Benefit: arbitrary OBS setups remain discoverable without configuring a control
surface. Source scope and global controls have understandable homes.

Cost: scene inspection may add a step compared with one-tap switching; a user
mainly watching chat may bypass the main workspace. Validate explicit quick
execution affordances without making inspection itself change output.

### B — Activity focus

Users deliberately switch between Prepare, Operate and Review. Prepare exposes
configuration and rehearsal; Operate prioritizes observed output, conversation
and immediate interventions; Review explores locally sampled history. Starting
a stream does not automatically rearrange controls. Full control remains
available while operating, because preparation can happen during a live session.

```text
Phone                               Tablet
Prepare / Operate / Review          Same chosen activity
Operate: output + chat              Output and chat | intervention tools
  -> persistent quick interventions Prepare: production tools side by side
  -> full controls, then return     Review: session collection + detail
```

Benefit: supports long monitoring periods without constant competition from
configuration controls.

Cost: users must understand activity boundaries and find controls across them;
“Prepare” can misleadingly sound unavailable during a live session. Keep changes
explicit and never infer mode solely from OBS streaming state.

### C — Personal control surface

The primary experience is a set of executable scene, sound and hotkey actions,
with a useful default and an always-available browse-all catalog. Users can pin
the actions that matter to them. Editing is distinct from operating. Commands
retain scoped targets and show unavailable/deleted targets clearly.

```text
Phone                               Tablet
Session + observed output           Session + observed output
Chosen actions, grouped into pages  More chosen actions visible together
  -> execute and observe state      Conversation as a companion
All controls / Chat / Edit          Browse-all catalog remains available
```

Benefit: gives repeated actions direct access and allows individual priorities.

Cost: stable routines and willingness to configure are unverified assumptions.
Configuration adds a persisted model and stale-target migration work. Default
actions cannot assume meaningful scene names or universal workflows.

## Evaluation at selection

| Criterion | A: Session workspace | B: Activity focus | C: Personal surface |
|---|---|---|---|
| Arbitrary OBS setup | Strong browsing/context | Full controls need an escape path | Depends on complete catalog |
| Prolonged monitoring | Companion can take focus | Primary strength | Depends on chosen surface |
| Repeated interventions | Clear targets; validate action count | Quick tools plus context switch | Primary strength after setup |
| Unverified user assumptions | Scene work deserves the center | Activities are meaningfully separable | Routines are stable/configuration acceptable |
| New infrastructure | Session/lifecycle adapter | Adapter plus activity state | Adapter plus persisted action configuration |
| Tablet value | Concurrent objects/tools | Concurrent tools for chosen task | Increased action capacity + companion |

The recommendation for A followed verified object relationships and lower
configuration cost. The user selected it with first-class adjustable chat focus.
That qualification changes the original fixed attention hierarchy; it does not
adopt B's activity stages or C's user-authored control surface.

## First slice and design checkpoint

Build an isolated Flutter prototype for the journeys in
[user-flows](user-flows.md), with fake session/command outcomes and functional
chat focus, draft, scroll and activity interactions, including chat-only entry. Validate phone and tablet composition
before extracting tokens or integrating transport. Production replacement follows integration and behavioral
validation of the same journey.

## Contemporary interaction references

Reviewed 2026-09-10. Android's canonical layouts distinguish object browsing with
list/detail from tools accompanying primary content, and describe preserving
selection when window size changes. These are useful vocabularies for A/B;
they do not establish OBS users' priorities or mandate Compose dependencies.
[Android canonical layouts](https://developer.android.com/develop/ui/views/layout/canonical-layouts)

Apple describes modality as temporarily preventing interaction with a parent
context. This informs our decision to examine whether routine editing needs an
interruption, rather than inheriting every dialog.
[Apple HIG: Modality](https://developer.apple.com/design/human-interface-guidelines/modality)

Exact accessibility, typography and motion choices require focused platform
guidance and rendered measurements at the prototype checkpoint. No library,
glass effect, font family or prior redesign tokens have been adopted.
