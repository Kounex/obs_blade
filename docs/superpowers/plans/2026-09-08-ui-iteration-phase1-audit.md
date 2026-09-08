# 4.0 UI Iteration — Phase 1: Current-State Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a grounded, prioritized audit of the app's current UI/motion state — screenshot inventory on phone + tablet, motion/token discipline findings — as the input for Phase 2 mockups.

**Architecture:** Read-only on app code. Visual inventory via the existing
visual-QA harness (`tool/visual_qa/capture_screenshots.sh` +
`integration_test/screenshot_walk_test.dart`) against a local OBS test
instance; advisor skill passes for motion; grep sweeps for token
discipline. Outputs: untracked screenshot dirs + two tracked markdown docs.

**Tech Stack:** Flutter integration_test, `xcrun simctl`, bash, the
`find-animation-opportunities` / `improve-animations` advisor skills.

## Global Constraints

- **No edits under `lib/`** (spec hard rule — exploration only).
- Screenshots may contain the simulator's saved-connection LAN address —
  **never commit raw screenshots** (public repo hygiene, AGENTS.md). The
  screenshot dir is gitignored in Task 1 before any PNG lands there.
- The walkthrough test is READ-ONLY by contract (no settings toggles) —
  tablet composition therefore requires a real iPad-width simulator, not
  Force Tablet Mode.
- The capture script always runs with `--no-uninstall` (simulator data
  container wipe risk — do not remove).
- macOS workstation, Flutter from PATH, one Flutter process at a time
  (never run `flutter test` concurrently with `flutter analyze`).

---

### Task 1: Gitignore the audit artifact dir + start local OBS

**Files:**
- Modify: `.gitignore` (append)

**Interfaces:**
- Produces: `docs/redesign/2026-iteration/` as the untracked home for all
  audit screenshots (`before-phone/`, `before-tablet/` subdirs).

- [ ] **Step 1: Gitignore the screenshot dir**

Append to `.gitignore`:

```gitignore
# 4.0 UI audit — local screenshot artifacts (may contain LAN addresses)
docs/redesign/2026-iteration/
```

- [ ] **Step 2: Verify the ignore works**

```bash
mkdir -p docs/redesign/2026-iteration/before-phone docs/redesign/2026-iteration/before-tablet
touch docs/redesign/2026-iteration/probe.png
git status --porcelain docs/redesign/2026-iteration/
```

Expected: empty output (dir ignored). Then `rm docs/redesign/2026-iteration/probe.png`.

- [ ] **Step 3: Start the local OBS test environment**

```bash
tool/obs_local/obs_test_env.sh start
```

Expected: OBS launches with the websocket server enabled (see
`docs/local-obs-e2e.md`). Verify:

```bash
dart run tool/obs_local/ws_smoke.dart --password "$(python3 -c 'import json; print(json.load(open("'"$HOME"'/Library/Application Support/obs-studio/plugin_config/obs-websocket/config.json"))["server_password"])')"
```

Expected: smoke test connects and prints scene/stats data. If the
password read fails, stop and ask the maintainer — do not hardcode it.

- [ ] **Step 4: Commit**

```bash
git add .gitignore
git commit -m "chore: gitignore 4.0 UI audit screenshot dir (hygiene)"
```

---

### Task 2: Phone-width visual inventory

**Files:**
- Create (untracked): `docs/redesign/2026-iteration/before-phone/*.png`

**Interfaces:**
- Consumes: running local OBS (Task 1), booted iPhone 17 Pro sim
  (`D6F98034-F7A7-4574-967C-A9E182A7ED3A`, iOS 26.5 — already booted).
- Produces: the phone "before" set referenced by the digest (Task 6).

- [ ] **Step 1: Run the capture**

```bash
tool/visual_qa/capture_screenshots.sh
```

Expected tail: `[capture] done: N screenshots in /tmp/obs_shots (test
exit: 0)`. If the walk fails mid-run, read
`/tmp/obs_shots/flutter_test_output.log` — fix environment issues (OBS
not running, sim not booted), never the test's read-only contract.

