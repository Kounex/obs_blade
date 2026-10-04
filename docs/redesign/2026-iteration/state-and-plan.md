# 4.0 UI Iteration — State & Plan

**Shipped:** the "restrained Liquid Glass" 4.0 rework merged to `master`
2026-09-22 and shipped as 4.0.0 — the `4.0-liquid-glass` branch is history.
This doc keeps what is still actionable: the goal, the ratified design law,
the unbuilt items, and the open (Phase-4-owned) decisions. Process history,
gate reports, and the artifact map are archived under
`docs/archive/redesign/`.

## The goal

OBS Blade 4.0 is a major-release UI/UX iteration of the whole app (Flutter,
iOS/Android, phone + tablet, 500k+ users). Target: feels like a 2026 app — fluid
motion, simplicity, clean color mapping — without regressing the tablet experience
(product requirement). The ratified direction is **"restrained Liquid Glass"**:
glass+blur only on truly floating layers (nav bars, tab bar, sheets), no
aurora/glow, ≤1 specular line per floating surface, one accent moment per screen.

## What is RATIFIED (do not re-litigate without a genuine defect)

- The restrained Liquid Glass direction itself (user-approved).
- The color grammar (token-delta §1): state colors from `AppStatusColors` (never
  the themable accent); accent = selection/brand; highlight = control states +
  transient affordances; green = streaming-live only; toasts = near-opaque solid.
- One accent moment per screen; glass only on floating layers; spring release only
  on ≥44pt targets; decorative icon tiles neutral.
- **Color groups, uniform across elements AND platforms** (user, 2026-09-09 —
  token-delta §1 rule 8): every colored element resolves to a named group token,
  identical on iOS/Android, no framework-default leaks; the group set is the
  future per-group CustomTheme surface.
- Composition model of the connected view (one view, many states — NOT separate
  pages per feature).
- **Token values in `token-delta.md` — that doc wins every conflict** (report
  mismatches as defects instead of averaging). Changing a ratified value needs
  measurement, not taste.

## Process rule (user-directed, standing)

