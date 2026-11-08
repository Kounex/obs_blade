#include "remote_panel.hpp"

#include <QCheckBox>
#include <QComboBox>
#include <QDateTime>
#include <QFormLayout>
#include <QHBoxLayout>
#include <QJsonArray>
#include <QLabel>
#include <QLineEdit>
#include <QMessageBox>
#include <QPushButton>
#include <QSpinBox>
#include <QToolButton>
#include <QVBoxLayout>

namespace obb_ui {

namespace {

/// Preview presets for relay sessions: longest edge + JPEG quality (the
/// core rewrites the app's preview screenshots to these)
struct Preset {
	const char *label;
	int maxEdge;
	int quality;
};

constexpr Preset kPresets[] = {
	{"Data saver - 480 px", 480, 50},
	{"Balanced - 640 px (default)", 640, 60},
	{"Sharp - 960 px", 960, 70},
};

QLabel *secondary(const QString &text, QWidget *parent)
{
	auto *label = new QLabel(text, parent);
	label->setWordWrap(true);
	label->setStyleSheet("color: palette(placeholder-text);");
	return label;
}

QString dot(const char *color)
{
	return QStringLiteral("<span style=\"color:%1; font-size:14pt;\">&#9679;</span>").arg(color);
}

} // namespace

QString relativeTime(qint64 unixSeconds, qint64 nowSeconds)
{
	if (unixSeconds <= 0)
		return QStringLiteral("never used");
	const qint64 ago = qMax<qint64>(0, nowSeconds - unixSeconds);
	if (ago < 60)
		return QStringLiteral("just now");
	if (ago < 3600)
		return QStringLiteral("%1 min ago").arg(ago / 60);
	if (ago < 86400)
		return QStringLiteral("%1 h ago").arg(ago / 3600);
	const qint64 days = ago / 86400;
	return days == 1 ? QStringLiteral("yesterday") : QStringLiteral("%1 days ago").arg(days);
}

RemotePanel::RemotePanel(Send send, Shell shell, QWidget *parent) : QWidget(parent), send_(std::move(send)), shell_(shell)
{
	auto *root = new QVBoxLayout(this);
	root->setSpacing(10);
	/// The panel's minimum height follows its content (wrapped hints,
	/// device rows) - the shells' windows can't squeeze it
	root->setSizeConstraint(QLayout::SetMinimumSize);

	auto *header = new QHBoxLayout();
	auto *title = new QLabel(QStringLiteral("<b>OBS Blade Remote</b>"), this);
	version_ = secondary(QString(), this);
	version_->setWordWrap(false);
	header->addWidget(title);
	header->addStretch();
	header->addWidget(version_);
	root->addLayout(header);
	root->addWidget(secondary(QStringLiteral("Control this OBS from the OBS Blade app anywhere - "
						 "end-to-end encrypted, no port forwarding."),
				  this));

	enabled_ = new QCheckBox(QStringLiteral("Remote access"), this);
	connect(enabled_, &QCheckBox::toggled, this, [this](bool on) {
		if (!applying_)
			send_(QJsonObject{{"cmd", "set_enabled"}, {"value", on}});
	});
	root->addWidget(enabled_);

	startAtLogin_ = new QCheckBox(QStringLiteral("Start at login"), this);
	startAtLogin_->setVisible(shell_ == Shell::Standalone);
	connect(startAtLogin_, &QCheckBox::toggled, this, [this](bool on) {
		if (!applying_ && onStartAtLogin_)
			onStartAtLogin_(on);
	});
	root->addWidget(startAtLogin_);

	auto *statusRow = new QHBoxLayout();
	statusDot_ = new QLabel(this);
	status_ = new QLabel(this);
	status_->setWordWrap(true);
	statusRow->addWidget(statusDot_);
	statusRow->addWidget(status_, 1);
	root->addLayout(statusRow);

	hint_ = secondary(QString(), this);
	hint_->setTextFormat(Qt::RichText);
	root->addWidget(hint_);

	devicesBox_ = new QWidget(this);
	auto *devicesLayout = new QVBoxLayout(devicesBox_);
	devicesLayout->setContentsMargins(0, 6, 0, 0);
	devicesLayout->addWidget(new QLabel(QStringLiteral("<b>Paired devices</b>"), devicesBox_));
	devicesList_ = new QVBoxLayout();
	devicesLayout->addLayout(devicesList_);
	root->addWidget(devicesBox_);

	auto *form = new QFormLayout();
	preview_ = new QComboBox(this);
	for (const Preset &preset : kPresets)
		preview_->addItem(QString::fromUtf8(preset.label));
	connect(preview_, &QComboBox::currentIndexChanged, this, [this](int index) {
		if (applying_ || index < 0 || index >= int(std::size(kPresets)))
			return;
		send_(QJsonObject{{"cmd", "set_preview"},
				  {"max_edge", kPresets[index].maxEdge},
				  {"jpeg_quality", kPresets[index].quality}});
	});
	form->addRow(QStringLiteral("Preview over remote access"), preview_);

	root->addLayout(form);

	/// Advanced: OBS started with --websocket_port / --websocket_password
	/// (its config file doesn't know them)
	auto *advancedToggle = new QToolButton(this);
	advancedToggle->setText(QStringLiteral("Advanced"));
	advancedToggle->setCheckable(true);
	advancedToggle->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);
	advancedToggle->setArrowType(Qt::RightArrow);
	advancedToggle->setAutoRaise(true);
	root->addWidget(advancedToggle);

