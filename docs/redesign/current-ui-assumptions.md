# Existing UI assumptions to challenge

These are source-based opportunities, not approved removals. Preserve product
semantics while questioning the presentation. Sources are indexed in
[business-logic-map](business-logic-map.md).

| Inherited assumption | Why it is optional | Redesign opportunity / guard |
|---|---|---|
| Connection and operation must be separate routes | Home/Dashboard lifecycle currently defines the boundary, not the protocol | A continuous session experience can own handshake, readiness and recovery independently of navigation. |
| Scenes, sources, sound, chat and statistics need their current tabs/columns | Existing composition follows widget groups | Compare object workspace, activity focus and chosen-action surface before fixing navigation. |
| Selecting a scene means executing a command | `SceneButton` mixes command dispatch, optimistic selection and local hide editing | Separate inspection, preview and program semantics. Avoid accidental output changes when exploring tools. |
| App studio preference determines the meaning of scene actions implicitly | Actual OBS studio mode and `ExposeStudioControls` jointly control targets | Make action target understandable; preserve the preference until an explicit behavior decision replaces it. |
| Route visibility is a suitable lifetime for a session | Dashboard mount owns setup/disposal; Settings checks a route for wakelock | Session ownership should survive tool changes and phone/tablet recomposition. |
| Every start/stop confirmation needs today's modal | Confirmation policy matters; presentation is incidental | Keep independently suppressible stream/record safeguards, choose interaction in context. |
| Frequent controls should be exposed through Settings | Exposure/order are stored preferences, not evidence that distant setup is best | Consider contextual customization after proving useful defaults. |
| Chat is only a dashboard section | Chat stores have independent transport and channel state | Preserve its lifetime when tools change; defer standalone chat navigation until prioritization is resolved. |
| Chat gestures have fixed local screen coordinates | WebView gesture arbitration uses Y bounds 150–450 | Replace geometry assumptions when composing a new viewport; verify scroll/input on real devices. |
| History's latest entries sit outside filtered results | Latest entries are removed from the previous-items list | One searchable collection can retain all entries; any promoted summary should not hide a matching result. |
| Rebuilding history should reset filter state | `StatisticsView.build` resets its lazy store | State should follow user intent and dataset changes, not arbitrary rebuilds. |
| Phone/tablet is one fixed width or a forced toggle | Current wrapper uses width >700 or `EnforceTabletMode`; content constraint is 640 | Preserve large-screen capability and stored preference intent; prototype panes from content needs and available window space. |
| Current theme fields require identical containers | Persisted app bar/card/tab colors reflect old composition | Retain data and purchased access; define a deliberate mapping once new components exist. |

## Baseline risks, not behavior to reproduce

- **Command truth:** requests return void; failed responses are logged. Scene
  commands optimistically change local state. No verified acknowledgement API
  exists for the new UI to consume. Plan the adapter seam before integrating
  pending/error states; do not label a simulated acknowledgement as implemented.
- **Transition naming:** the existing transition widget sends
  `SetCurrentProgramScene`, not a dedicated studio-transition request. Verify
  intended OBS behavior before offering a new “take” interaction.
- **Retry lifetime:** the reconnect loop awaits then accesses active session,
  with no visible cancellation token. Exit/retry races require focused probes
  before relocating ownership.
- **Grouped sources:** commands target parent groups, while enabled-event
  filtering checks the displayed scene. Probe group-child echo behavior.
- **History:** duration “Between” filter currently accepts everything; detail
  assumes populated samples/duration. Address when history is migrated.
- **Data deletion:** `deleteAllUserDataPreservingEntitlements` omits
  `PastRecordData`, `Hotkey` and `PurchasedTip` boxes despite its all-data wording.
  Existing tests check entitlement flags and logs, not those boxes. Retention of
  purchase history may be intentional; define the promised scope before changing
  deletion. This archaeology does not run destructive operations or fix them.
- **Entitlement enforcement:** native chat gates are in presentation while
  stores can connect independently. Keep the gate in the replacement contract;
  do not infer background transport enforcement from visible locked controls.

No production fixes have been applied. These findings select later probes; they
are not justification for a broad store rewrite or unrelated cleanup now.