**Evaluation/critique findings are triaged to the user BEFORE anything is
applied.** Present findings with a recommendation; the user approves, adjusts or
rejects; only then build. Applies to mock changes, token/contract changes, and
doc amendments that follow from findings. (Ratified 2026-09-09 after a Gate-1
finding — the cool-tint card — was applied without user review and had to be
reverted. Taste-affecting changes are the user's call, always.)

## Known unbuilt items

Everything the token-delta contract calls for that 4.0 does **not** ship, with
the reason each exists and the reason it is deferred. None of these are
regressions — they are contract items the styling wave deliberately did not
absorb, or open decisions that were never ratified for build.

### A. Ratified contract items, deferred (token-delta §5)

> **Status 2026-09-26:** item 1 shipped in a different shape — no scrim;
> `DashboardStore.sendMutation` refuses sends while `obsStateStale`,
> `StaleGuard` disables controls, `StaleStateBadge` / the health pill say
> "LAST KNOWN STATE", LIVE/REC pills go neutral. Item 4 resolved with it:
> `ReconnectToast` is now only a tokenized "Reconnected to OBS" flash.
> Items 2 and 3 remain open.

1. **Reconnecting: blocking scrim + inert command handlers.**
   *What:* when the OBS socket drops, the connected view must put an
   input-blocking scrim over the content area and make every OBS-command
   control inert — scene tiles, transition, sliders, eye/lock/mute, chat send,
   **and the LIVE/REC pills** — to pointer *and* keyboard/assistive input
   (guarded command handlers, not pointer-events alone). A neutral "reconnect
   status" pill (single pulse on appear) anchors below the pills row. Only
   navigation (Close, navbar menu, tab bar) stays live.
   *Why it exists:* an armed green LIVE pill over a dead connection asserts
   "you're live" when you are not — the worst lie a remote can tell mid-show;
   and commands fired into a dead socket fail silently, so the UI must not
   offer them.
   *Built already:* the neutral **unknown state** for the LIVE/REC pills
   (gray dot + label, no breathe) rides the existing store observable.
   *Why deferred:* the scrim + guarded handlers are state/interaction logic
   across `DashboardStore`'s command paths, not styling — half-guarding them
   in a styling wave was the risky option.
   *Needs:* a command-dispatch guard (one choke point), the scrim widget, the
   status pill, semantics audit.

2. **Auth-failed error-card toast with "Edit password" action.**
   *What:* on OBS authentication failure, a near-opaque error card with an
   **"Edit password"** action that routes to the Connect view's Manual pane
   *and moves focus there*, plus a × dismiss; manual-dismiss only; a 1px
   red-tinted hairline on all four sides carries "error" (the v11 left-edge
   bar was killed — user: "generic template chrome"); hidden toasts leave the
   semantics tree entirely.
   *Why it exists:* today an auth failure strands the user on a generic
   message with no path to the one field that fixes it; the action turns a
   dead end into a one-tap recovery.
   *Why deferred:* it is **unbuilt functionality** (routing + focus management
   + semantics), not a restyle of an existing surface — the app has no error
   toast of this kind at all.
   *Needs:* new toast widget on the toast contract, route + focus handoff to
   the Manual pane, a11y pass on show/hide.

3. **Paywall equivalence line ("$4.17/mo" under the yearly price).**
   *What:* the mock shows the per-month equivalence on the yearly card so
   BEST VALUE is a number, not an adjective.
   *Why deferred:* the purchase gateway's `ProProduct` carries only a display
   `priceString` ("$49.99") — numeric prices are not plumbed through, and
   parsing a localized currency string is exactly the fragile path we refuse
   to take.
   *Needs:* expose numeric price through the gateway (RevenueCat
   `StoreProduct.price` / `pricePerMonth`; legacy direct-IAP
   `ProductDetails.rawPrice`), divide, format per locale.

4. **Reconnect toast off-token (motion + colors).**
   *What:* the existing reconnect toast still animates on a hardcoded
   500ms/easeOut and uses red/green borders instead of `AppMotion` + status
   tokens.
   *Why deferred:* §5 relocates reconnect status to the pill below the pills
   row (item 1) — re-tokenizing chrome that the same contract then
   repositions is rework. Resolves together with item 1.

### B. Open decisions (token-delta §6 — never ratified for build, Phase-4 owned)

5. **Chat-bar frame (§6.3).** The densest cluster in the app — engine switch,
   channel dropdown, emote picker, mod actions, send — was never modeled in
   the mock, so 4.0 leaves it alone. A design pass of its own in the Phase 4
   spec.
6. **Data-viz color slot (§6.5).** Every statistics chart shares chrome-blue,
   which encodes nothing. The categorical slot decision (+ axis-label dedupe)
   is open, so chart colors are deliberately untouched.
7. **Tablet composition (§6.1).** Tablet layout rules (640 cap vs
   multi-column, side-by-side pairing, scene-grid breakpoints, carousels →
   grid, statistics master-detail, landscape) are unmocked and unratified.
   4.0's tablet requirement was *no regressions* — verified by the
   iPad walk — not a tablet redesign; that is the biggest Phase-4 item.

### C. Framework ceiling (documented in code, not fixable in-app today)

8. **GlassBar saturate garnish + reduced-transparency fallback.** The glass
   spec's saturation pass and the accessibility fallback for reduced
   transparency are not expressible in Flutter 3.44 — no `ImageFilter` color
   pass over the blur, no `MediaQuery` reduced-transparency flag. Documented
   in `lib/shared/design/glass_bar.dart`; revisit on an SDK bump.

## Open decisions (owned by the Phase 4 spec — token-delta §6)

Tablet composition (biggest gap), light-theme + True Dark derivation pass,
chat-bar frame, Streaming Mode, data-viz color slot, haptics tokens, scene-tile
identity, **migration strategy**, **token-debt sequencing**.
