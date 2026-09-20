# Stale-state honesty (astra phase 3, wave 2) — design

Date: 2026-09-20 · Status: ratified (design approved in brainstorm) · Branch target: `4.0-liquid-glass`

## Context

The ordering wave (astra phase 3, wave 1, merged `191f1f13`) made displayed
state *correct* — events beat stale reads via `EventOrdering` epochs +
journals + FIFO read tags. But it is still not *honest*: during a reconnect
(socket dead, `_checkOBSConnection` looping, `DashboardStore.reconnecting ==
true`) the dashboard keeps rendering scene/item/audio values as if live.
Taps on controls send mutations into a dead socket where the intent is
silently lost (no ack, no queue, no retry), and the only signal is a small
toast saying "OBS connection lost / Reconnecting...".

Astra's design lab (`lib/redesign/`) proved the honesty model: **stale is
never time-based** — it means "the confirmation channel for this value is
gone". Its surfaces keep values fully visible, label them as last known,
shift live accents to neutral, disable controls, and say plainly that the
state is stale. This wave ports that concept (not astra's code) onto the
merged ordering machinery.

Ratified in brainstorm (2026-09-20):

- **Scope: reconnect-driven staleness only.** The single driver is
  `DashboardStore.reconnecting`. No per-row failed-read freshness (deferred),
  no pending/busy indicators (rejected — contradicts the ratified
  "optimistic UX stays" decision from wave 1).
- **Controls disable while stale.** Optimistic taps on a dead transport are
  silently lost intent; honest lockout + last-known values beats phantom
  interactivity. Astra does the same.
- **Per-pane labeling** (not a global banner): Scenes, Scene Items, and
  Audio panes each surface the stale state next to the values it describes;
  works identically on phone tabs and tablet side-by-side.
- **Architecture A:** one store predicate + `sendMutation` chokepoint guard
  + per-pane `Observer` bindings. Rejected: B (per-domain freshness flags —
  YAGNI at this scope), C (presentation-only — untestable, no seam).

## 1. The predicate

`DashboardStore`:

```dart
/// Displayed OBS values may not reflect OBS's actual state and mutations
/// cannot be delivered - the confirmation channel (the socket) is down.
/// Single driver today: reconnect loop active. Future drivers plug in here
/// (collection-changing window, terminated-but-still-mounted) without
/// touching widgets.
///
/// Deliberately a plain getter, NOT @computed: reactions/Observers track
/// the `reconnecting` read through it identically, and no build_runner
/// regen (dashboard.g.dart) is needed.
bool get obsStateStale => this.reconnecting;
```

## 2. The guard (backstop)

`sendMutation` early-returns while `obsStateStale`:

- Nothing is sent (the socket is dead anyway).
- Returns a synthetic **not-sent** `ObsRequestAck` — distinguishable from a
  real failure (a flag or named constructor, e.g. `ObsRequestAck.notSent()`).
- The ack layer's failure machinery must SKIP not-sent acks: no
  `_resyncAfterFailedMutation` re-read (transport is dead; the reconnect
  burst re-reads everything — and lands immediately thanks to the
  dead-transport tag wipe, `191f1f13`) and no failure toast.
- Implementation-time check: enumerate every caller awaiting a
  `sendMutation` future and confirm none surfaces the not-sent ack as a
  user-visible error. (Most call sites are unawaited.)
- Fire-and-forget paths that bypass `sendMutation` (slider ticks) are
  covered by the visual disable only — a disabled slider cannot tick.
  Documented, accepted.

## 3. Per-pane surfaces (UI)

- New small reusable `StaleStateBadge` in `lib/shared/` — "LAST KNOWN"
  label, On Air design-system tokens (neutral text color,
  `AppMotion.medium` fade), no custom styling outside the token layer.
- Shown via `Observer` on `obsStateStale` in the pane headers of:
  Scenes, Scene Items, Audio (exact anchor widgets identified in the plan).
- **Values are never dimmed, hidden, or color-altered** — astra's honesty
  rule: the label and the disabled controls carry the signal; the state
  itself stays fully readable.
- `ReconnectToast` copy upgrade: "OBS connection lost — values shown are
  the last known state. Reconnecting..." (keep the "Reconnected!" flash;
  drop the `advLog('RECONNECTING!!!!!')` debug line while touching the
  file).

## 4. Control disabling

While `obsStateStale`, disabled: scene buttons, scene-item visibility
toggles, audio sliders + mutes, studio-mode checkbox + transition button,
transition controls, record/stream buttons, hotkeys, replay buffer
controls. Mechanism per control in the plan (`onPressed: null` where the
widget supports it, else `IgnorePointer` + control-level opacity). The
disabled look applies to **controls only, never values**.

## 5. Re-enable flow

`reconnecting = false` on reconnect success → predicate false → badges fade
out, controls re-enable. The reconnect burst (`initialRequests`, with the
D1 wipe) re-confirms all values immediately. No additional work.

## Edge cases (design decisions, not open questions)

- **Unlimited-reconnects setting:** stale can last arbitrarily long —
  badges persist; correct by construction.
- **`obsTerminated`:** the app navigates Home; stale surfaces are moot.
- **Collection-changing window:** NOT flagged stale this wave (values from
  the old collection remain visible briefly). The predicate is the
  documented seam if a later wave wants it.
- **Stats pane:** numbers freeze during reconnect; not labeled — the toast
  already tells the connection story. Considered, skipped (YAGNI).
- **Screen readers:** the badge is a semantic label change in the pane
  header, announced naturally; no `liveRegion` work this wave.

## Testing

- `test/websocket/` (fake peer, existing patterns):
  - Predicate: `reconnecting = true` → `obsStateStale` true; false → false.
  - Guard: while stale, `sendMutation` puts nothing on the wire
    (`peer.requests` unchanged), returns the not-sent ack, and triggers no
    re-read and no toast path; after flipping back, sends flow normally.
- Regression: the ordering suite (46 tests) stays green — the guard is
  inert when not stale.
- Gates per AGENTS.md: `test/websocket/` during the wave; full suite +
  analyze (472 baseline) at wrap-up; dart format. Visuals = user dogfood
  (kill the OBS connection mid-session: badges appear, controls lock,
  values persist; reconnect → snap back).

## Wave structure (commit per verified unit; S-tier per AGENTS.md)

1. Store predicate + `sendMutation` guard + tests.
2. `StaleStateBadge` + per-pane bindings + control disabling + toast copy.
3. Full gates, changelog + handoff, push; dogfood note for the user.

## Risks

- **An awaiting caller misreads not-sent as failure** → user-visible error
  during reconnect. Mitigation: explicit caller enumeration in the plan +
  the guard test asserting no toast/re-read path fires.
- **A missed control stays live** → intent lost into the dead socket (today's
  behavior, not a regression). Mitigation: the `sendMutation` guard is the
  backstop regardless of visuals; the plan enumerates the mutation surfaces
  from the `sendMutation(` call-site grep.
- **Badge anchors differ between phone/tablet layouts** → plan verifies
  each pane's header widget exists in both compositions
  (`ResponsiveWidgetWrapper` paths).
