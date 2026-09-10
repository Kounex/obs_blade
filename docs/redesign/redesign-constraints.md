# Redesign constraints

## Required behavior and compatibility

- iOS and Android, phone and tablet/large-window use are first-party. The first
  composition checkpoint includes both, including keyboard and large text.
- Preserve the valuable capabilities and recoveries in
  [product-model](product-model.md) and [user-flows](user-flows.md). Deferred
  vertical slices are not feature removals.
- OBS WebSocket v5 is the protocol baseline. Keep typed request/event semantics,
  authentication, scene/group identity and collection-change synchronization.
  Existing defects are not required compatibility behavior.
- Preserve Hive type IDs, field indices, enum values, box names and settings-key
  strings, including legacy spelling. Translate preferences deliberately before
  replacing their presentation; never clear user data to simplify a redesign.
- Keep purchase identifiers, restore, entitlement updates/offline mirror and
  legacy Blacksmith access. Free WebView and paid native engine paths survive.
- Preserve account secrets/configuration handling without copying real values
  into documentation, prototypes, screenshots or fixtures. Use synthetic data.
- Destructive operations and configured stream/record confirmations retain their
  safety semantics. Changing their policy requires an explicit decision.

## Engineering boundaries

Master source/tests establish the implemented baseline. Previous redesign
branches and visual artifacts are not inputs. All work stays on the new branch;
unrelated changes in the original checkout remain untouched.

Prototype code is isolated and initially fake. Production startup/navigation,
stores and persistence are unchanged during archaeology and concept selection.
Reuse MobX/GetIt logic through explicit UI state/actions adapters after validation;
do not replace state management or split DashboardStore speculatively.

The transport currently lacks command acknowledgements for callers. A new UI can
simulate pending/rejection during exploration, but integration needs explicit
resolution semantics; an optimistic store value is not proof of OBS confirmation.
Determine the smallest integration change then, with protocol tests.

## Accessibility and quality targets

These are new project requirements, not claims that master already passes:

- State remains understandable through labels/semantics as well as color; program,
  preview, muted, pending and disconnected cannot be color-only distinctions.
- Screen readers get meaningful control labels, values and focus order; changing
  tool or window size preserves useful context. Verify VoiceOver/TalkBack later.
- Support platform text scaling, reduced motion, keyboard insets and reachable
  control targets. Verify concrete sizes and contrast against actual rendered
  states when visual tokens exist; no token values are frozen at this stage.
- Validate phone portrait/landscape and tablet resizing with long labels, empty
  data and busy scenes. Avoid fixed-height compositions that clip scaled text.
- Animation communicates state or spatial continuity; it must not delay recovery
  or hide controls while waiting for an entrance animation.

## Choices still open

Primary organizing model, exact navigation, pane rules/breakpoints, appearance,
density, motion and theme translation remain open. Current 700/640 layout values,
Material/Cupertino widgets, tab count and existing theme slots are implementation
facts, not immutable requirements. New dependencies need a demonstrated need and
current compatibility/maintenance review; none is selected.
