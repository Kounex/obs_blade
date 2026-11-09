// Finding and starting OBS Studio on each OS (the standalone's watcher).
#pragma once

#include <QString>

namespace obs_process {

/// OBS runs right now (process name: obs64.exe / OBS / obs)
bool running();

/// The running OBS's executable (Windows, Linux; empty on macOS, where
/// OBS has no portable mode and is started by its bundle id, and for a
/// Flatpak OBS, whose path isn't one on the host)
QString runningExe();

/// Starts OBS: [knownExe] (the one last seen running, `state.obs_exe`)
/// when it still exists - portable installs - else the regular install.
/// False when none was found; on failure [error] says why.
bool start(const QString &knownExe, QString *error = nullptr);

/// Brings a running OBS to the front (macOS: a window the plugin raises
/// stays behind the active app otherwise; elsewhere the plugin's raise is
/// all there is)
void bringToFront();

/// Phone-requested starts only, OBS not running: removes the marks OBS 32
/// leaves after a crash (`obs-studio/.sentinel/run_*` in its config dir,
/// frontend/utility/CrashHandler.cpp). Otherwise it opens to a "Launch in
/// Safe Mode / Normally" dialog nobody at the PC answers - and Safe Mode
/// turns the WebSocket off. [knownExe] adds a portable install's config.
/// Returns how many were removed.
int clearCrashMarks(const QString &knownExe);

} // namespace obs_process
