# Workspace interaction prototype

Status: first rendered checkpoint verified, 2026-09-11. This is an isolated
fake-state Flutter experience for D-003/D-004, not production migration or a
final visual system.

## Scope and boundaries

`lib/main_redesign.dart` is the independent entrypoint;
`lib/redesign/workspace/` contains the UI and in-memory `WorkspaceModel`.
No production startup, Hive boxes, accounts, purchases or network sessions are
opened. Synthetic messages, audience activity and OBS outcomes are labelled in
the lab. Focus preference lasts for this run; device persistence is future work.

The prototype exercises OBS and chat focus, simultaneous tablet panes, explicit
scene inspection versus preview/program changes, global sound, chat draft/reply,
scroll pause, recent activity and independent connection recovery. It does not
promise background execution, real event subscriptions or moderation integration.

## Local web preview

Run from this branch's worktree, after Flutter dependencies are available:

```sh
flutter build web --no-wasm-dry-run --no-web-resources-cdn --target lib/main_redesign.dart --output build/workspace_lab
cp tool/workspace_lab/index.html build/workspace_lab/index.html
python3 -m http.server 49160 --bind 127.0.0.1 --directory build/workspace_lab
```

Open `http://localhost:49160`. The separate lab HTML replaces only ignored build
output; it does not change the production web entrypoint. Browser resizing tests
composition; native keyboard, accessibility and plugin behavior still require
later iOS/Android device validation. Never run this entrypoint through production
startup just to obtain fake state.

## Interaction contract under exploration

- Focus and connection availability are orthogonal. Chat stays available when
  OBS is disconnected, connecting, failed or reconnecting.
- Inspecting a scene does not change program/preview. A dispatched command
  captures its target. Studio take uses preview; direct program uses inspection.
- Only a simulated successful result changes confirmed control state. Rejection
  leaves it intact; OBS exit invalidates in-flight results. External OBS changes
  can supersede pending local actions.
- Source visibility is scoped to the inspected scene in this small fixture;
  production groups/IDs still need a richer adapter contract.
- Chat sends serialize. Failure keeps draft/reply; success clears them. OBS
  availability and focus changes do not own chat state.
- Chat scroll anchor and input controller should survive focus/viewport changes.
  Incoming activity must not pull a reader away from scrolled-up content.

These semantics guide exploration; `WorkspaceModel` is not the final adapter
interface. Fake timing and results are not evidence of production capabilities.

## Validation checklist

- Phone OBS and Chat at compact and typical widths; tablet together and emphasis
  presets. Long labels and large text must not create overflow.
- Inspect another scene without changing output; preview then take; simulate
  rejection, delay and an external change.
- Begin chat reply/draft → open audio → return → switch focus → resize: preserve
  the input and reading position. Send failure remains recoverable.
- Chat-only entry; wrong password repair; reconnect while continuing chat;
  cancel a pending connection or leave a reconnect without resurrection.
- Activity inspection and quiet presentation without losing conversation.
- Browser screenshots and semantics inspection at the complete composition
  checkpoint; focused model/widget tests for state continuity and async edges.

## Verified results

- Web release build passed. Targeted analysis of entrypoint, prototype and its
  tests: no issues. Full baseline plus redesign gate: **764 tests passed**.
  Two subsequent accessibility-only changes (composer label and volume formatter)
  were checked with the **26-test redesign suite**, targeted analysis and rebuild.
- Widget checks cover 360×640, 390×844, 820×1180, 900×700 and 1180×820 at
  150% text scale; a keyboard-inset/failed-draft case; controller identity and
  reply/draft retention through focus changes and resizing; chat-only sending;
  persistent output action and scene inspection semantics.
- Browser inspection covered phone OBS/chat, tablet emphasis/together,
  independent reconnect with chat visible, draft retention after audio access
  and resize, and repair of the simulated password failure.
- Refined defects: compact chat overflow; output action below the fold; scene
  details buried below the scene list; unusably narrow companion panes near the
  tablet threshold; ambiguous scene-action icons; lost focus selection when a
  tablet together layout narrowed to phone.
- Current solid text roles were measured using WCAG relative luminance: primary
  `#EDF2F7` and secondary `#ACB8C8` on panel `#1E2936` are 13.08:1 and 7.33:1.
  This is not a claim that every control/state passes a complete accessibility audit.

Screenshots: [phone OBS](prototype-shots/phone-obs.png),
[phone chat](prototype-shots/phone-chat.png),
[tablet together](prototype-shots/tablet-together.png),
[tablet OBS emphasis](prototype-shots/tablet-obs.png),
[tablet reconnecting](prototype-shots/tablet-reconnecting.png).

Browser tooling note: Flutter's web semantics overlay can make agent-browser
ref clicks report covered elements even though normal pointer input works. Inspect
semantics and element geometry, then use pointer input at the verified control
position. Allow route animation to settle before taking a new snapshot. Browser
checks do not establish native VoiceOver/TalkBack or keyboard behavior.

## Approved interaction and remaining scope

Scene rows inspect on tap, with a separate labelled Preview/Send action. The user
approved this recommendation on 2026-09-11 (D-005), deliberately changing master's
whole-row execution behavior. Preserve this distinction during integration.

The prototype has one synthetic channel/source fixture; manual endpoint entry,
QR/discovery, actual authentication, entitlement states, platform-specific native
chat capabilities, real activity feeds, persistence and native device testing
remain future work. OBS retries/outcomes are manually simulated. Global OBS busy
state is a fixture simplification; production needs command-scoped pending state
and explicit acknowledgement policy. No live studio-transition behavior is proven
by the simulated Take action. Keep these limits visible when defining the adapter.