	advanced_ = new QWidget(this);
	auto *advancedForm = new QFormLayout(advanced_);
	advancedForm->setContentsMargins(12, 0, 0, 0);
	advancedForm->addRow(secondary(QStringLiteral("Only needed when OBS runs with --websocket_port or "
						      "--websocket_password. Leave empty to use OBS's own settings."),
				       advanced_));
	obsPort_ = new QSpinBox(advanced_);
	obsPort_->setRange(0, 65535);
	obsPort_->setSpecialValueText(QStringLiteral("From OBS"));
	obsPassword_ = new QLineEdit(advanced_);
	obsPassword_->setEchoMode(QLineEdit::Password);
	obsPassword_->setPlaceholderText(QStringLiteral("From OBS"));
	advancedForm->addRow(QStringLiteral("WebSocket port"), obsPort_);
	advancedForm->addRow(QStringLiteral("WebSocket password"), obsPassword_);
	auto *apply = new QPushButton(QStringLiteral("Apply"), advanced_);
	connect(apply, &QPushButton::clicked, this, [this] {
		QJsonObject command{{"cmd", "set_obs_override"}};
		command["port"] = obsPort_->value() > 0 ? QJsonValue(obsPort_->value()) : QJsonValue();
		command["password"] = obsPassword_->text().isEmpty() ? QJsonValue() : QJsonValue(obsPassword_->text());
		send_(command);
	});
	advancedForm->addRow(QString(), apply);
	unpair_ = new QPushButton(QStringLiteral("Unpair This PC"), advanced_);
	connect(unpair_, &QPushButton::clicked, this, [this] {
		if (QMessageBox::question(this, QStringLiteral("Unpair This PC"),
					  QStringLiteral("All paired devices lose remote access to this PC. "
							 "They can set it up again from the OBS Blade app.")) ==
		    QMessageBox::Yes)
			send_(QJsonObject{{"cmd", "unpair"}});
	});
	advancedForm->addRow(QString(), unpair_);
	advanced_->setVisible(false);
	connect(advancedToggle, &QToolButton::toggled, this, [this, advancedToggle](bool open) {
		advanced_->setVisible(open);
		advancedToggle->setArrowType(open ? Qt::DownArrow : Qt::RightArrow);
	});
	root->addWidget(advanced_);
	root->addStretch();
}

void RemotePanel::setStartAtLogin(bool on, std::function<void(bool)> onChange)
{
	onStartAtLogin_ = std::move(onChange);
	applying_ = true;
	startAtLogin_->setChecked(on);
	applying_ = false;
}

