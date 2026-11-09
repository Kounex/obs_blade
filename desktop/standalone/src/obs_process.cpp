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

namespace {

/// A portable install's base folder from its executable - mirrors
/// obs_config::install_base in the core (frontend/OBSApp.cpp BASE_PATH:
/// "../.." from bin/64bit on Windows, ".." from bin on Linux)
QString installBase(const QString &exe)
{
	QDir dir = QFileInfo(exe).absoluteDir();
#ifdef Q_OS_WIN
	dir.cdUp();
#endif
	dir.cdUp();
	return dir.absolutePath();
}

/// OBS only creates `config` next to itself in portable mode; without a
/// marker file it was started with --portable, so start it that way again
/// (frontend/obs-main.cpp)
QStringList portableArgs(const QString &exe)
{
	const QDir base(installBase(exe));
	for (const char *marker : {"portable_mode", "obs_portable_mode", "portable_mode.txt", "obs_portable_mode.txt"})
		if (base.exists(QString::fromLatin1(marker)))
			return {};
	return base.exists(QStringLiteral("config/obs-studio")) ? QStringList{QStringLiteral("--portable")}
								: QStringList{};
}

/// OBS resolves its data and portable config relative to the working
/// directory: start it from its own folder (as OBS's updater does)
[[maybe_unused]] bool startKnown(const QString &knownExe)
{
	if (knownExe.isEmpty() || !QFileInfo::exists(knownExe))
		return false;
	return QProcess::startDetached(knownExe, portableArgs(knownExe), QFileInfo(knownExe).absolutePath());
}

} // namespace

#ifdef Q_OS_WIN

namespace {

/// The process name OBS's own virtual camera looks for
/// (plugins/win-dshow/virtualcam-module/virtualcam-filter.cpp); 0 = none
DWORD obsPid()
{
	HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
	if (snapshot == INVALID_HANDLE_VALUE)
		return 0;
	PROCESSENTRY32W entry{};
	entry.dwSize = sizeof(entry);
	DWORD pid = 0;
	for (BOOL ok = Process32FirstW(snapshot, &entry); ok; ok = Process32NextW(snapshot, &entry)) {
		if (_wcsicmp(entry.szExeFile, L"obs64.exe") == 0) {
			pid = entry.th32ProcessID;
			break;
		}
	}
	CloseHandle(snapshot);
	return pid;
}

} // namespace

bool running()
{
	return obsPid() != 0;
}

QString runningExe()
{
	const DWORD pid = obsPid();
	if (!pid)
		return {};
	HANDLE process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
	if (!process)
		return {};
	wchar_t buffer[MAX_PATH * 4] = {};
	DWORD size = MAX_PATH * 4;
	const bool ok = QueryFullProcessImageNameW(process, 0, buffer, &size);
	CloseHandle(process);
	return ok ? QDir::fromNativeSeparators(QString::fromWCharArray(buffer, int(size))) : QString();
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

bool start(const QString &knownExe, QString *error)
{
	if (startKnown(knownExe))
		return true;
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

QString runningExe()
{
#ifdef Q_OS_MACOS
	return {};
#else
	QProcess pgrep;
	pgrep.start(QStringLiteral("pgrep"), {QStringLiteral("-ix"), QStringLiteral("obs")});
	if (!pgrep.waitForFinished(2000) || pgrep.exitCode() != 0)
		return {};
	const QString pid = QString::fromLatin1(pgrep.readAllStandardOutput()).split(QLatin1Char('\n')).value(0).trimmed();
	/// A Flatpak OBS reads /app/bin/obs - not a path on the host
	const QString exe = QFileInfo(QStringLiteral("/proc/%1/exe").arg(pid)).symLinkTarget();
	return QFileInfo::exists(exe) ? exe : QString();
#endif
}

bool start(const QString &knownExe, QString *error)
{
#ifdef Q_OS_MACOS
	Q_UNUSED(knownExe);
	const bool ok = QProcess::startDetached(QStringLiteral("open"),
						{QStringLiteral("-b"), QStringLiteral("com.obsproject.obs-studio")});
	if (!ok && error)
		*error = QStringLiteral("OBS Studio wasn't found");
	return ok;
#else
	if (startKnown(knownExe))
		return true;
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

void bringToFront()
{
#ifdef Q_OS_MACOS
	if (running())
		QProcess::startDetached(QStringLiteral("open"), {QStringLiteral("-b"), QStringLiteral("com.obsproject.obs-studio")});
#endif
}

int clearCrashMarks(const QString &knownExe)
{
	/// OBS's config dir (GetAppConfigPath): %APPDATA% / Application Support /
	/// XDG config, the Flatpak's, and a portable install's
	QStringList dirs;
	if (!knownExe.isEmpty())
		dirs << installBase(knownExe) + QStringLiteral("/config/obs-studio/.sentinel");
#if defined(Q_OS_WIN)
	dirs << qEnvironmentVariable("APPDATA") + QStringLiteral("/obs-studio/.sentinel")
	     << installDir() + QStringLiteral("/config/obs-studio/.sentinel");
#elif defined(Q_OS_MACOS)
	dirs << QDir::homePath() + QStringLiteral("/Library/Application Support/obs-studio/.sentinel");
#else
	const QString xdg = qEnvironmentVariable("XDG_CONFIG_HOME", QDir::homePath() + QStringLiteral("/.config"));
	dirs << xdg + QStringLiteral("/obs-studio/.sentinel")
	     << QDir::homePath() + QStringLiteral("/.var/app/com.obsproject.Studio/config/obs-studio/.sentinel");
#endif
	int removed = 0;
	for (const QString &path : dirs) {
		QDir dir(path);
		if (!dir.exists())
			continue;
		for (const QString &name : dir.entryList({QStringLiteral("run_*")}, QDir::Files))
			removed += dir.remove(name) ? 1 : 0;
	}
	return removed;
}

} // namespace obs_process
