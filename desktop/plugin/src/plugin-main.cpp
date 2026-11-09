/*
OBS Blade Remote - OBS plugin shell
Copyright (C) 2026 Kounex

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program. If not, see <https://www.gnu.org/licenses/>
*/

// Thin shell around the Rust core (desktop/core, C ABI obs_blade_bridge.h):
// starts it once OBS has loaded, answers the app's vendor requests, opens
// the shared panel (desktop/ui) from Tools -> OBS Blade Remote and stops it
// on OBS exit. Design: docs/superpowers/specs/2026-11-07-remote-relay-design.md

#include <obs-frontend-api.h>
#include <obs-module.h>
#include <plugin-support.h>

#include "obs-websocket-api.h"
#include "obs_blade_bridge.h"
#include "remote_panel.hpp"

#include <QAction>
#include <QApplication>
#include <QDialog>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMainWindow>
#include <QMetaObject>
#include <QPointer>
#include <QVBoxLayout>

#include <filesystem>
#include <mutex>
#include <string>

OBS_DECLARE_MODULE()
OBS_MODULE_USE_DEFAULT_LOCALE(PLUGIN_NAME, "en-US")

MODULE_EXPORT const char *obs_module_name(void)
{
	return "OBS Blade Remote";
}

MODULE_EXPORT const char *obs_module_description(void)
{
	return "Control this OBS from the OBS Blade app anywhere (Pro): end-to-end encrypted, no port forwarding.";
}

namespace {

/// Vendor the app calls (lib/utils/remote/remote_relay_client.dart
/// kRemoteBridgeVendor) and the standalone probes (monitor.rs VENDOR)
constexpr const char *kVendor = "obs-blade-bridge";

ObbBridge *g_bridge = nullptr;
std::mutex g_stateMutex;
QJsonObject g_state;
QPointer<QDialog> g_dialog;
QPointer<obb_ui::RemotePanel> g_panel;

void send(const QJsonObject &command)
{
	if (!g_bridge)
		return;
	const QByteArray json = QJsonDocument(command).toJson(QJsonDocument::Compact);
	obb_command(g_bridge, json.constData());
}

/// Core events arrive on the bridge's threads
void onEvent(const char *json, void *)
{
	const QJsonObject event = QJsonDocument::fromJson(QByteArray(json)).object();
	const QString type = event["type"].toString();
	if (type == "log") {
		const QString level = event["level"].toString();
		obs_log(level == "error" ? LOG_ERROR : level == "warn" ? LOG_WARNING : LOG_INFO, "%s",
			event["message"].toString().toUtf8().constData());
		return;
	}
	if (type == "pair_result") {
		obs_log(LOG_INFO, "pairing %s", event["ok"].toBool() ? "done" : "refused");
		return;
	}
	if (type != "state")
		return;
	{
		std::lock_guard<std::mutex> lock(g_stateMutex);
		g_state = event;
	}
	QMetaObject::invokeMethod(
		qApp,
		[event] {
			if (!g_panel)
				return;
			/// A hint appearing grows the dialog (fitWindowToContent)
			g_panel->applyState(event);
		},
		Qt::QueuedConnection);
}

QJsonObject currentState()
{
	std::lock_guard<std::mutex> lock(g_stateMutex);
	return g_state;
}

/// `Pair {code, app_key}` - the app hands over its pairing code and
/// end-to-end key while connected on the LAN. The bridge's key goes back as
/// the obs-blade-pair-ack CustomEvent after the redeem (and here, for
/// convenience).
void onPair(obs_data_t *request, obs_data_t *response, void *)
{
	const char *code = obs_data_get_string(request, "code");
	const char *appKey = obs_data_get_string(request, "app_key");
	if (!code || !*code) {
		obs_data_set_bool(response, "accepted", false);
		return;
	}
	send(QJsonObject{{"cmd", "pair"}, {"code", code}, {"app_key", appKey ? appKey : ""}});
	obs_data_set_bool(response, "accepted", true);
	const QString bridgeKey = currentState()["bridge_key"].toString();
	if (!bridgeKey.isEmpty())
		obs_data_set_string(response, "bridge_key", bridgeKey.toUtf8().constData());
}

/// `Status` - the standalone asks it to know the plugin runs (then it only
/// watches OBS)
void onStatus(obs_data_t *, obs_data_t *response, void *)
{
	const QJsonObject state = currentState();
	obs_data_set_string(response, "version", obb_version());
	obs_data_set_string(response, "relay", state["relay"].toString().toUtf8().constData());
	obs_data_set_bool(response, "paired", state["paired"].toBool());
}

void openPanel()
{
	if (g_dialog) {
		g_dialog->show();
		g_dialog->raise();
		g_dialog->activateWindow();
		return;
	}
	auto *main = static_cast<QMainWindow *>(obs_frontend_get_main_window());
	auto *dialog = new QDialog(main);
	dialog->setWindowTitle(QStringLiteral("OBS Blade Remote"));
	dialog->setAttribute(Qt::WA_DeleteOnClose);
	dialog->setMinimumWidth(420);
	auto *layout = new QVBoxLayout(dialog);
	auto *panel = new obb_ui::RemotePanel(send, obb_ui::Shell::Plugin, dialog);
	layout->addWidget(panel);
	obb_ui::fitWindowToContent(dialog);
	panel->applyState(currentState());
	g_dialog = dialog;
	g_panel = panel;
	dialog->adjustSize();
	dialog->show();
}

void stopBridge(bool obsExit)
{
	if (!g_bridge)
		return;
	ObbBridge *bridge = g_bridge;
	g_bridge = nullptr;
	obb_stop(bridge, obsExit);
}

void onFrontendEvent(enum obs_frontend_event event, void *)
{
	/// A clean exit tells the relay "OBS closed" (not a crash)
	if (event == OBS_FRONTEND_EVENT_EXIT)
		stopBridge(true);
}

/// obs-websocket's config.json next to our own plugin_config folder -
/// portable installs included (the core searches the usual places
/// otherwise)
std::string obsWebsocketConfig()
{
	char *ours = obs_module_config_path("");
	if (!ours)
		return {};
	std::filesystem::path path(ours);
	bfree(ours);
	path = path.parent_path();
	if (path.filename().empty())
		path = path.parent_path();
	return (path.parent_path() / "obs-websocket" / "config.json").string();
}

} // namespace

