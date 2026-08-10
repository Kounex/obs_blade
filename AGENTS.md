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

## Start here (next session)

→ **[`docs/session-handoff.md`](docs/session-handoff.md)** — reset at every
handoff, holds only current state + immediate next steps. Read it before
trusting anything below to still be current.

→ **If `docs/private/` exists in your checkout, you're on a maintainer
machine: also read `docs/private/maintainer-workflow.md` before doing
anything** (machine topology, dogfood handoff rule, private-doc sync
duties — they apply to you). If `docs/private/` is absent, you're in an
external contributor clone and can ignore everything about it.

## Agent constraints

- **500k+ live users** — treat persistence and release paths carefully.
- **`git fetch --all` before trusting this file or the handoff doc** — both
  are only as current as whoever last updated them remembered to make them.
  Diff your branch against its remote counterpart and skim recent log first.
- **Commit per verified unit** — after each finished, tested/analyzed piece
  of work, commit it as a small, logically-scoped commit without waiting to
  be asked. **Push when the user asks, and always at wrap-up/handoff** —
  the remote is the source of truth; never leave work local-only when
  handing over. Active branch:
  `master` (includes "On Air" redesign; pull/fetch before editing — see the
  handoff doc for exactly how current each machine's clone is).
- Keep this file short. Deeper notes live in [`docs/`](docs/).

### Maintainer's agent setup

Maintainer-specific setup (machine topology, SDK locations, dogfood and
private-doc sync workflow) lives in `docs/private/maintainer-workflow.md`
— gitignored, kept only on the maintainer's machines. External
contributors can ignore it entirely: everything needed to build and
contribute is in this file and the tracked `docs/`.

## Quick map

| Area | Where |
|---|---|
| Entry / DI / Hive init | `lib/main.dart` |
| Tabs + routes | `lib/tab_base.dart`, `lib/utils/routing_helper.dart` |
| WebSocket session | `lib/stores/shared/network.dart`, `lib/utils/network_helper.dart` |
| Dashboard state | `lib/stores/views/dashboard.dart` |
| Protocol DTOs | `lib/types/classes/stream/` |
| Persisted models | `lib/models/` + `TypeIDs` |
| Stream chat (WebView + native Twitch) | `lib/views/dashboard/widgets/obs_widgets/stream_chat/` |
| YouTube video id helper | `lib/utils/youtube_video_id.dart` |
| Shared design system ("On Air") | `lib/shared/design/` |
| Responsive phone↔tablet swap | `lib/shared/general/responsive_widget_wrapper.dart` (width > `StylingHelper.max_width_mobile` **700**, or Settings → **Force Tablet Mode**) |
| Content column max width | `BaseConstrainedBox` / `kBaseConstrainedMaxWidth` **640** |

**Stack:** MobX + GetIt · **Hive CE** · freezed for nested OBS API objects.

**Layouts:** Use `ResponsiveWidgetWrapper` when mobile and tablet need different
composition (e.g. tabs vs side-by-side). Don’t phone-optimize the dashboard in a
way that regresses tablet. Details: [`docs/redesign/design-system.md`](docs/redesign/design-system.md)
§ Responsive layouts.

**OBS control:** official WebSocket **v5** only — typed subset under
`lib/types/` (see architecture doc). `DashboardStore` is a large intentional
monolith; don't split it unless asked.

**Chat:** Twitch has a native engine (device-code login + EventSub chat +
Helix send input — reads AND writes) next to the WebView embeds; a manual
WebView↔Native switch lives in the chat bar (`SelectedChatEngine`, default
WebView; availability seam: `nativeChatAvailableFor` in
`lib/models/enums/chat_engine.dart`). The native side renders in
`NativeChatWindow` (optional `input` slot docks the generic, Twitch-free
`NativeChatInput`; silent `user:write:chat` scope upgrade — pre-upgrade
sessions get a read-only lock strip). **Multi-chat** lets users add other
channels (search / moderated / followed), switch via the chat-bar dropdown
(connect-on-switch, per-channel history), and run delete/timeout/ban in
modded channels (local reconcile + EventSub echo dedup). Room-level mod
actions (`ChannelModSheet` — clear, chat modes, shield, announce) ship via
the chat-bar shield button and native options sheet when moderating. Role badges +
per-category toggles ship via `TwitchBadgeStore` + the native chat options
sheet (per-platform seam); third-party (7TV/BTTV) emotes render inline via
`ThirdPartyEmoteStore` (toggle in the native chat options sheet); an emote
picker (first-party Get User Emotes via `TwitchEmoteStore` + the
third-party catalogs) docks in the native input (`user:read:emotes` silent
upgrade); message lifecycle rides the same session
(`message_delete`/`clear_user_messages`/`clear` → content-visible
tombstones (dimmed content + ` —Deleted` marker) + `/clear` banner,
best-effort subs; a `channel.moderate` v2 sub (gated on the
`kTwitchModerationScopes` 8-scope bundle, pre-upgrade tokens skip it)
supplies the deleting mod for the tap reveal) and scrolled-up chat shows a
pause chip. Next after dogfood: replies, availability/entitlement gate —
see chat audit + handoff.

## Docs index

| Doc | Use when |
|---|---|
| [`docs/session-handoff.md`](docs/session-handoff.md) | **Fresh agent** — resume state |
| [`docs/obs-websocket-architecture.md`](docs/obs-websocket-architecture.md) | How OBS WebSocket is modeled/used |
| [`docs/websocket-connect-audit.md`](docs/websocket-connect-audit.md) | Connect/handshake gaps + remediation |
| [`docs/dashboard-store-websocket-audit.md`](docs/dashboard-store-websocket-audit.md) | DashboardStore events/responses/batches |
| [`docs/chat-webview-audit.md`](docs/chat-webview-audit.md) | Twitch/YouTube/Owncast chat strategy |
| [`docs/upgrade-plan.md`](docs/upgrade-plan.md) | Flutter / package upgrade status |
| [`docs/persistence-risk.md`](docs/persistence-risk.md) | Hive CE, typeIds, shipping data safety |
| [`docs/hive-ce-source-audit.md`](docs/hive-ce-source-audit.md) | Classic Hive vs Hive CE on-disk audit |
| [`docs/changelog-agent.md`](docs/changelog-agent.md) | History of agent changes (not the handoff doc — that's current-state only) |
| [`docs/local-obs-e2e.md`](docs/local-obs-e2e.md) | Local OBS ↔ simulator E2E loop (macOS) |
| [`docs/superpowers/plan-defect-checklist.md`](docs/superpowers/plan-defect-checklist.md) | Running an SDD wave — pre-dispatch plan-verification pass, codegen checklist, named defect probes |
| [`docs/redesign/`](docs/redesign/) | "On Air" redesign (now on `master`): design system, audit digest, session notes |
| [`docs/private/monetization-strategy.md`](docs/private/monetization-strategy.md) | Business model — pricing tiers, power-user/Studio revenue plan. **Gitignored — not public.** |
| [`docs/private/backend-architecture.md`](docs/private/backend-architecture.md) | Infra plan for paid backend features — hosting, build order, open decisions. **Gitignored — not public.** |
| [`docs/private/maintainer-workflow.md`](docs/private/maintainer-workflow.md) | Maintainer-only machine setup + dogfood/private-doc sync workflow. **Gitignored — not public; contributors can ignore.** |

## Tooling

- **Flutter:** `./flutterw` wraps whatever SDK you have (`FLUTTER_ROOT` →
  `~/flutter` → `vendor/flutter`). Current pinned version: see
  `docs/upgrade-plan.md`.
- **Local OBS E2E (macOS):** `tool/obs_local/obs_test_env.sh start` →
  `dart run tool/obs_local/ws_smoke.dart --password <obs-ws-password>` →
  `flutter run -d <sim-id>` → `… stop`. Details: `docs/local-obs-e2e.md`.
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
     flight — `bash flutterw test test/chat/twitch_chat_store_test.dart`
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
     `bash flutterw test test/chat/ test/websocket/ test/persistence/` +
     analyze. Store cut: full gate + integration tests.
  Two gotchas: don't run `flutter test` concurrently with analyze or
  other Flutter processes (they starve each other and can look hung), and
  never do real I/O (e.g. a Hive `save()`) inside `testWidgets`' fake-async
  zone — it never completes and hangs the suite at shutdown.
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
