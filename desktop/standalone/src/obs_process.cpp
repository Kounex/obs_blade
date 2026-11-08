#include "obs_process.hpp"

#include <QDir>
#include <QFileInfo>
#include <QProcess>
#include <QStandardPaths>

#ifdef Q_OS_WIN
#include <windows.h>
#include <tlhelp32.h>
#endif

namespace obs_process {

#ifdef Q_OS_WIN

bool running()
{
	/// The process name OBS's own virtual camera looks for
	/// (plugins/win-dshow/virtualcam-module/virtualcam-filter.cpp)
	HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
	if (snapshot == INVALID_HANDLE_VALUE)
		return false;
	PROCESSENTRY32W entry{};
	entry.dwSize = sizeof(entry);
	bool found = false;
	for (BOOL ok = Process32FirstW(snapshot, &entry); ok; ok = Process32NextW(snapshot, &entry)) {
		if (_wcsicmp(entry.szExeFile, L"obs64.exe") == 0) {
			found = true;
			break;
		}
	}
	CloseHandle(snapshot);
	return found;
}

namespace {

QString readUninstallValue(const wchar_t *name)
{
	/// The installer's uninstall key, 32-bit view (the updater writes it
	/// there: frontend/updater/updater.cpp UpdateRegistryVersion)
	HKEY key;
	if (RegOpenKeyExW(HKEY_LOCAL_MACHINE, L"Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\OBS Studio", 0,
			  KEY_READ | KEY_WOW64_32KEY, &key) != ERROR_SUCCESS)
		return {};
	wchar_t buffer[MAX_PATH * 2] = {};
	DWORD size = sizeof(buffer);
	DWORD type = 0;
	QString value;
	if (RegQueryValueExW(key, name, nullptr, &type, reinterpret_cast<LPBYTE>(buffer), &size) == ERROR_SUCCESS &&
	    (type == REG_SZ || type == REG_EXPAND_SZ))
		value = QString::fromWCharArray(buffer).trimmed().remove(QLatin1Char('"'));
	RegCloseKey(key);
	return value;
}

QString installDir()
{
	QString dir = readUninstallValue(L"InstallLocation");
	if (dir.isEmpty()) {
		const QString uninstaller = readUninstallValue(L"UninstallString");
		if (!uninstaller.isEmpty())
			dir = QFileInfo(uninstaller).absolutePath();
	}
	if (dir.isEmpty())
		dir = qEnvironmentVariable("ProgramFiles", "C:\\Program Files") + "\\obs-studio";
	return dir;
}

} // namespace

bool start(QString *error)
{
	/// As OBS's updater launches it: bin\64bit\obs64.exe with that folder as
	/// working directory (frontend/updater/updater.cpp LaunchOBS)
	const QString bin = QDir(installDir()).filePath("bin/64bit");
	const QString exe = QDir(bin).filePath("obs64.exe");
	if (!QFileInfo::exists(exe)) {
		if (error)
			*error = QStringLiteral("OBS Studio wasn't found (%1)").arg(QDir::toNativeSeparators(exe));
		return false;
	}
	return QProcess::startDetached(exe, {}, bin);
}

#else

bool running()
{
	/// macOS: "OBS" when launched from Finder / open, "obs" from the
	/// binary path; Linux (native and Flatpak): "obs"
	QProcess pgrep;
	pgrep.start(QStringLiteral("pgrep"), {QStringLiteral("-ix"), QStringLiteral("obs")});
	if (!pgrep.waitForFinished(2000))
		return false;
	return pgrep.exitCode() == 0;
}

bool start(QString *error)
{
#ifdef Q_OS_MACOS
	const bool ok = QProcess::startDetached(QStringLiteral("open"),
						{QStringLiteral("-b"), QStringLiteral("com.obsproject.obs-studio")});
	if (!ok && error)
		*error = QStringLiteral("OBS Studio wasn't found");
	return ok;
#else
	const QString obs = QStandardPaths::findExecutable(QStringLiteral("obs"));
	if (!obs.isEmpty())
		return QProcess::startDetached(obs, {});
	const QString flatpak = QStandardPaths::findExecutable(QStringLiteral("flatpak"));
	if (!flatpak.isEmpty())
		return QProcess::startDetached(flatpak,
					       {QStringLiteral("run"), QStringLiteral("com.obsproject.Studio")});
	if (error)
		*error = QStringLiteral("OBS Studio wasn't found (no obs on PATH, no Flatpak)");
	return false;
#endif
}

#endif

} // namespace obs_process
