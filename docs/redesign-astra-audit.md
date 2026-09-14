# Astra redesign — audit + verdict (2026-09-14)

Audit of the sibling first-principles redesign: branch `redesign-astra`
(master base `23070815`, tip `54141fe1` + uncommitted emote-picker WIP),
developed in isolation under its own governing docs (`docs/redesign/` in that
clone: README, decisions, design-direction, contracts, progress).

**Verdict, ratified by the user 2026-09-14: progressive adoption** — keep the
shipped On Air / 4.0 visual identity, adopt astra's interaction + state
architecture in stages. The workspace shell stays a design lab, not a merge
candidate. Details + staging below.

## Method

Three passes: (1) code audit of `lib/redesign/` (26 files, ~5.4k lines) + the
three lab entrypoints; (2) digest of astra's nine governing docs; (3) review
of the 22 prototype captures (phone + tablet). Every claim astra's docs make
about master's UI was verified against master source, with `4.0-liquid-glass`
status noted.

User inputs that shaped the verdict: the workspace structure is compelling
("OBS control and chat separate is a big win"); the current UI's visuals are
preferred (transition-fading scene buttons named explicitly); adoption scope
decided after this audit.

## What astra actually is

Not a visual redesign — its docs defer all visual decisions ("visual
character remains open"; no tokens, glass, or font adopted) and the code
confirms it: one hardcoded dark theme, five color constants copy-pasted into
three files, default Material typography, no motion design. Astra is an
**interaction + state architecture** prototype: a session workspace where OBS
control and chat share one stable context with user-controlled focus (phone:
OBS | Chat; tablet: + Together), validated on iOS simulators against a
loopback synthetic OBS peer and synthetic chat stores (859 tests / 108
redesign at the final gate per its session-handoff).

## What astra gets right (evidence-backed)

1. **Session above navigation.** Session lifetime owned by a session object,
   not widget mounting (master's is route-owned — confirmed defect). Focus
   switches and phone↔tablet resizes preserve drafts, composer and scroll
   state (IndexedStack + shared GlobalKeys, test-verified).
2. **Chat independent + first-class.** Usable before/without OBS, survives
   OBS disconnect; tablet Together mode; phone header keeps program pill +
   quick mic while chat has focus.
3. **Confirmed-vs-requested state** (`lib/redesign/obs/`): never assigns from
   an ack — re-reads; revision counters so events beat stale reads; no
   auto-retry of mutations; explicit RECONNECTING · STALE surfaces.
   Protocol-verified against a loopback v5 peer in tests. Arguably better
   than master's optimistic writes.
4. **Inspect ≠ command.** Scene row tap = inspect; labelled Preview / Send
   live; persistent Take dock using the correct `TriggerStudioModeTransition`
   request. Fixes master's browsing-changes-output hazard.
5. **Conversation-owned chat composition.** Drafts keyed by
   (platform, account, channel); sends serialized against channel switches;
   revision-guarded modal edits; entitlement re-checked at action time; typed
   timeline preserves production DTOs; honest read-only gate states.
6. **Engineering discipline.** Zero GetIt in redesign code (constructor
   injection), pure projection functions, no TODOs, docs disciplined about
   what each evidence level does and does not establish.

## Where astra is weak / unproven

- **A slice, not an app:** no routing, no saved connections, no stream/record
  controls, no statistics/history, no settings, no themes, no connect flow;
  moderation/user-cards/pins/appearance only partially bound.
- **Unvalidated:** Android entirely (all native checks were iOS sims), real
  installed OBS, real chat APIs, accessibility (VoiceOver/TalkBack), purchase
  flows.
- **Prototype-grade seams:** `WorkspaceModel` doubles as fake fixture and
  live-model base; copy-pasted color constants; breakpoints 900/600/360
  conflicting with production's 700; dense MobX-autorun-inside-ChangeNotifier
  plumbing with build-time mutations in the timeline.
- **Product trade-offs to feel in hand:** phone never co-displays OBS + chat
  (focus fully swaps); scene switching gains a step vs today's one-tap
  (safety vs speed).

## Verified master defects astra surfaced

All six confirmed against master source; **none fixed on `4.0-liquid-glass`**
(4.0 is a token/surface restyle over identical structure):

| # | Defect | Evidence |
|---|---|---|
| 1 | Scene tile multiplexes hide-edit + optimistic selection + live command on one tap | `scene_button.dart` (master ~:68-85, 4.0 :74-96) |
| 2 | "Studio mode transition" button sends `SetCurrentProgramScene`, not a transition request | `studio_mode_transition_button.dart` (:68-76) |
| 3 | Command layer fire-and-forget: `makeRequest` returns void, failures log-only, optimistic scene state never rolled back | `network_helper.dart:322-356`, `dashboard.dart` `_handleResponse` |
| 4 | Chat WebView gesture arbitration hardcodes Y 150–450 | `stream_chat.dart:513-514` |
| 5 | Statistics: `DurationFilter.Between` returns true for everything; filter state reset on every rebuild (`resetLazySingleton` in `build`) | `statistics.dart` (:188, :211) |
| 6 | "Delete all user data" omits `PastRecordData`, `Hotkey`, `PurchasedTip` boxes | `data_management.dart:31-53` |

## What to keep from the current UI

- **The visual identity** — On Air tokens + 4.0 glass/tally refinements. The
  user-named "fading scene buttons" are real engineering: `SelectableBox`'s
  fill fade is driven by the **live OBS transition duration**, crossfading in
  sync with the actual transition (`scene_button.dart` on both branches;
  master = solid accent fill, 4.0 = 10% program tint + ring + tally chips).
- The user-reorderable dashboard element layout (`DashboardElementsOrder`),
  the scene tile grid idiom, the 4.0 glass/token layer, and the whole app
  skeleton astra never rebuilt (connect flow, settings, statistics, themes,
  routing).

## Harvest list (already written + tested on the astra branch)

Production-file changes, backward-compatible, independently valuable —
cherry-pick candidates:

- `twitch_chat.dart` (+33/−6): send-race ownership fix (capture
  destination/reply before awaiting token refresh).
- `youtube_chat.dart` (+60/−15): same send-ownership fix + buffer retirement
  when a saved video is replaced/removed.
- `request_type.dart` (+3): `TriggerStudioModeTransition` — enables fixing
  defect #2.
- `network_helper.dart` (1 line): guard so custom envelopes don't pollute the
  static request-body map.
- Three shared chat rows (+30): optional injected catalog stores (DI seams).
- Dirty tree (finish first): `chat_emote_picker.dart` injected stores/settings
  + real emote-insertion spacing fix (`hiKappa` → `hi Kappa`).

**Sequencing note:** 4.0's tree-wide format migration means landing these on
master now guarantees merge friction with `4.0-liquid-glass`. Land them on
the 4.0 branch or right after it merges.

## Verdict + staged path

**Progressive adoption** (ratified 2026-09-14):

1. **Harvest** the production fixes above; fix the six verified master
   defects (independent of UI direction; #3 is the strategic one — the
   missing command-acknowledgement layer).
2. **After 4.0 merges**, port into the dashboard wearing the 4.0 skin:
   confirmed-state OBS projection (additive, next to DashboardStore), scene
   inspect-vs-command separation + persistent Take bar, chat independence +
   conversation-owned drafts, stale-state honesty in reconnect surfaces.
3. **Astra stays a design lab.** Its remaining roadmap (account/setup,
   stream/record, settings hosting) only earns its keep if full shell
   replacement becomes a live candidate — revisit as a 5.0 decision with real
   usage evidence from the ported pieces, not prototype promise.

**Not adopted:** astra's provisional visuals, its 900/600/360 breakpoints,
the `WorkspaceModel` fake/base duality, the no-routes navigation model.

## Open threads

- Astra's tree has an uncommitted emote-picker unit mid-flight; letting that
  agent park after its current unit is consistent with the lab role.
- User to run the three labs (`lib/main_redesign*.dart`) to feel the two
  trade-offs above before the porting phase.
- Porting phase needs the preference-translation design astra deferred
  (hidden scenes, studio-control visibility, confirmations, wakelock, retry).