void RemotePanel::applyState(const QJsonObject &state)
{
	applying_ = true;

	version_->setText(QStringLiteral("v%1").arg(state["version"].toString()));
	const bool enabled = state["enabled"].toBool(true);
	const bool paired = state["paired"].toBool();
	enabled_->setChecked(enabled);

	const QString relay = state["relay"].toString();
	const QString obs = state["obs"].toString();
	const QString detail = state["detail"].toString();

	/// Relay and OBS together: "online" only means phones reach OBS when
	/// OBS lets the bridge in (amber = the app card's warning color)
	const char *color = "#8e8e93";
	QString status;
	if (relay == "online") {
		if (obs == "running") {
			color = "#30d158";
			status = QStringLiteral("Online - phones can reach this OBS");
		} else if (obs == "closed") {
			color = "#ffc107";
			status = shell_ == Shell::Standalone ? QStringLiteral("Online - OBS isn't running")
							     : QStringLiteral("Online - OBS is closing");
		} else if (obs == "ws_off" || obs == "auth_failed") {
			color = "#ffc107";
			status = QStringLiteral("Online - but OBS doesn't let OBS Blade Remote in");
		} else {
			status = QStringLiteral("Online - checking OBS...");
		}
	} else if (relay == "connecting") {
		status = QStringLiteral("Connecting to the OBS Blade relay...");
	} else if (relay == "offline") {
		color = "#ff453a";
		status = QStringLiteral("Can't reach the OBS Blade relay - retrying");
	} else if (relay == "update_required") {
		color = "#ff453a";
		status = QStringLiteral("Update required");
	} else if (relay == "unpaired") {
		status = QStringLiteral("Not set up yet");
	} else if (relay == "disabled") {
		status = QStringLiteral("Remote access is off on this PC");
	} else if (relay == "deferred") {
		color = "#30d158";
		status = QStringLiteral("The OBS Blade Remote plugin in OBS handles remote access");
	}
	statusDot_->setText(dot(color));
	status_->setText(status);

	QStringList hints;
	if (relay == "unpaired")
		hints << QStringLiteral("In the OBS Blade app, connect to this OBS on your Wi-Fi, tap the "
					"globe on the dashboard, then <b>Set Up Remote Access</b>.");
	if (relay == "update_required")
		hints << QStringLiteral("This version is too old for the relay (needs %1 or newer).").arg(detail);
	if (obs == "ws_off")
		hints << QStringLiteral("OBS's WebSocket server is off - turn it on in OBS under "
					"<b>Tools &rarr; WebSocket Server Settings</b>.");
	else if (obs == "auth_failed")
		hints << QStringLiteral("OBS refused the WebSocket password. If OBS was started with "
					"&#8209;&#8209;websocket_password, enter it under Advanced.");
	else if (obs == "closed" && shell_ == Shell::Standalone && relay != "deferred")
		hints << QStringLiteral("Phones can start it from the OBS Blade app.");
	hint_->setText(hints.join(QStringLiteral("<br>")));
	hint_->setVisible(!hints.isEmpty());

	devicesBox_->setVisible(paired);
	rebuildDevices(state["devices"].toArray());

	applyPreview(state["preview_max_edge"].toInt(640), state["preview_jpeg_quality"].toInt(60));

	if (!obsPort_->hasFocus())
		obsPort_->setValue(state["obs_port"].isNull() ? 0 : state["obs_port"].toInt());
	if (!obsPassword_->hasFocus() && !state["obs_password_set"].toBool())
		obsPassword_->clear();
	unpair_->setEnabled(paired);

	applying_ = false;
}

void RemotePanel::rebuildDevices(const QJsonArray &devices)
{
	while (QLayoutItem *item = devicesList_->takeAt(0)) {
		if (QWidget *widget = item->widget())
			widget->deleteLater();
		delete item;
	}
	if (devices.isEmpty()) {
		devicesList_->addWidget(secondary(QStringLiteral("No devices yet."), devicesBox_));
		return;
	}
	const qint64 now = QDateTime::currentSecsSinceEpoch();
	for (const QJsonValue value : devices) {
		const QJsonObject device = value.toObject();
		auto *row = new QWidget(devicesBox_);
		auto *layout = new QHBoxLayout(row);
		layout->setContentsMargins(0, 0, 0, 0);
		layout->setSpacing(12);
		auto *name = new QLabel(device["name"].toString(), row);
		const QString seen = device["connected"].toBool()
					     ? QStringLiteral("connected now")
					     : relativeTime(qint64(device["last_used"].toDouble()), now);
		auto *when = secondary(seen, row);
		when->setWordWrap(false);
		auto *remove = new QPushButton(QStringLiteral("Remove"), row);
		const QString id = device["id"].toString();
		const QString deviceName = device["name"].toString();
		connect(remove, &QPushButton::clicked, this, [this, id, deviceName] {
			if (QMessageBox::question(this, QStringLiteral("Remove Device"),
						  QStringLiteral("%1 loses remote access to this PC.").arg(deviceName)) ==
			    QMessageBox::Yes)
				send_(QJsonObject{{"cmd", "remove_device"}, {"id", id}});
		});
		layout->addWidget(name);
		layout->addWidget(when, 1);
		layout->addWidget(remove);
		/// Rows never shrink below their height: a hint appearing above
		/// must grow the panel, not squeeze the buttons together
		row->setSizePolicy(QSizePolicy::Preferred, QSizePolicy::Fixed);
		devicesList_->addWidget(row);
	}
}

void RemotePanel::applyPreview(int maxEdge, int jpegQuality)
{
	int index = -1;
	for (int i = 0; i < int(std::size(kPresets)); i++) {
		if (kPresets[i].maxEdge == maxEdge && kPresets[i].quality == jpegQuality)
			index = i;
	}
	/// Values set elsewhere (the other shell, an older version) that match
	/// no preset show as "Custom"
	const int customIndex = int(std::size(kPresets));
	if (index < 0) {
		if (preview_->count() == customIndex)
			preview_->addItem(QStringLiteral("Custom - %1 px").arg(maxEdge));
		else
			preview_->setItemText(customIndex, QStringLiteral("Custom - %1 px").arg(maxEdge));
		index = customIndex;
	} else if (preview_->count() > customIndex) {
		preview_->removeItem(customIndex);
	}
	preview_->setCurrentIndex(index);
}

} // namespace obb_ui
