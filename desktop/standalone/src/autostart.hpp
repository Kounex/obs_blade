// Start at login, per OS: macOS LaunchAgent, Windows HKCU Run key, Linux
// XDG autostart entry. The entry starts the app with --background (tray
// only, no window).
#pragma once

namespace autostart {

bool enabled();
bool setEnabled(bool on);

} // namespace autostart
