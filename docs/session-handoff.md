# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-08-08** (full reset at
session close-out: all waves pushed, only the deleted-content dogfood open).

## Handoff hygiene (read before editing this file)

- **This is a baton, not a history log.** It holds only what the *next*
  session needs to pick up work right now — current branch, immediate open
  threads, pointers to the docs with real depth. If you're about to narrate
  *what happened and why*, that belongs in `changelog-agent.md` (history) or
  a dedicated `docs/*.md` (architecture/design/strategy) — leave only a
  pointer here, not the content itself.
- **Clear and rewrite this file at every handoff**, don't accumulate on top
  of the previous version. A stale "still open" note here caused real
  confusion once already: this file kept saying a release blocker was open
  well after it had actually been resolved on the other machine, because
  nobody reset it — they just left the old narrative in place and it quietly
  went stale.
- **`git fetch --all` before trusting anything here or in `AGENTS.md`** —
  diff your branch against its remote counterpart and skim recent log. This
  file is only as current as whoever last updated it remembered to make it.
- **Non-public docs live in `docs/private/`** (gitignored — this repo is
  public). Git will never sync it. If you create or edit anything there,
  copy it to the other machine immediately:
  `scp docs/private/*.md macbook:~/development/flutter/obs_blade/docs/private/`
  (or NAS-ward: `scp docs/private/*.md nas:~/agent/obs-blade/docs/private/`).
  Same goes for any other file that's deliberately outside git — don't let
  state exist on only one machine.

## Workspace facts

| | |
|---|---|
| Remote | `Kounex/obs_blade` (**public**) |
| Branch | **`master`** (includes "On Air" redesign; `redesign` branch retained as history) |
| Users | 500k+ live — persistence + release paths are sensitive |
| Form factors | First-party **phone and tablet** — see `AGENTS.md` + `redesign/design-system.md` § Responsive layouts |

### Machines

| Host | Path | Role |
|---|---|---|
| **Headless** (NAS) | `~/agent/obs-blade` | `pub get` / `analyze` / unit tests only. **Never `flutter run`.** |
| **Workstation** (MacBook) | `~/development/flutter/obs_blade` | Same branch — simulator/device runs, integration tests, visual-QA screenshots. The heavy lifter for anything needing a running app. |

Commit per verified unit proactively (small, logically-scoped commits).
Push when the user asks, and always at wrap-up/handoff — the remote is the
source of truth; never leave work local-only when handing over.

## Right now

**Everything is on `master` and pushed** (latest: `350e89d`). Gates at last
wrap-up: full suite 250/250, analyze 0 errors + exactly 6 pre-existing
warnings. Depth for every wave below: [`changelog-agent.md`](changelog-agent.md)
+ specs/plans under `docs/superpowers/`; per-task detail incl. commit ranges
in the SDD ledger `.superpowers/sdd/progress.md` (untracked, per-machine).

