/*
OBS Blade Remote - standalone (tray / menu bar app)
Copyright (C) 2026 Kounex - GPL-3.0-or-later
*/

// The bridge core (desktop/core) in a tray app that runs without OBS: it
// watches OBS (closed / running for the app's messages) and starts it when
// a phone asks. If the OBS plugin is loaded, the core steps back
// (relay: deferred) and this app only watches. Spec:
// docs/superpowers/specs/2026-11-07-remote-relay-design.md

#include "autostart.hpp"
#include "obs_blade_bridge.h"
#include "obs_process.hpp"
#include "remote_panel.hpp"

#include <QAction>
#include <QApplication>
#include <QCloseEvent>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QIcon>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLockFile>
#include <QMenu>
#include <QMessageBox>
#include <QSettings>
#include <QStandardPaths>
#include <QSystemTrayIcon>
#include <QTimer>
#include <QVBoxLayout>

namespace {

ObbBridge *g_bridge = nullptr;

void send(const QJsonObject &command)
{
	if (!g_bridge)
		return;
	const QByteArray json = QJsonDocument(command).toJson(QJsonDocument::Compact);
	obb_command(g_bridge, json.constData());
}

/// The core's folder for bridge.json (Rust dirs::config_dir): Qt's
/// "config" locations differ on macOS (Preferences) and Windows (Local)
QString bridgeDir()
{
#if defined(Q_OS_MACOS)
	const QString base = QDir::homePath() + "/Library/Application Support";
#elif defined(Q_OS_WIN)
	const QString base = qEnvironmentVariable("APPDATA");
#else
	const QString base = qEnvironmentVariable("XDG_CONFIG_HOME", QDir::homePath() + "/.config");
#endif
	return base + "/obs-blade-remote";
}

/// Support log next to bridge.json (kept small)
void logLine(const QString &line)
{
	const QString dir = bridgeDir();
	QDir().mkpath(dir);
	QFile file(dir + "/standalone.log");
	if (file.size() > 1024 * 1024)
		file.remove();
	if (file.open(QIODevice::Append | QIODevice::Text))
		file.write((QDateTime::currentDateTime().toString(Qt::ISODate) + " " + line + "\n").toUtf8());
}

class PanelWindow : public QWidget {
public:
	obb_ui::RemotePanel *panel;

	PanelWindow()
	{
		setWindowTitle(QStringLiteral("OBS Blade Remote"));
		setWindowIcon(QIcon(QStringLiteral(":/app-256.png")));
		setMinimumWidth(440);
		auto *layout = new QVBoxLayout(this);
		panel = new obb_ui::RemotePanel(send, obb_ui::Shell::Standalone, this);
		layout->addWidget(panel);
	}

	void present()
	{
		show();
		raise();
		activateWindow();
	}

protected:
	/// Closing the window keeps the app in the tray
	void closeEvent(QCloseEvent *event) override
	{
		hide();
		event->ignore();
	}
};

/// Tray / menu bar status line for a core state
QString statusText(const QJsonObject &state)
{
	const QString relay = state["relay"].toString();
	const QString obs = state["obs"].toString();
	if (relay == "deferred")
		return QStringLiteral("Handled by the OBS plugin");
	if (relay == "unpaired")
		return QStringLiteral("Not set up yet");
	if (relay == "disabled")
		return QStringLiteral("Remote access off");
	if (relay == "offline")
		return QStringLiteral("Relay unreachable - retrying");
	if (relay == "update_required")
		return QStringLiteral("Update required");
	if (relay == "online")
		return obs == "running" ? QStringLiteral("Online") : QStringLiteral("Online - OBS not running");
	return QStringLiteral("Connecting...");
}

} // namespace

