/* OBS Blade Remote bridge core - C ABI (desktop/core/src/ffi.rs).
 *
 * Everything crosses as JSON. Commands and events: src/api.rs.
 * The callback runs on the bridge's own threads: copy the string and
 * marshal to your UI thread (Qt: QMetaObject::invokeMethod, queued).
 * `user` must stay valid until obb_stop() returns; no callback runs after.
 */
#pragma once

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct ObbBridge ObbBridge;
typedef void (*obb_event_callback)(const char *json, void *user);

/* config: {"kind": "plugin"|"standalone", "name"?, "relay_url"?,
 *          "state_path"?, "obs_ws_config"?}. NULL on bad config. */
ObbBridge *obb_start(const char *config_json, obb_event_callback callback, void *user);

/* command: {"cmd": "pair", "code": "..."} etc. false if unknown/malformed. */
bool obb_command(ObbBridge *bridge, const char *command_json);

/* obs_exit: OBS is closing cleanly (the plugin on OBS_FRONTEND_EVENT_EXIT). */
void obb_stop(ObbBridge *bridge, bool obs_exit);

const char *obb_version(void);

#ifdef __cplusplus
}
#endif
