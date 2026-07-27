# Hive 2.2.3 → Hive CE 2.19.3 source audit

Compared packages from pub.dev archives (not device data):

- classic: `hive` **2.2.3** + `hive_flutter` **1.1.0** (what the app used)
- CE: `hive_ce` **2.19.3** + `hive_ce_flutter` **2.3.4** (current branch)

Scope: on-disk compatibility for **OBS Blade’s** boxes (typed models + untyped
settings). Not a claim about every possible Hive feature worldwide.

## Verdict

**Should be good for an upgrade-style open.** No source-level blocker found for
this app’s persistence shape. Device verification is still the gold standard,
but the wire format paths that matter here are preserved.

## Why (wire format)

| Concern | Finding |
|---|---|
| Primitive tags `FrameValueType` 0–12 | **Identical** (null/int/double/bool/string/lists/map/hiveList) |
| User `typeId` → wire byte | Both do `typeId + 32` for external adapters; our IDs **0–12 → wire 32–44** |
| Custom `TypeAdapter` contract | Same `typeId` / `read` / `write` API |
| Int encoding | Still float64 little-endian (same quirk both sides) |
| Frame layout | length(u32) + key + value + CRC32(u32); unencrypted CRC seed `0` |
| Encryption | App does **not** use `HiveCipher` / `encryptionCipher` |
| Box path | `initFlutter()` → app documents dir, no `subDir` — same as classic |
| Stored timestamps/colors | App stores **ints / hex strings**, not `DateTime`/`Color` objects |

CE **adds** `FrameValueType` 13–21 (sets, duration, typeId extension, …). Those
only appear in **new CE writes** of new types. Classic boxes from this app do
not contain them for our models.

## App-specific migration checks (this branch)

- Kept `@HiveType` / `@HiveField` (no `GenerateAdapters` remapping)
- Manual adapter registration in `main.dart` (same set); do not also call
  `Hive.registerAdapters()` (would double-register)
- Regenerated adapters: field index **sets** unchanged vs pre-migration fixtures
- `hive_ce_flutter.initFlutter` auto-registers Color(**200**) / TimeOfDay(**201**)
  — no collision with TypeIDs 0–12

## Non-blockers / residual risk

1. **Not a substitute for device open** of a real long-lived install (corruption,
   partial writes, OEM storage quirks).
2. **Downgrade CE → classic** would be unsafe if CE wrote Set/extended typeIds;
   upgrade path only matters here.
3. **List specialization** differs slightly (classic forced `listT` when
   `contains(null)`; CE prefers typed list tags first). Our chart lists are
   non-null `List<int>` / `List<double>` — fine.
4. `freezed` on a `-dev` resolve is unrelated to Hive on-disk format.

## Residual “prove it harder” option — **done**

`tool/classic_hive_writer/` depends only on classic `hive: 2.2.3`, writes the
same foundation dataset to `test/persistence/fixtures/classic_boxes/`.

`test/persistence/hive_classic_to_ce_test.dart` copies those files and opens
them with **Hive CE** (counts + Living Room PC / Midnight Blade / settings /
chat type / dashboard order). That closes the classic→CE binary gap without a
store build. Device open of a long-lived install remains the final check.
