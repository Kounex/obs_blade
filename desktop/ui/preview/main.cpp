// Renders RemotePanel for each state the core can report (see
// desktop/core/src/shared.rs emit_state) into <out>/panel_<name>.png.
#include "remote_panel.hpp"

#include <QApplication>
#include <QDateTime>
#include <QDir>
#include <QJsonArray>
#include <QJsonObject>
#include <QLayout>
#include <QPalette>
#include <QStyleFactory>
#include <QToolButton>
#include <QVBoxLayout>
#include <cstdio>
#include <QElapsedTimer>
#include <QThread>

namespace {

QJsonObject base()
{
	const qint64 now = QDateTime::currentSecsSinceEpoch();
	return QJsonObject{
		{"type", "state"},       {"kind", "plugin"},  {"relay", "online"},
		{"detail", QJsonValue()}, {"obs", "running"},  {"paired", true},
		{"enabled", true},       {"version", "0.4.0"}, {"preview_max_edge", 640},
		{"preview_jpeg_quality", 60}, {"obs_port", QJsonValue()}, {"obs_password_set", false},
		{"devices",
		 QJsonArray{
			 QJsonObject{{"id", "d_1"}, {"name", "iPhone 17 Pro"}, {"platform", "ios"}, {"created_at", now - 86400}, {"last_used", now}, {"connected", true}},
			 QJsonObject{{"id", "d_2"}, {"name", "iPhone 17 Pro"}, {"platform", "ios"}, {"created_at", now - 40 * 86400}, {"last_used", now - 3 * 86400}, {"connected", false}},
			 QJsonObject{{"id", "d_3"}, {"name", "iPad Pro 11-Inch (M5)"}, {"platform", "ios"}, {"created_at", now - 400 * 86400}, {"last_used", now - 9 * 86400}, {"connected", false}},
		 }},
	};
}

QJsonObject with(QJsonObject state, std::initializer_list<std::pair<QString, QJsonValue>> changes)
{
	for (const auto &[key, value] : changes)
		state[key] = value;
	return state;
}

void dark(QApplication &app)
{
	/// Close to OBS's default dark theme (Yami)
	QPalette p;
	p.setColor(QPalette::Window, QColor(0x1d, 0x1f, 0x26));
	p.setColor(QPalette::WindowText, QColor(0xe6, 0xe6, 0xe6));
	p.setColor(QPalette::Base, QColor(0x27, 0x2a, 0x33));
	p.setColor(QPalette::Text, QColor(0xe6, 0xe6, 0xe6));
	p.setColor(QPalette::Button, QColor(0x3c, 0x40, 0x4b));
	p.setColor(QPalette::ButtonText, QColor(0xe6, 0xe6, 0xe6));
	p.setColor(QPalette::PlaceholderText, QColor(0x9a, 0x9c, 0xa3));
	app.setPalette(p);
}

/// Runs the event loop for [ms] (animations, queued layout requests)
void settle(QApplication &app, int ms = 400)
{
	QElapsedTimer timer;
	timer.start();
	while (timer.elapsed() < ms) {
		app.processEvents();
		QThread::msleep(5);
	}
}

} // namespace