- [ ] **Step 2: Spot-check the captures**

Open 3–5 PNGs (dashboard, scenes, settings) and confirm they show real
content (connected dashboard, not an error/empty state). `ReadMediaFile`
on `/tmp/obs_shots/` entries. If the dashboard shots show "disconnected",
OBS wasn't reachable — redo Step 1 after fixing Task 1 Step 3.

- [ ] **Step 3: Move into the audit dir**

```bash
find /tmp/obs_shots -maxdepth 1 -name '*.png' ! -name 'current.png' \
  -exec mv {} docs/redesign/2026-iteration/before-phone/ \;
ls docs/redesign/2026-iteration/before-phone/ | wc -l
```

Expected: count matches the script's reported `N`.

- [ ] **Step 4: Commit the (empty-of-images) state**

Nothing tracked changed in this task — no commit. (Screenshots stay
untracked by design.)

---

### Task 3: Tablet-width visual inventory

**Files:**
- Create (untracked): `docs/redesign/2026-iteration/before-tablet/*.png`

**Interfaces:**
- Consumes: running local OBS (Task 1).
- Produces: the tablet "before" set referenced by the digest (Task 6).

- [ ] **Step 1: Create + boot an iPad simulator (none exists on this machine)**

```bash
RUNTIME=$(xcrun simctl list runtimes | grep 'iOS 26' | awk '{print $NF}')
xcrun simctl list devicetypes | grep -i 'iPad Pro' | head -3
xcrun simctl create "iPad QA" com.apple.CoreSimulator.SimDeviceType.iPad-Pro-11-inch-M4 "$RUNTIME"
xcrun simctl boot "iPad QA"
xcrun simctl list devices booted
```

If the M4 device type id differs, pick any `iPad-Pro` devicetype id from
the list output. Expected: "iPad QA" appears as Booted alongside the
iPhone. Note its UUID for the next step.

- [ ] **Step 2: First launch on the iPad sim (fresh container → app data seeds itself)**

```bash
DEVICE_ID="iPad QA" OUT_DIR=/tmp/obs_shots_ipad tool/visual_qa/capture_screenshots.sh
```

Expected: same `[capture] done: N screenshots` tail, exit 0. The fresh
sim has no saved connection — the walkthrough's connect flow uses the
local OBS via the dart-define password, same as phone.

- [ ] **Step 3: Spot-check tablet composition**

`ReadMediaFile` the dashboard shot: Scene Items + Audio and Chat + Stats
must compose **side-by-side** (not phone tabs) per
`docs/redesign/design-system.md` § Responsive layouts. If they don't,
capture the evidence — that's itself an audit finding.

- [ ] **Step 4: Move into the audit dir + shut the iPad down**

```bash
find /tmp/obs_shots_ipad -maxdepth 1 -name '*.png' ! -name 'current.png' \
  -exec mv {} docs/redesign/2026-iteration/before-tablet/ \;
xcrun simctl shutdown "iPad QA"
```

---

### Task 4: Motion advisor audits (read-only skills)

**Files:**
- Create: `docs/redesign/2026-iteration/animation-opportunities.md`
- Create: `docs/redesign/2026-iteration/motion-audit.md`

**Interfaces:**
- Produces: raw findings consumed by the digest (Task 6).

- [ ] **Step 1: Run the `find-animation-opportunities` skill**

Scope: `lib/views/` + `lib/shared/`. It is read-only and proposes motion
with exact values. Save its full output to
`docs/redesign/2026-iteration/animation-opportunities.md` with a
one-line header (`# Animation opportunities — 2026-09 audit input`).

- [ ] **Step 2: Run the `improve-animations` skill**

Scope: existing animation/motion code (`lib/shared/design/`,
`AnimatedTheme`, `AnimatedSwitcher`, `AnimationController` usages). It
produces a prioritized audit. Save to
`docs/redesign/2026-iteration/motion-audit.md` with the same header
idiom.

- [ ] **Step 3: Commit**

The `.gitignore` entry from Task 1 ignores the whole dir, so force-add
the two tracked findings docs:

```bash
git add -f docs/redesign/2026-iteration/animation-opportunities.md docs/redesign/2026-iteration/motion-audit.md
git commit -m "docs: 4.0 audit — advisor passes (opportunities + motion audit)"
```

(If the force-add proves annoying for the tracked docs, narrow the rule
in `.gitignore` to `docs/redesign/2026-iteration/before-*/` instead —
either is fine; keep exactly one mechanism.)

---

### Task 5: Token-discipline sweep

**Files:**
- Create: `docs/redesign/2026-iteration/token-discipline.md`

**Interfaces:**
- Produces: counts + hotspots consumed by the digest (Task 6).

- [ ] **Step 1: Hardcoded colors outside the design system**

```bash
rg -n 'Color\(0x|Colors\.' lib/views lib/shared --glob '!lib/shared/design/**' \
  | grep -v 'Colors.transparent' | wc -l
rg -n 'Color\(0x|Colors\.' lib/views lib/shared --glob '!lib/shared/design/**' \
  | grep -v 'Colors.transparent' | awk -F: '{print $1}' | sort | uniq -c | sort -rn | head -15
```

- [ ] **Step 2: Ad-hoc animation durations/curves outside `AppMotion`**

```bash
rg -n 'Duration\(milliseconds' lib --glob '!lib/shared/design/app_motion.dart' | wc -l
rg -n 'Curves\.' lib --glob '!lib/shared/design/app_motion.dart' | wc -l
```

- [ ] **Step 3: Ad-hoc radii outside `AppRadius`**

```bash
rg -n 'BorderRadius' lib --glob '!lib/shared/design/**' | wc -l
```

- [ ] **Step 4: Write `token-discipline.md`**

Format:

```markdown
# Token discipline sweep — 2026-09 audit input

## Hardcoded colors (outside lib/shared/design)
- Total: <N> (excl. Colors.transparent)
- Hotspots: <top files with counts>

## Ad-hoc durations
- Total: <N> Duration(milliseconds…) outside app_motion.dart

## Ad-hoc curves
- Total: <N> Curves.* outside app_motion.dart

## Ad-hoc radii
- Total: <N> BorderRadius.* outside lib/shared/design
```

- [ ] **Step 5: Commit**

```bash
git add -f docs/redesign/2026-iteration/token-discipline.md
git commit -m "docs: 4.0 audit — token discipline sweep"
```

---

### Task 6: Findings digest

**Files:**
- Create: `docs/redesign/2026-iteration-audit.md` (tracked, text-only)

**Interfaces:**
- Consumes: Tasks 2–5 outputs (screenshots in
  `docs/redesign/2026-iteration/`, the three findings docs).
- Produces: the Phase 1 deliverable the spec promises; input to Phase 2
  mockup planning.

- [ ] **Step 1: Write the digest**

Structure (scale each group to the actual findings — no filler):

```markdown
# 4.0 iteration — current-state audit (2026-09-08)

Screenshots: `2026-iteration/before-phone/`, `2026-iteration/before-tablet/`
(untracked, local). Raw inputs: `2026-iteration/*.md`.

## Quick wins
## Systemic issues
## Where the 2026 feel is missing
## Tablet-specific findings
```

Rules: reference screenshot files by relative path (e.g.
`![dashboard](2026-iteration/before-phone/05_dashboard.png)` — adjust to
actual filenames); every "missing feel" item names the screen + the
concrete gap; no LAN addresses or personal paths in the text.

- [ ] **Step 2: Self-check hygiene**

```bash
grep -nE '([0-9]{1,3}\.){3}[0-9]{1,3}|/Users/' docs/redesign/2026-iteration-audit.md
```

Expected: no matches.

- [ ] **Step 3: Commit**

```bash
git add docs/redesign/2026-iteration-audit.md
git commit -m "docs: 4.0 UI iteration — current-state audit digest"
```

- [ ] **Step 4: Stop the local OBS test environment**

```bash
tool/obs_local/obs_test_env.sh stop
```

- [ ] **Step 5: Wrap-up push**

```bash
git push
```
