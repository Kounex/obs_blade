# User intent journeys

Source evidence is mapped in [business-logic-map](business-logic-map.md). These
journeys describe intent and outcomes, not mandatory routes or dialogs.

| Journey | Intent sequence | Recovery and preservation |
|---|---|---|
| Reach OBS | Choose a saved endpoint or discover/scan/enter one → authenticate → synchronize → understand the active production | Distinguish unreachable, handshake timeout, password failure and incompatible RPC; retain editable input. Offer save for an unsaved connection. |
| Change the visible production | Identify current output → choose a scene or stage preview → inspect sources → change visibility/sound → observe OBS state | Make program versus preview targeting clear; preserve group identity, local hiding and studio preference. External OBS changes update the same state. |
| Start or end capture | Inspect current stream/record state → request change → apply configured confirmation → observe actual output state | Independent stream/record confirmation preferences; paused recording is active. Dispatch alone is not success. |
| Keep operating through interruption | Notice stale/disconnected status → understand automatic retry → recover or leave → resume with fresh state | Retry limits remain configurable; no stale controls masquerading as live; explicit disconnect and OBS termination differ. |
| Follow an audience | Choose platform/engine/destination → satisfy access prerequisites → read → scroll back → return live | Preserve engine choice, per-channel buffers and WebView lifetime. Entitlement, account and network failures are distinct. |
| Participate or moderate | Compose/reply or inspect a message → act with available role/scope → observe result | Failed drafts and unresolved moderation rows remain recoverable; successful actions reconcile against server echoes. No invented parity between Twitch and YouTube. |
| Inspect health and history | Notice live metrics → investigate a concern → later locate a locally observed session → inspect/name/favorite/delete | History may be partial; stream/record samples differ. Search should eventually cover the whole collection, including latest entries. |
| Adapt the tool | Choose accessible reading/density and relevant controls → save preferences → continue working | Preserve stored choices while translating their meaning; new geometry need not reproduce old slots. |
| Unlock or restore capabilities | Inspect available capability → understand entitlement → purchase/restore → see access update | Cancellation/error/offline/expired entitlement differ. Preserve old ownership and free capabilities. |
| Manage local data | Understand category and consequence → confirm deletion → observe updated data | Preserve purchase ownership. Current delete-all implementation has coverage gaps; resolve scope before migrating it. |

## First vertical slice candidate

**Connect → understand current production → change scene and sound → recover from
a connection interruption → disconnect.** This exercises session ownership,
information hierarchy, control targeting, asynchronous feedback, local state and
phone/tablet composition without requiring every product feature at once.

Prototype scenarios should include:

1. Returning connection and first use with no saved endpoint; wrong password and
   reachable-but-not-yet-ready states.
2. Ordinary scene selection and a studio-mode variant showing distinct program
   and preview; include long names, many scenes and a grouped source.
3. Mute/volume with a delayed or rejected command and an external OBS change.
4. Reconnecting with stale values, successful resynchronization, failed retries
   and explicit exit.
5. Phone with keyboard/large text and tablet with simultaneous context/tools;
   resize without losing selected context or owning a second session.

Show output status and representative chat content in the composition to test
attention balance. Real purchase/auth/moderation integration and stream/record
commands are later slices. This is sequencing, not feature removal.
