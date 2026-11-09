// Finding and starting OBS Studio on each OS (the standalone's watcher).
#pragma once

#include <QString>

namespace obs_process {

/// OBS runs right now (process name: obs64.exe / OBS / obs)
bool running();

/// Starts OBS; false when no install was found. On failure [error] says why.
bool start(QString *error = nullptr);

/// Brings a running OBS to the front (macOS: a window the plugin raises
/// stays behind the active app otherwise; elsewhere the plugin's raise is
/// all there is)
void bringToFront();

/// Phone-requested starts only, OBS not running: removes the marks OBS 32
/// leaves after a crash (`obs-studio/.sentinel/run_*` in its config dir,
/// frontend/utility/CrashHandler.cpp). Otherwise it opens to a "Launch in
/// Safe Mode / Normally" dialog nobody at the PC answers - and Safe Mode
/// turns the WebSocket off. Returns how many were removed.
int clearCrashMarks();

} // namespace obs_process
