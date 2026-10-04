# Mod overflow into Options — design

**Date:** 2026-08-09 · **Status:** approved (design) · **Process tier:** S

## Intent

When the channel Mod shield does not fit next to Options + account on the
native chat bar, Moderation is reached via Options. That path must read as
**settings and moderation together**, not as a generic list row buried among
appearance toggles.

## Ratified decisions

| Question | Decision |
|---|---|
| Overall direction | **A** — combined bar chip + featured Mod card in Options |
| Featured Mod card when shield fits on bar | **No** — only when Mod is folded into Options |
| Bar when shield fits | Unchanged separate shield + options gear |
| Opening Mod from the featured card | Existing `showChannelModSheet` (no content change) |

## Behavior

### Fit gate (unchanged meaning)

Reuse `nativeModClusterFitsWithShield` + `TwitchChatStore.canModerateSelectedChannel`:

- `showShield = canMod && clusterFits`
- `modFoldedIntoOptions = canMod && !showShield`

### Bar — Options control

When `modFoldedIntoOptions`:

- Replace the square gear-only tile with a **wider combined chip**: gear,
  light divider, shield icon (same visual language as today’s tiles).
- Same tap target → opens Options sheet.
- Tooltip: e.g. “Chat options & moderation”.

When not folded: keep today’s `NativeChatOptionsButton` (gear only).

### Options sheet root

When `modFoldedIntoOptions`:

1. **Featured Mod card** at the top — shield icon tile, title “Channel
   moderation”, short subtitle (clear / modes / Shield / announce), chevron.
   Distinct surface (tinted card / border), not a `ListTile` nav row.
   Tap → `showChannelModSheet`.
2. Light separator, then existing settings nav (Appearance, Emotes, Badges,
   Event messages).

When not folded: no Moderation entry in the sheet at all (shield on the bar
is the only channel-Mod entry).

## Wiring

Pass `modFoldedIntoOptions` from `_NativeRightCluster` (or equivalent) into
`NativeChatOptionsButton` / `NativeChatOptionsSheet` so bar chrome and sheet
content stay in sync on the same fit + auth observables.

## Out of scope

- Channel Mod sheet contents / actions
- Changing fit math beyond accounting for the wider combined chip width in
  the fit check (the chip appears only when the *shield tile* already failed
  the fit — combined chip replaces gear only, does not reintroduce a second
  tile)
- Showing Moderation in Options while the shield is visible on the bar

## Testing

- Fit helper / cluster: when `canMod` and width too tight → no separate
  shield; options button is combined chrome (or exposes folded flag).
- Options sheet: folded → featured card present and opens Mod sheet; not
  folded + canMod → no Moderation row/card; cannot mod → neither.
- Existing options nav rows unchanged when folded.
