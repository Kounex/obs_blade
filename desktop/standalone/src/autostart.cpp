#include "autostart.hpp"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSettings>
#include <QStandardPaths>

namespace autostart {

namespace {

constexpr const char *kLabel = "com.kounex.obs-blade-remote";

QString executable()
{
	return QCoreApplication::applicationFilePath();
}

#if defined(Q_OS_MACOS)

QString plistPath()
{
	return QDir::homePath() + "/Library/LaunchAgents/" + kLabel + ".plist";
}

#elif defined(Q_OS_LINUX)

QString desktopPath()
{
	const QString config = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation);
	return config + "/autostart/obs-blade-remote.desktop";
}

#endif

} // namespace

bool enabled()
{
#if defined(Q_OS_WIN)
	QSettings run(R"(HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run)", QSettings::NativeFormat);
	return run.contains("OBS Blade Remote");
#elif defined(Q_OS_MACOS)
	return QFile::exists(plistPath());
#else
	return QFile::exists(desktopPath());
#endif
}

bool setEnabled(bool on)
{
#if defined(Q_OS_WIN)
	QSettings run(R"(HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run)", QSettings::NativeFormat);
	if (on)
		run.setValue("OBS Blade Remote", QString("\"%1\" --background").arg(QDir::toNativeSeparators(executable())));
	else
		run.remove("OBS Blade Remote");
	run.sync();
	return run.status() == QSettings::NoError;
#elif defined(Q_OS_MACOS)
	const QString path = plistPath();
	if (!on)
		return !QFile::exists(path) || QFile::remove(path);
	QDir().mkpath(QFileInfo(path).absolutePath());
	QFile file(path);
	if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
		return false;
	const QString plist = QString(R"(<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>%1</string>
	<key>ProgramArguments</key>
	<array>
		<string>%2</string>
		<string>--background</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>ProcessType</key>
	<string>Interactive</string>
</dict>
</plist>
)")
				      .arg(kLabel, executable().toHtmlEscaped());
	return file.write(plist.toUtf8()) > 0;
#else
	const QString path = desktopPath();
	if (!on)
		return !QFile::exists(path) || QFile::remove(path);
	QDir().mkpath(QFileInfo(path).absolutePath());
	QFile file(path);
	if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
		return false;
	/// An AppImage moves with its file: APPIMAGE is its real path
	const QString exe = qEnvironmentVariable("APPIMAGE", executable());
	const QString entry = QString("[Desktop Entry]\nType=Application\nName=OBS Blade Remote\n"
				      "Exec=\"%1\" --background\nX-GNOME-Autostart-enabled=true\n")
				      .arg(exe);
	return file.write(entry.toUtf8()) > 0;
#endif
}

} // namespace autostart
