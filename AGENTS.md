# OBS Blade

Flutter remote for OBS Studio via **OBS WebSocket v5** (**iOS/Android — phone and
tablet / large-screen first-party**). Great UI on both form factors is a product
requirement, not an afterthought.
Repo: `Kounex/obs_blade` (**public**) · branches: `master`, `redesign`, `foss`, `legacy`.

> **Docs hygiene (public repo):** no credentials, personal absolute paths,
> device IDs, or LAN/WAN addresses in tracked files. Write docs and tooling so
> any contributor's agent can follow them; keep maintainer-specific setup
> notes clearly marked as such. **Non-public content** (business strategy,
> infra/security architecture) goes in `docs/private/` — gitignored, never
> committed. See `docs/session-handoff.md`'s hygiene section for how that
> stays in sync across machines despite not being in git.

## Start here — every session, no exceptions

Run this checklist before **any** other work — fresh session, resumed
session, and after a context compaction alike ("I'm just continuing the
TODO list" is exactly how this gets skipped; a continuation is still a
session start):

1. **`git fetch --all`** — diff your branch against its remote counterpart
   and skim recent log. This file and the handoff doc are only as current
   as whoever last updated them.
2. **Maintainer machine check:** if `docs/private/` exists in your
   checkout, read **[`docs/private/maintainer-workflow.md`](docs/private/maintainer-workflow.md)**
   (gitignored, maintainer machines only: machine topology, SDK locations,
   dogfood handoff rule, private-doc sync duties) and verify the private
   docs are in sync (checksum commands in that file).
   If `docs/private/` is absent, you're in an external contributor clone —
   skip this step entirely.
3. **Read [`docs/session-handoff.md`](docs/session-handoff.md)** — reset
   at every handoff, holds only current state + immediate next steps.
   Read it before trusting anything below to still be current.

## Agent constraints