- **"On Air" redesign** — closed, merged. Design system: `lib/shared/design/`.
- **Native Twitch chat program** — all waves shipped:
  - Phase 1 + engine switch (08-04): OAuth device-code login ("OBS Blade
    Chat" app), read-only EventSub, manual WebView↔Native switch
    (`SelectedChatEngine`, default WebView; seam `nativeChatAvailableFor`).
  - Container UI (08-05): `NativeChatWindow` everywhere (tab slot, cards,
    streaming mode) + connection sheet; generic params = YouTube reuse seam.
  - Role badges + per-category toggles (08-05): `TwitchBadgeStore`, native
    chat options sheet (per-platform seam).
  - Send input (08-05): reads AND writes — `NativeChatInput` dock, silent
    `user:write:chat` scope upgrade (pre-upgrade sessions: read-only lock
    strip), Helix send, no optimistic insert. Dogfood passed 08-06.
  - Third-party emotes 7TV/BTTV (08-06): `ThirdPartyEmoteStore`, inline
    animated render, default-on toggle. Formal checklist never run as such —
    de-facto covered during picker/lifecycle dogfood (inline emotes visible
    in every session since).
  - Emote picker (08-06): dock button → bottom sheet (search, Channel/
    Global + third-party sections), insert at cursor; `user:read:emotes`
    silent upgrade + CTA. **Dogfood PASSED 08-07.**
  - Message lifecycle (08-06): delete/timeout-purge tombstoning, `/clear`
    banner, scrolled-up "Paused ↓" chip. **Dogfood PASSED 08-07.**
  - Deleted content + actor reveal (08-07): deleted rows keep content
    dimmed (alpha 0.5) + italic ` —Deleted` marker; tap a mod-deleted row →
    `<mod> deleted <chatter>'s message`. **DOGFOOD OPEN — the only open
    checklist:**
    - Delete a message from twitch.tv mod tools → content stays, dimmed,
      marker ` —Deleted`; username/badges untouched.
    - Tap it → `<mod> deleted <chatter>'s message`; tap again collapses;
      expansion survives new incoming messages.
    - Time out a user / `/clear` → content + marker but NO tap reveal
      (payloads carry no actor).
    - Deleted message with emotes → emotes render dimmed.

**Open threads (unblocked, pick up anytime):**

- Chat-only reconnect simulation (send-input wave): kill WAN only (pull
  router uplink / DNS-block `eventsub.wss.twitch.tv`) with LAN to OBS up →
  chat enters `reconnecting` via keepalive watchdog (~30s), recovers on its
  own. Never successfully triggered.
- Logout path itself untested (08-04) — incl. post-logout WebView fallback
  (`_syncWebController` early-return, `stream_chat.dart:108-112`; fix only
  if the fallback renders blank).
- Earlier review notes (not yet acted on): revocation toast on forced
  logout; message dedup by `messageId` (duplicate `/clear` → double banner
  is the known symptom class); revoked-refresh-token (Twitch 400) kept
  mid-session, wiped on next cold-start validate.
- Watch-only: "Paused ↓" chip may briefly re-appear mid-resume-animation
  (known transient; fix only if it reads badly).

**Next work:**

- **Native chat availability/entitlement gate** — the named next chat item:
  plugs into `nativeChatAvailableFor` (`lib/models/enums/chat_engine.dart`),
  brings auto-switch-on-login. Should be the first wave through the new
  verifier pass (below).
- Replies/announce — send polish, after the gate.
- Store cut — Android build/test + version/build-number bump first (see
  master notes in changelog).
- Paid backend — OAuth broker registration still deferred; see
  `private/backend-architecture.md`.

**Process (SDD waves):** after plan approval, run the pre-dispatch
plan-verification pass before Task 1 — checklist + named defect probes +
codegen artifact rules in
[`docs/superpowers/plan-defect-checklist.md`](superpowers/plan-defect-checklist.md);
paste per its §4 wiring; append new ratified defect classes at wrap-up.

## Verify quickly

```bash
# Headless (NAS)
cd ~/agent/obs-blade && git checkout master && git pull
~/flutter/bin/flutter test test/chat/ test/websocket/ test/persistence/

# Workstation (MacBook, login shell so PATH picks up Flutter)
cd ~/development/flutter/obs_blade
flutter test test/chat/ test/websocket/ test/persistence/
# Simulator: flutter devices && flutter run -d <sim-id>
# Visual-QA: tool/visual_qa/capture_screenshots.sh (keeps --no-uninstall)
# Tablet smoke: Settings → Force Tablet Mode, confirm adjacent pairs side-by-side
```

## Doc map

| Doc | Topic |
|---|---|
| [`AGENTS.md`](../AGENTS.md) | Short project rules + index |
| [`changelog-agent.md`](changelog-agent.md) | History of agent changes (not this file) |
| [`chat-webview-audit.md`](chat-webview-audit.md) | Chat strategy + Phase 0/1+ |
| [`obs-websocket-architecture.md`](obs-websocket-architecture.md) | OBS WS v5 model |
| [`websocket-connect-audit.md`](websocket-connect-audit.md) | Connect gaps (mostly fixed) |
| [`dashboard-store-websocket-audit.md`](dashboard-store-websocket-audit.md) | DashboardStore event handling |
| [`persistence-risk.md`](persistence-risk.md) / [`hive-ce-source-audit.md`](hive-ce-source-audit.md) | Hive CE safety |
| [`upgrade-plan.md`](upgrade-plan.md) | Flutter/package bump status |
| [`local-obs-e2e.md`](local-obs-e2e.md) | Local OBS ↔ simulator E2E loop (macOS) |
| [`superpowers/plan-defect-checklist.md`](superpowers/plan-defect-checklist.md) | SDD wave hardening — verifier pass, defect probes, codegen checklist |
| [`redesign/`](redesign/) | "On Air" redesign: design system, audit digest, session notes |
| [`private/monetization-strategy.md`](private/monetization-strategy.md) | Business model — pricing tiers, power-user/Studio revenue plan. **Gitignored.** |
| [`private/backend-architecture.md`](private/backend-architecture.md) | Infra plan for paid backend features. **Gitignored.** |
