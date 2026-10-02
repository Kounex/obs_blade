# Widget shots

Renders widget states to PNGs **headless** - no simulator, no device, no
OBS - with the app's real theme (`App.buildTheme`) and real fonts (Roboto,
Material + Cupertino icons, the app's icon fonts). Use it to *look at*
every new UI state before reporting a feature as done; it's how layout,
copy and color problems get caught without a dogfood round.

Light enough for the headless analyze/test machine. For the whole app on
a simulator against a real OBS, use `tool/visual_qa/` instead.

```bash
tool/widget_shots/run.sh                                    # every spec
tool/widget_shots/run.sh tool/widget_shots/canvas_shots_test.dart
```

PNGs land in `build/widget_shots/<name>.png` (gitignored). Open them -
agents read them as images.

## Writing a spec

Copy `canvas_shots_test.dart`. A spec is a normal widget test file named
`*_shots_test.dart` in this folder (outside `test/`, so the regular suite
and `tool/test_gate.dart` never run it):

1. `setUpAll(ShotsHarness.loadFonts)`, `harness.setUp()` / `tearDown()`
   for Hive, register the stores the widgets read (GetIt).
2. Fill the stores the way OBS would have answered (`runInAction`) -
   one helper per state keeps the shots readable.
3. `await harness.shot(tester, 'name', widget)` per state a user can
   reach; `size: kShotTablet` for the large-screen layout, a narrow
   `Size(320, 640)` for overflow checks.

Shoot the states the feature adds *and* the neighbors it changes (the
dashboard interaction checklist, `docs/dashboard-interaction-checklist.md`).

Notes:
- Text renders in Roboto (what flutter_test can load) - iOS uses SF, so
  widths differ slightly; leave headroom.
- Shots use `--update-goldens` to write files; they are images to look
  at, not regression goldens - nothing is compared or committed.
- A MobX "No observables detected" warning in the run output is a real
  finding (an Observer that watches nothing).