int main(int argc, char **argv)
{
	QApplication app(argc, argv);
	/// --native: the platform's own style and palette (what the standalone
	/// shows on macOS / Windows) instead of Fusion close to OBS's dark theme
	const bool native = argc > 2 && QString::fromLocal8Bit(argv[2]) == QStringLiteral("--native");
	if (!native) {
		app.setStyle(QStyleFactory::create("Fusion"));
		dark(app);
	}
	const QString out = argc > 1 ? QString::fromLocal8Bit(argv[1]) : QStringLiteral(".");
	QDir().mkpath(out);

	const std::pair<const char *, QJsonObject> states[] = {
		{"online", base()},
		{"unpaired", with(base(), {{"relay", "unpaired"}, {"paired", false}, {"devices", QJsonArray()}})},
		{"ws_off", with(base(), {{"obs", "ws_off"}})},
		{"auth_failed", with(base(), {{"obs", "auth_failed"}})},
		{"offline", with(base(), {{"relay", "offline"}, {"detail", "timeout"}})},
		{"update_required", with(base(), {{"relay", "update_required"}, {"detail", "0.5.0"}})},
		{"disabled", with(base(), {{"relay", "disabled"}, {"enabled", false}})},
		{"custom_preview", with(base(), {{"preview_max_edge", 800}, {"preview_jpeg_quality", 65}})},
		{"advanced", base()},
		{"deferred", with(base(), {{"relay", "deferred"}, {"kind", "standalone"}, {"devices", QJsonArray()}})},
	};
	for (const auto &[name, state] : states) {
		for (const auto shell : {obb_ui::Shell::Plugin, obb_ui::Shell::Standalone}) {
			obb_ui::RemotePanel panel([](const QJsonObject &) {}, shell);
			if (shell == obb_ui::Shell::Standalone)
				panel.setStartAtLogin(true, [](bool) {});
			panel.applyState(state);
			if (QString::fromUtf8(name) == QStringLiteral("advanced")) {
				panel.findChild<QToolButton *>()->setChecked(true);
				settle(app);
			}
			/// The height the plugin's dialog grows to (heightForWidth -
			/// wrapped hints included)
			panel.resize(440, 100);
			panel.layout()->activate();
			panel.resize(440, qMax(panel.sizeHint().height(), panel.heightForWidth(440)));
			const QString file = QStringLiteral("%1/panel_%2_%3.png")
						     .arg(out, shell == obb_ui::Shell::Plugin ? "plugin" : "standalone", name);
			panel.grab().save(file);
		}
	}
	/// The standalone with OBS closed (its own hint)
	obb_ui::RemotePanel closed([](const QJsonObject &) {}, obb_ui::Shell::Standalone);
	closed.applyState(with(base(), {{"obs", "closed"}, {"kind", "standalone"}}));
	closed.resize(440, 100);
	closed.layout()->activate();
	closed.resize(440, qMax(closed.sizeHint().height(), closed.heightForWidth(440)));
	closed.grab().save(QStringLiteral("%1/panel_standalone_obs_closed.png").arg(out));

	/// The window follows its content: a fixed width, the height animated
	/// with Advanced opening and closing (dogfood 2026-11-09: squeezed rows,
	/// then empty room after closing)
	QWidget window;
	auto *windowLayout = new QVBoxLayout(&window);
	auto *fitted = new obb_ui::RemotePanel([](const QJsonObject &) {}, obb_ui::Shell::Standalone, &window);
	windowLayout->addWidget(fitted);
	obb_ui::fitWindowToContent(&window);
	fitted->applyState(base());
	window.show();
	settle(app, 100);
	auto *toggle = fitted->findChild<QToolButton *>();
	const auto check = [&](const char *what) {
		const int needed = window.heightForWidth(window.width());
		std::printf("window %s: %dx%d, content needs %d -> %s\n", what, window.width(), window.height(), needed,
			    window.height() == needed ? "ok" : "MISMATCH");
	};
	const int closedHeight = window.height();
	check("closed");
	window.grab().save(QStringLiteral("%1/window_closed.png").arg(out));
	toggle->setChecked(true);
	settle(app, 90);
	std::printf("window opening: height %d (between %d and the open height)\n", window.height(), closedHeight);
	window.grab().save(QStringLiteral("%1/window_opening.png").arg(out));
	settle(app);
	check("open");
	window.grab().save(QStringLiteral("%1/window_advanced.png").arg(out));
	toggle->setChecked(false);
	settle(app);
	check("closed again");
	std::printf("window closed again: %s\n", window.height() == closedHeight ? "back to the closed height" : "NOT BACK");
	return 0;
}