- **500k+ live users** — treat persistence and release paths carefully.
- **Commit per verified unit** — after each finished, tested/analyzed piece
  of work, commit it as a small, logically-scoped commit without waiting to
  be asked. **Push when the user asks, and always at wrap-up/handoff** —
  the remote is the source of truth; never leave work local-only when
  handing over. Active branch:
  `master` (includes "On Air" redesign; pull/fetch before editing — see the
  handoff doc for exactly how current each machine's clone is).
- Keep this file short. Deeper notes live in [`docs/`](docs/).

## Definition of done — feature work

Feature work - new **or** a change / fix to an existing feature - that
talks to OBS (requests, events, plugin vendor calls), to a chat platform
(chat, sign-ins, activity feed, TTS) or changes the dashboard / chat UI
goes through the **`feature-work` skill** (`.claude/skills/feature-work/`;
agents without skills: read it as a runbook). It's at least process tier
M, whatever the handoff's default. Not done before:

1. the request clarified with the user where it leaves room (states,
   platforms, scope, taste) - ask, don't assume;
2. real-world use researched (who uses it, which plugins / platforms /
   account setups);
3. facts checked against the **source** (obs-websocket / OBS / plugin
   source, the platform's API reference + a real answer), noted in
   [`docs/obs-protocol-gotchas.md`](docs/obs-protocol-gotchas.md) or the
   chat audits, and the test fakes behaving like that source - awkward
   cases first;
4. the journeys walked through the area checklist:
   [`docs/dashboard-interaction-checklist.md`](docs/dashboard-interaction-checklist.md)
   (OBS / dashboard), [`docs/chat-journey-checklist.md`](docs/chat-journey-checklist.md)
   (chat, sign-ins, activity);
5. every new UI state rendered and looked at (`tool/widget_shots/`);
6. a fresh-context review done and its findings handled;
7. a device check list handed over - store test builds only after the
   user's on-device OK.

**After building a feature, remind the user to run `/code-review high` in
a fresh session** - an independent pass without this session's
assumptions. Put the reminder at the end of the final report.

## Quick map

| Area | Where |
|---|---|
| Entry / DI / Hive init | `lib/main.dart` |
| Tabs + routes | `lib/tab_base.dart`, `lib/utils/routing_helper.dart` |
| WebSocket session | `lib/stores/shared/network.dart`, `lib/utils/network_helper.dart` |
| Dashboard state | `lib/stores/views/dashboard.dart` |
| Protocol DTOs | `lib/types/classes/stream/` |
| Persisted models | `lib/models/` + `TypeIDs` |
| Chat (WebView + native Twitch/YouTube/Kick + Combined; dedicated tab, dashboard pane removed) | `lib/views/dashboard/widgets/obs_widgets/stream_chat/` |
| Media hub (soundboard) | `lib/views/dashboard/widgets/dashboard_content/scene_content/media_hub/` (behind `ExposeMediaHub`; spec `docs/superpowers/specs/2026-09-27-media-hub-design.md`) |
| Activity feed (own-channel events, seen / thanked, status banner, gaps) | `lib/stores/views/activity.dart`, `lib/utils/activity/` (own-YouTube poller, status builder), `lib/views/chat/widgets/activity/`; Kick webhook relay `tool/kick_events_relay/` |
| YouTube video id helper | `lib/utils/youtube_video_id.dart` |
| Shared design system ("On Air") | `lib/shared/design/` |
| Responsive phone↔tablet swap | `lib/shared/general/responsive_widget_wrapper.dart` (width > `StylingHelper.max_width_mobile` **700**, or Settings → **Force Tablet Mode**) |
| Content column max width | `BaseConstrainedBox` / `kBaseConstrainedMaxWidth` **720** (text/list screens) · `kWideContentMaxWidth` **1040** (charts / data grids, e.g. statistic detail) |

**Stack:** MobX + GetIt · **Hive CE** · freezed for nested OBS API objects.

**Layouts:** Use `ResponsiveWidgetWrapper` when mobile and tablet need different
composition (e.g. tabs vs side-by-side). Don’t phone-optimize the dashboard in a
way that regresses tablet. Details: [`docs/redesign/design-system.md`](docs/redesign/design-system.md)
§ Responsive layouts.

**OBS control:** official WebSocket **v5** only — typed subset under
`lib/types/` (see architecture doc). `DashboardStore` is a large intentional
monolith; don't split it unless asked.

**Canvases (OBS 32.1+ / obs-websocket 5.7):** `CanvasViewStore` switches a
dashboard view (view-only) to a non-main canvas (e.g. Aitum Vertical);
the Aitum Vertical plugin adds live scene/output control of its canvas,
Twitch Dual Format sends an extra canvas through the main stream.
Details: [`docs/canvases.md`](docs/canvases.md).

**Chat (Twitch native):** a full native engine (device-code login,
EventSub reads, Helix writes, multi-chat, room + message mod tooling,
badges / third-party emotes / emote picker, history backfill) ships next
to the WebView embeds — engine switch in the chat bar
(`SelectedChatEngine`). Chat is a **dedicated tab** (no OBS session
needed; the dashboard pane is removed) and the streaming-mode dashboard's
co-display. Details: [`docs/chat-engines.md`](docs/chat-engines.md).

**YouTube chat:** native engine next to the WebView embed — reads poll
`liveChatMessages.list` with a user-supplied API key, writes/mod ride
Google OAuth device flow; channel entries auto-resolve (and roll over to)
the channel's current live stream. Details:
[`docs/youtube-native-chat-audit.md`](docs/youtube-native-chat-audit.md).

**Kick chat:** native engine (read + write/mod) next to the WebView embed —
anonymous reads (public web API + Kick's Pusher socket), writes/mod via
the official API behind an optional manual-paste PKCE sign-in.
Details: [`docs/kick-chat-audit.md`](docs/kick-chat-audit.md).

**Combined chat (waves 1-3 shipped):** `ChatType.Combined` (native-only)
merges the signed-in channels — or saved combos of any channels — into
one Pro-gated timeline (stable k-way merge, per-platform rows / mod
sheets, writing to a picked target). Details:
[`docs/chat-engines.md`](docs/chat-engines.md).

**Add chat sheets (all 3 engines):** one searchable channel picker per
platform on shared chrome, opened from the native channel menus and the
combo builder's "Other…". Details:
[`docs/chat-engines.md`](docs/chat-engines.md).

**General native chat (all 3 engines):** shared mechanics ship uniformly —
own-channel detection, mention/keyword highlighting, mute words, chat
search, Chatterino-style extras (autocomplete, timestamps/zebra, readable
name colors, FFZ + zero-width emotes, highlighted/ignored users, censor
mode), "Copy message" for read-only viewers, and screen-reader row
semantics. Details: [`docs/chat-engines.md`](docs/chat-engines.md).

**Chat TTS:** `ChatTtsStore` (startup singleton, Pro) reads the visible
chat aloud over the app's own native TTS channel — a never-dropping queue
with spam collapsing, per-language voices, opt-in per-message language
detection, speaker toggle in the native chat header. Details:
[`docs/chat-tts.md`](docs/chat-tts.md).

**Monetization (Pro):** native chat engines are gated behind the **Pro
entitlement** (`ProStore.isPro`). Products `pro_yearly` / `pro_monthly`
(subs) + `pro_lifetime` (non-consumable) are created + priced store-side
and **approved on both stores**; the app runs the **RevenueCat** path
(`purchases_flutter`, entitlement `pro`) with the legacy direct-IAP
fallback. WebView chat stays free forever. Gate mechanics + wiring:
[`docs/revenuecat-setup.md`](docs/revenuecat-setup.md).

## Docs index

| Doc | Use when |
|---|---|
| [`docs/session-handoff.md`](docs/session-handoff.md) | **Fresh agent** — resume state |
| [`docs/obs-websocket-architecture.md`](docs/obs-websocket-architecture.md) | How OBS WebSocket is modeled/used |
| [`docs/obs-protocol-gotchas.md`](docs/obs-protocol-gotchas.md) | **Before any OBS-facing feature** — obs-websocket / OBS / plugin behavior the docs don't tell (canvas-scoped lookups, missing events, Aitum, Dual Format) |
| [`docs/dashboard-interaction-checklist.md`](docs/dashboard-interaction-checklist.md) | **Before reporting a feature done** — journeys × dashboard surfaces × state changes × form factors |
| [`docs/websocket-connect-audit.md`](docs/websocket-connect-audit.md) | Connect/handshake gaps + remediation |
| [`docs/dashboard-store-websocket-audit.md`](docs/dashboard-store-websocket-audit.md) | DashboardStore events/responses/batches |
| [`docs/chat-webview-audit.md`](docs/chat-webview-audit.md) | Twitch/YouTube/Owncast chat strategy |
| [`docs/chat-native-roadmap.md`](docs/chat-native-roadmap.md) | Native chat: unexploited Twitch API surface + build order |
| [`docs/youtube-native-chat-audit.md`](docs/youtube-native-chat-audit.md) | Native YouTube chat: API feasibility, quota reality, build plan |
| [`docs/chatterino-comparison.md`](docs/chatterino-comparison.md) | Chatterino feature comparison, adapt list + YouTube channel→live resolution |
| [`docs/revenuecat-setup.md`](docs/revenuecat-setup.md) | Pro subscription: RevenueCat dashboard/store wiring checklist |
| [`docs/upgrade-plan.md`](docs/upgrade-plan.md) | Flutter / package upgrade status |
| [`docs/persistence-risk.md`](docs/persistence-risk.md) | Hive CE, typeIds, shipping data safety |
| [`docs/hive-ce-source-audit.md`](docs/hive-ce-source-audit.md) | Classic Hive vs Hive CE on-disk audit |
| [`docs/release-playbook.md`](docs/release-playbook.md) | Store releases — versioning, release notes, TestFlight/Play internal → review → publish; entry points are the `release-beta` / `release-promote` / `release-direct` / `release-publish` skills in `.claude/skills/` |
| [`docs/changelog-agent.md`](docs/changelog-agent.md) | History of agent changes (not the handoff doc — that's current-state only) |
| [`docs/local-obs-e2e.md`](docs/local-obs-e2e.md) | Local OBS ↔ simulator E2E loop (macOS) |
| [`docs/superpowers/plan-defect-checklist.md`](docs/superpowers/plan-defect-checklist.md) | Running an SDD wave — pre-dispatch plan-verification pass, codegen checklist, named defect probes |
| [`docs/superpowers/visual-companion-gotchas.md`](docs/superpowers/visual-companion-gotchas.md) | Brainstorm companion server — framing ban, session keys, real-browser verification |
| [`docs/redesign/`](docs/redesign/) | "On Air" redesign (now on `master`): design system, audit digest, session notes |
| [`docs/redesign-astra-audit.md`](docs/redesign-astra-audit.md) | Astra first-principles redesign (branch `redesign-astra`): audit + ratified progressive-adoption verdict, verified master defects, harvest list |
| [`docs/private/monetization-strategy.md`](docs/private/monetization-strategy.md) | Business model — pricing tiers, power-user/Studio revenue plan. **Gitignored — not public.** |
| [`docs/private/backend-architecture.md`](docs/private/backend-architecture.md) | Infra plan for paid backend features — hosting, build order, open decisions. **Gitignored — not public.** |
| [`docs/private/feature-requests-2026-10.md`](docs/private/feature-requests-2026-10.md) | User requests 2026-10 (chat TTS, in-app web pages, TikTok chat, OBS canvases): feasibility, store-rating impact, decisions + plan. **Gitignored — not public.** |
| [`docs/private/maintainer-workflow.md`](docs/private/maintainer-workflow.md) | Maintainer-only machine setup + dogfood/private-doc sync workflow. **Gitignored — not public; contributors can ignore.** |

## Tooling

- **Flutter:** plain `flutter` from PATH (machine-local install; make
  sure `flutter` is on PATH on every machine — e.g. add `~/flutter/bin`
  where the SDK isn't PATH-installed). The current Flutter version per
  machine is tracked in `docs/upgrade-plan.md`.
- **Format:** the tree is `dart format`-clean on the SDK tall style since
  2026-09-10 (one-time 404-file migration) — format changed files freely;
  `tool/*` standalone packages are excluded from that pass.
- **No agent-side sim verification** (user directive 2026-09-10, confirmed
  2026-09-30): ship best-effort code + analyze/test gates; the user runs
  the simulator. For a task where a simulator check or screenshot would
  really help (e.g. a visual fix), ask the user first - never start one
  unasked.
- **Local OBS E2E (macOS):** `tool/obs_local/obs_test_env.sh start` →
  `dart run tool/obs_local/ws_smoke.dart --password <obs-ws-password>` →
  `flutter run -d <sim-id>` → `… stop`. Details: `docs/local-obs-e2e.md`.
- **YouTube chat quota spike:** `tool/youtube_spike/` (standalone Dart
  package, own pubspec; run `setup.sh` first — fetches Google's
  `stream_list.proto` + protoc). Measures REST-poll vs gRPC `streamList`
  read cost against a real chat with a throwaway API key. Protocol:
  `tool/youtube_spike/README.md`.
- **Provisioning automation:** `tool/provisioning/` (standalone package,
  creds-by-path, `--dry-run`, idempotent) — `gcp-youtube` (GCP project +
  YouTube API + restricted key), `asc-products` (subscription group +
  subs + IAP + per-territory pricing via ASC API), `play-products` (Play
  subscription + base plans + one-time product + per-region pricing).
  Both stores price from one reviewed table
  (`tool/provisioning/lib/src/pricing_targets.dart`, generated from
  Google's convertRegionPrices + hand-reviewed; refresh workflow in the
  README § Pricing table, `bin/audit_prices.dart` cross-checks the live
  stores). Usage + creds
  acquisition: `tool/provisioning/README.md`.
- **Store releases:** `tool/release/` (status, preflight, build, TestFlight
  / Play internal, submit, promote, publish; every store write is a dry run
  without `--yes`). Process: `docs/release-playbook.md`; agents start from
  the `release-*` skills in `.claude/skills/` (agents without skill support:
  read those `SKILL.md` files as runbooks).
- **Widget shots (headless, any machine):** `tool/widget_shots/run.sh` —
  renders widget states with the real theme + fonts to
  `build/widget_shots/*.png`, no simulator / OBS. Specs are
  `tool/widget_shots/*_shots_test.dart` (template: `canvas_shots_test.dart`,
  guide: `tool/widget_shots/README.md`). Part of the definition of done.
- **Visual-QA screenshots (macOS, booted sim):**
  `tool/visual_qa/capture_screenshots.sh` — runs
  `integration_test/screenshot_walk_test.dart`, writes PNGs to
  `/tmp/obs_shots/`. OBS ws password is read from the local OBS config at
  runtime, never from the repo. **Always keeps `--no-uninstall`** in the
  flutter test call — the default uninstalls the app afterwards and wipes
  the simulator's data container. Phone-width by default; for a large-screen
  smoke, enable Settings → **Force Tablet Mode** (or use a wide / iPad sim)
  and re-check dashboard Scene Items/Audio + Chat/Stats side-by-side.
- **Test selection (scale the run to the change):** don't run the full
  suite every time — run what the change can actually break, widening as
  you get closer to shipping:
  1. **While iterating:** only the test file(s) covering the code in
     flight — `flutter test test/chat/twitch_chat_store_test.dart`
     (seconds, not minutes).
  2. **Before committing a unit:** the suite directory matching the area
     touched — chat (`lib/utils/twitch/`, `lib/stores/views/twitch_*`,
     `lib/views/**/stream_chat/`) → `test/chat/`; websocket/protocol
     (`lib/stores/shared/network.dart`, `lib/types/`) → `test/websocket/`;
     persistence (`lib/models/`, `TypeIDs`, hive registrar) →
     `test/persistence/`; shared widgets/utils → their matching
     `test/shared/` / `test/utils/` files. Cross-cutting changes (design
     system, DI/`main.dart`, routing) → all affected suites.
  3. **Wrap-up, before push/handoff:** the full gate once —
     `flutter test test/chat/ test/websocket/ test/persistence/` +
     analyze. Store cut: full gate + integration tests.
  Two gotchas: don't run `flutter test` concurrently with analyze or
  other Flutter processes (they starve each other and can look hung), and
  never do real I/O (e.g. a Hive `save()`) inside `testWidgets`' fake-async
  zone — it never completes and hangs the suite at shutdown.
- **Test gate wrapper:** `dart tool/test_gate.dart [test targets...]`
  (default `test/`) wraps `flutter test -j 1 --reporter json`, transparently
  re-runs files that fail to *load* with the flutter_tester
  `WebSocketException` runner flake (up to 3 attempts per file) and exits
  non-zero only on real failures — use it for full-suite gates so the load
  flake doesn't force manual babysitting. `--runs=N` repeats the whole gate
  N times, failing fast. It prefers `~/flutter/bin/flutter` and falls back
  to `flutter` on PATH, so it works on any machine.
- **Process tiers (default S):** size the process to the change — S:
  implement directly in-session (no subagents/plan doc), TDD + gates
  once at the end; M: 1 implementer subagent + 1 end reviewer, prose
  mini-plan; L: full SDD per `docs/superpowers/plan-defect-checklist.md`
  §0 (verifier pass, per-task reviews, defect probes). Upgrade past S
  only when the user flags risk (persistence/protocol/release paths) or
  the work is genuinely multi-day. Subagents go on the secondary model;
  if its quota is exhausted, say so and drop a tier instead of running
  the full pipeline on primary. This tier policy is the project's
  explicit override of the superpowers-skill defaults (brainstorming,
  subagent-driven-development) for process sizing — skills still apply
  within the chosen tier. Append new ratified defect classes to
  the checklist at wave wrap-up.
- Branch: `master`

## Related

- `Kounex/obs_blade_page` — marketing site
- `Kounex/obs_station_server` — separate Twitch-era backend (historical)