int main(int argc, char **argv)
{
	QApplication app(argc, argv);
	QApplication::setApplicationName(QStringLiteral("OBS Blade Remote"));
	QApplication::setOrganizationName(QStringLiteral("Kounex"));
	QApplication::setOrganizationDomain(QStringLiteral("kounex.com"));
	QApplication::setQuitOnLastWindowClosed(false);
	const bool background = app.arguments().contains(QStringLiteral("--background"));

	/// One instance per user
	QLockFile lock(QDir::temp().filePath(QStringLiteral("obs-blade-remote-%1.lock").arg(qEnvironmentVariable("USER", qEnvironmentVariable("USERNAME")))));
	lock.setStaleLockTime(0);
	if (!lock.tryLock(100)) {
		if (!background)
			QMessageBox::information(nullptr, QStringLiteral("OBS Blade Remote"),
						 QStringLiteral("OBS Blade Remote is already running - look for it in the menu bar / tray."));
		return 0;
	}

	PanelWindow window;
	QSystemTrayIcon tray;
	QMenu menu;
	QAction *status = menu.addAction(QStringLiteral("Starting..."));
	status->setEnabled(false);
	menu.addSeparator();
	QAction *open = menu.addAction(QStringLiteral("Open OBS Blade Remote..."));
	QAction *startObs = menu.addAction(QStringLiteral("Start OBS"));
	menu.addSeparator();
	QAction *quit = menu.addAction(QStringLiteral("Quit OBS Blade Remote"));
	QObject::connect(open, &QAction::triggered, &window, &PanelWindow::present);
	QObject::connect(startObs, &QAction::triggered, [] {
		QString error;
		if (!obs_process::start(&error))
			QMessageBox::warning(nullptr, QStringLiteral("OBS Blade Remote"), error);
	});
	QObject::connect(quit, &QAction::triggered, &app, &QApplication::quit);

#ifdef Q_OS_MACOS
	/// Menu bar template image: the system tints it for light / dark
	QIcon trayIcon;
	trayIcon.addFile(QStringLiteral(":/tray-mask.png"));
	trayIcon.addFile(QStringLiteral(":/tray-mask@2x.png"));
	trayIcon.setIsMask(true);
#else
	QIcon trayIcon(QStringLiteral(":/app-64.png"));
#endif
	tray.setIcon(trayIcon);
	tray.setToolTip(QStringLiteral("OBS Blade Remote"));
	tray.setContextMenu(&menu);
#ifndef Q_OS_MACOS
	QObject::connect(&tray, &QSystemTrayIcon::activated, [&window](QSystemTrayIcon::ActivationReason reason) {
		if (reason == QSystemTrayIcon::Trigger || reason == QSystemTrayIcon::DoubleClick)
			window.present();
	});
#endif
	tray.show();

	/// Start at login: on by default (user decision 2026-11-08), set once
	QSettings settings;
	if (!settings.value(QStringLiteral("autostartInitialized")).toBool()) {
		autostart::setEnabled(true);
		settings.setValue(QStringLiteral("autostartInitialized"), true);
	}
	window.panel->setStartAtLogin(autostart::enabled(), [](bool on) { autostart::setEnabled(on); });

	/// Core events arrive on the bridge's threads
	struct Context {
		PanelWindow *window;
		QAction *status;
		QSystemTrayIcon *tray;
	} context{&window, status, &tray};
	g_bridge = obb_start(
		R"({"kind": "standalone"})",
		[](const char *json, void *user) {
			const QJsonObject event = QJsonDocument::fromJson(QByteArray(json)).object();
			auto *ctx = static_cast<Context *>(user);
			QMetaObject::invokeMethod(
				qApp,
				[event, ctx] {
					const QString type = event["type"].toString();
					if (type == "state") {
						ctx->window->panel->applyState(event);
						ctx->status->setText(statusText(event));
						ctx->tray->setToolTip(QStringLiteral("OBS Blade Remote - %1").arg(statusText(event)));
					} else if (type == "start_obs") {
						logLine(QStringLiteral("a phone asked to start OBS"));
						if (!obs_process::running()) {
							QString error;
							if (!obs_process::start(&error))
								logLine(QStringLiteral("starting OBS failed: %1").arg(error));
						}
					} else if (type == "log") {
						logLine(QStringLiteral("[%1] %2").arg(event["level"].toString(), event["message"].toString()));
					} else if (type == "pair_result") {
						logLine(QStringLiteral("pairing %1").arg(event["ok"].toBool() ? "done" : "refused"));
					}
				},
				Qt::QueuedConnection);
		},
		&context);
	if (!g_bridge) {
		QMessageBox::critical(nullptr, QStringLiteral("OBS Blade Remote"), QStringLiteral("The bridge didn't start."));
		return 1;
	}
	logLine(QStringLiteral("started (core %1)").arg(QString::fromUtf8(obb_version())));

	/// The OBS watcher: whether OBS runs tells "closed" from "WebSocket
	/// server off" for the app's messages
	int lastRunning = -1;
	auto checkObs = [&lastRunning, startObs] {
		const bool running = obs_process::running();
		startObs->setEnabled(!running);
		if (int(running) != lastRunning) {
			lastRunning = int(running);
			send(QJsonObject{{"cmd", "obs_running"}, {"value", running}});
		}
	};
	QTimer watcher;
	QObject::connect(&watcher, &QTimer::timeout, checkObs);
	watcher.start(2000);
	checkObs();

	/// First start (not from login): show the panel once so people see it
	if (!background)
		window.present();

	const int code = app.exec();
	obb_stop(g_bridge, false);
	g_bridge = nullptr;
	return code;
}