bool obs_module_load(void)
{
	obs_log(LOG_INFO, "loaded (core %s)", obb_version());
	return true;
}

/// Vendor requests must be registered here, after obs-websocket loaded
/// (obs-protocol-gotchas.md: "Plugin API and server config")
void obs_module_post_load(void)
{
	QJsonObject config{{"kind", "plugin"}};
	const std::string wsConfig = obsWebsocketConfig();
	if (!wsConfig.empty())
		config["obs_ws_config"] = QString::fromStdString(wsConfig);
	const QByteArray json = QJsonDocument(config).toJson(QJsonDocument::Compact);
	g_bridge = obb_start(json.constData(), onEvent, nullptr);
	if (!g_bridge) {
		obs_log(LOG_ERROR, "the bridge core didn't start");
		return;
	}

	obs_websocket_vendor vendor = obs_websocket_register_vendor(kVendor);
	if (vendor) {
		obs_websocket_vendor_register_request(vendor, "Pair", onPair, nullptr);
		obs_websocket_vendor_register_request(vendor, "Status", onStatus, nullptr);
	} else {
		obs_log(LOG_WARNING, "obs-websocket isn't available - pairing works through the standalone only");
	}

	obs_frontend_add_event_callback(onFrontendEvent, nullptr);
	QAction *action = static_cast<QAction *>(obs_frontend_add_tools_menu_qaction("OBS Blade Remote"));
	QObject::connect(action, &QAction::triggered, [] { openPanel(); });
}

void obs_module_unload(void)
{
	obs_frontend_remove_event_callback(onFrontendEvent, nullptr);
	stopBridge(false);
	obs_log(LOG_INFO, "unloaded");
}
