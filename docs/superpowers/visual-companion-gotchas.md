# Visual companion gotchas (learned 2026-09-08)

Hard-won lessons from the 4.0 UI mockup phase — read before building
mockup tooling on the brainstorm companion server.

## The big one: verify served content in a REAL browser

A subagent "verified" a multi-iframe mockup shell twice with headless
Chrome — and it passed both times while failing in the user's real
browser. Cause: the harness loaded local `file://` copies, which never
touch the server and therefore never see its HTTP headers. **Headless
verification of server-served pages must go through the server URL** —
and when the question is "does it work in the user's browser", verify in
the user's actual browser (kimi-webbridge: borrow/navigate the real tab,
probe the DOM, click through the states).

## The server forbids framing

The companion server sends `X-Frame-Options: DENY` + `CSP:
frame-ancestors 'none'` on `/files/*` responses. Mockups can **never**
be composed via iframes. To combine multiple mockups behind one switcher,
merge them into a **single HTML document** (scope per-view CSS under
wrapper classes, namespace JS ids). Check embedding-relevant response
headers (`curl -sSI`) before choosing an architecture — one header check
beats two failed iterations.

Also: `HEAD` requests to `/files/*` return 404 while `GET` works — probe
with GET.

## Session key mechanics

- Always hand out the full `?key=…` URL; the server rejects keyless
  requests until the cookie is set, and cookies are NOT reliably sent for
  iframe subresources (cookie partitioning) — another reason iframes fail
  even aside from the framing ban.
- Hardcoding the key into mockup files works but goes stale if the
  session rotates.

## Server lifecycle

- Start script: `~/.kimi-code/plugins/managed/superpowers/skills/brainstorming/scripts/start-server.sh --project-dir <repo-root> --foreground` — run it under a background task (detached/nohup
  children get reaped), then smoke-check with `curl` (expect 200) before
  sharing the URL.
- Port + session key are discoverable at
  `.superpowers/brainstorm/<session-id>/state/server-info` (and the server
  prints them on startup).
- For a quick static look, the mock HTML also opens fine via `file://` —
  but anything server-served (e.g. images under `/files/`) will break,
  and "does it work for the user" must always be verified through the
  server URL in the real browser.
- Session dirs persist under `.superpowers/brainstorm/`; restart with the
  same `--project-dir` reuses the port and the user's tab reconnects.
- The server serves the NEWEST file in the content dir — never reuse
  filenames; iterate with `-v2`, `-v3` suffixes.
- A restart reuses port + session key but NOT the content dir (a new
  timestamped dir is created) — copy the mock files over manually, and
  update any bookmarks pointing at `/files/<name>` (filenames survive,
  the key in the query string survives too).

## Screenshotting mocks in a background browser tab

When driving the user's real browser via kimi-webbridge to capture a
mock: if the tab is not frontmost, **CSS animations are throttled** —
entrance animations (opacity/stagger) crawl or stall, and screenshots
catch half-faded content that looks like a design bug but isn't.
Reliable capture recipe: inject a settle-override style before
screenshotting —

```css
.stagger, .s-el {animation:none !important; opacity:1 !important; transform:none !important}
```

— then screenshot. Cover **every** animated class the mock uses: the 4.0
shell animates view entrances via `.stagger`, but the Scenes view's
composed elements via `.s-el` (with `backwards` fill, so throttled items
sit at opacity 0 — a `.stagger`-only override still yields invisible
content there). Also note element `display:none` subtrees never run
CSS animations at all: a view shown later must have its entrance
replayed explicitly (remove/re-add the animating class after a forced
reflow) or its items stay at their pre-animation state (e.g. opacity 0).
