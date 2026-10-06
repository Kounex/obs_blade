# Dashboard interaction checklist

Walk this before reporting OBS-facing work (new or a change, `feature-work`
skill) as done. Every row is a place where a change has broken something
before, or would have - the point is to check interactions, not just the feature on its own. Add a row
whenever a review finds a new kind of interaction.

For each row: what does the user see, what does a tap do, and is that
still right with the new feature? Answer from the code (and a widget
shot, `tool/widget_shots/`), not from memory.

## Journeys (who goes through this)

Write the 3-6 real user setups for the feature first (research how people
actually use it - plugins, platforms, guides), then walk each through the
surfaces below. Example from the canvas work:

- no extra canvas / OBS too old - nothing may change
- Aitum Vertical + separate TikTok stream
- Twitch Dual Format (vertical canvas sent with the main stream)
- landscape or 4:5 "vertical" canvas
- the plugin missing or broken (fresh-install bug)

## Surfaces that depend on "the current scene / canvas / output"

| Surface | Check |
|---|---|
| Scene buttons | tap meaning (live switch / preview / view only), tally colors, studio mode PGM/PVW |
| Edit Scene Visibility | taps hide instead of acting; hidden state keyed correctly (scene names repeat across canvases) |
| Scene items + groups | toggles reach the right scene (group children live in the group's scene); hidden items; events patch the right row - a group child's events name the group, and its id can repeat a top-level id (visibility **and** lock confirm through the event) |
| Audio mixer | inputs are global - must not follow a canvas / scene by accident |
| Scene preview + fullscreen | follows what the scene buttons show; aspect ratio; scene changes play the OBS transition only with a transition context (no animation on reconnect / collection switch / canvas switch / studio preview pick) |
| Studio mode | transition / preview controls act on the main canvas only |
| App bar actions | screenshot source, stream / record / replay / virtual cam entries |
| Status pills (LIVE / REC / extra canvas) | only what's really on air; neutral while reconnecting |
| Exposed controls | main output only - nothing new may read as theirs |
| Streaming mode | fixed layout, main canvas; app bar still shows status |
| Media hub | "in program" markers |
| Dashboard customisation | toggles hide the feature cleanly; no way to get stuck |

## State changes the feature must survive

| Change | Check |
|---|---|
| Reconnect | listeners re-attached to the new socket, state re-read (see `docs/obs-protocol-gotchas.md` § General) |
| Profile switch | per-profile settings re-read (video, stream service, record dir) |
| Scene collection switch | scenes / canvases / items re-read |
| Something changed in OBS with no event | periodic re-read where it matters (canvas size, profile settings) |
| Plugin installed / removed / not answering | feature degrades with an explanation, never dead buttons |
| Leaving / re-entering the dashboard | store lifetime, timers stopped |

## Form factors + presentation

| Check | |
|---|---|
| Phone 390 pt and narrow 320 pt | no overflow (shot it) |
| Tablet / Force Tablet Mode | layout still makes sense side by side |
| Copy | names the thing the user knows (canvas name, platform), no internal jargon; never contradicts itself (status vs button) |
| Color grammar | live green = on air only, red = recording / program, amber = paused |
| Accessibility | one semantics node per control with a state + hint |
