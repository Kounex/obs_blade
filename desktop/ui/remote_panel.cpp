#include "remote_panel.hpp"

#include <QApplication>
#include <QCheckBox>
#include <QComboBox>
#include <QDateTime>
#include <QEvent>
#include <QGridLayout>
#include <QIntValidator>
#include <QHBoxLayout>
#include <QJsonArray>
#include <QLabel>
#include <QLineEdit>
#include <QLocale>
#include <QMessageBox>
#include <QPushButton>
#include <QToolButton>
#include <QVariantAnimation>
#include <QVBoxLayout>

namespace obb_ui {

namespace {

/// Preview presets for relay sessions: longest edge + JPEG quality (the
/// core rewrites the app's preview screenshots to these)
struct Preset {
	const char16_t *name;
	int maxEdge;
	int quality;

	QString label() const
	{
		return QStringLiteral("%1 \u2013 %2 px").arg(QString::fromUtf16(name)).arg(maxEdge);
	}
};

constexpr Preset kPresets[] = {
	{u"Data saver", 480, 50},
	{u"Balanced", 640, 60},
	{u"Sharp", 960, 70},
};

/// Marks the labels RemotePanel::updateSecondaryColor dims
constexpr const char *kSecondary = "obbSecondary";

QLabel *secondary(const QString &text, QWidget *parent)
{
	auto *label = new QLabel(text, parent);
	label->setWordWrap(true);
	label->setProperty(kSecondary, true);
	return label;
}

QLabel *heading(const QString &text, QWidget *parent)
{
	auto *label = new QLabel(text, parent);
	QFont font = label->font();
	font.setBold(true);
	label->setFont(font);
	return label;
}

QString dot(const char *color)
{
	return QStringLiteral("<span style=\"color:%1; font-size:14pt;\">&#9679;</span>").arg(color);
}

} // namespace

namespace {

class ContentFitter : public QObject {
public:
	ContentFitter(QWidget *window, int width) : QObject(window), window_(window)
	{
		window->setFixedWidth(width);
	}

protected:
	bool eventFilter(QObject *watched, QEvent *event) override
	{
		if (watched == window_ && (event->type() == QEvent::Resize || event->type() == QEvent::LayoutRequest ||
					   event->type() == QEvent::Show))
			fit();
		return false;
	}

private:
	void fit()
	{
		if (fitting_)
			return;
		fitting_ = true;
		int needed = window_->heightForWidth(window_->width());
		if (needed < 0)
			needed = window_->sizeHint().height();
		/// Exactly the content: no empty room after a section closes, and
		/// an animating section (Collapsible) moves the bottom edge with it
		if (window_->minimumHeight() != needed || window_->maximumHeight() != needed)
			window_->setFixedHeight(needed);
		fitting_ = false;
	}

	QWidget *window_;
	bool fitting_ = false;
};

} // namespace

void fitWindowToContent(QWidget *window, int width)
{
	window->installEventFilter(new ContentFitter(window, width));
}

Collapsible::Collapsible(QWidget *parent) : QWidget(parent), animation_(new QVariantAnimation(this))
{
	QSizePolicy policy(QSizePolicy::Preferred, QSizePolicy::Fixed);
	policy.setHeightForWidth(true);
	setSizePolicy(policy);
	animation_->setDuration(220);
	animation_->setEasingCurve(QEasingCurve::OutCubic);
	connect(animation_, &QVariantAnimation::valueChanged, this, [this](const QVariant &value) {
		progress_ = value.toReal();
		updateGeometry();
	});
	connect(animation_, &QVariantAnimation::finished, this, [this] {
		if (progress_ <= 0.0 && content_)
			content_->hide();
	});
}

void Collapsible::setContent(QWidget *content)
{
	content_ = content;
	content_->hide();
}

void Collapsible::setExpanded(bool open)
{
	if (!content_)
		return;
	if (open) {
		content_->show();
		layoutContent();
	}
	animation_->stop();
	animation_->setStartValue(progress_);
	animation_->setEndValue(open ? 1.0 : 0.0);
	animation_->start();
}

int Collapsible::heightForWidth(int width) const
{
	return qRound(progress_ * contentHeight(width));
}

QSize Collapsible::sizeHint() const
{
	const int width = content_ ? content_->sizeHint().width() : 0;
	return {width, heightForWidth(this->width() > 0 ? this->width() : width)};
}

void Collapsible::resizeEvent(QResizeEvent *event)
{
	layoutContent();
	QWidget::resizeEvent(event);
}

int Collapsible::contentHeight(int width) const
{
	if (!content_)
		return 0;
	const int height = content_->hasHeightForWidth() ? content_->heightForWidth(width) : -1;
	return height > 0 ? height : content_->sizeHint().height();
}

void Collapsible::layoutContent()
{
	/// Always the full content, clipped by this widget: revealed / covered
	/// from the bottom, never squeezed
	if (content_)
		content_->setGeometry(0, 0, width(), contentHeight(width()));
}

QString addedDate(qint64 unixSeconds, qint64 nowSeconds)
{
	/// English like the rest of the panel; the year only when it isn't this one
	const QLocale english(QLocale::English);
	const QDate date = QDateTime::fromSecsSinceEpoch(unixSeconds).date();
	const bool thisYear = date.year() == QDateTime::fromSecsSinceEpoch(nowSeconds).date().year();
	return english.toString(date, thisYear ? QStringLiteral("MMM d") : QStringLiteral("MMM d, yyyy"));
}

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
	auto *title = heading(QStringLiteral("OBS Blade Remote"), this);
	version_ = secondary(QString(), this);
	version_->setWordWrap(false);
	header->addWidget(title);
	header->addStretch();
	header->addWidget(version_);
	root->addLayout(header);
	root->addWidget(secondary(QStringLiteral("Control this OBS from the OBS Blade app anywhere \u2013 "
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

	/// Standalone while the plugin handles remote access: its settings and
	/// devices live in OBS - shown there instead of a copy here that the
	/// running plugin wouldn't follow
	openInObs_ = new QPushButton(QStringLiteral("Open in OBS"), this);
	connect(openInObs_, &QPushButton::clicked, this, [this] { send_(QJsonObject{{"cmd", "open_plugin_panel"}}); });
	auto *openRow = new QHBoxLayout();
	openRow->addWidget(openInObs_);
	openRow->addStretch();
	root->addLayout(openRow);

	devicesBox_ = new QWidget(this);
	auto *devicesLayout = new QVBoxLayout(devicesBox_);
	devicesLayout->setContentsMargins(0, 6, 0, 0);
	devicesLayout->setSpacing(6);
	devicesLayout->addWidget(heading(QStringLiteral("Paired devices"), devicesBox_));
	devicesList_ = new QVBoxLayout();
	devicesList_->setSpacing(4);
	devicesLayout->addLayout(devicesList_);
	root->addWidget(devicesBox_);

	/// Preview quality: a heading over a left-aligned picker (a QFormLayout
	/// right-aligns and indents its labels on macOS)
	previewSection_ = new QWidget(this);
	auto *previewBox = new QVBoxLayout(previewSection_);
	previewBox->setContentsMargins(0, 6, 0, 0);
	previewBox->setSpacing(6);
	previewBox->addWidget(heading(QStringLiteral("Preview quality"), this));
	preview_ = new QComboBox(this);
	for (const Preset &preset : kPresets)
		preview_->addItem(preset.label());
	preview_->setSizeAdjustPolicy(QComboBox::AdjustToContents);
	/// macOS: align the visible box, not its focus-ring margin, with the text
	preview_->setAttribute(Qt::WA_LayoutUsesWidgetRect);
	connect(preview_, &QComboBox::currentIndexChanged, this, [this](int index) {
		if (applying_ || index < 0 || index >= int(std::size(kPresets)))
			return;
		send_(QJsonObject{{"cmd", "set_preview"},
				  {"max_edge", kPresets[index].maxEdge},
				  {"jpeg_quality", kPresets[index].quality}});
	});
	auto *previewRow = new QHBoxLayout();
	previewRow->addWidget(preview_);
	previewRow->addStretch();
	previewBox->addLayout(previewRow);
	previewBox->addWidget(secondary(QStringLiteral("The scene previews on phones connected through the "
						      "relay. Smaller loads faster on mobile data."),
					this));
	root->addWidget(previewSection_);

	/// Advanced: OBS started with --websocket_port / --websocket_password
	/// (its config file doesn't know them), and unpairing. A plain text
	/// disclosure - a checkable QToolButton draws a box when open on macOS.
	advancedToggle_ = new QToolButton(this);
	auto *advancedToggle = advancedToggle_;
	advancedToggle->setCheckable(true);
	advancedToggle->setToolButtonStyle(Qt::ToolButtonTextOnly);
	advancedToggle->setCursor(Qt::PointingHandCursor);
	/// The headings' size, in the sheet: macOS gives tool buttons a smaller
	/// font, and a widget style sheet ignores setFont
	advancedToggle->setStyleSheet(QStringLiteral("QToolButton { border: none; background: transparent; padding: 0; "
						     "font-weight: bold; font-size: %1pt; }")
					      .arg(QApplication::font().pointSizeF()));
	const auto toggleText = [](bool open) {
		return open ? QStringLiteral("\u25BE  Advanced") : QStringLiteral("\u25B8  Advanced");
	};
	advancedToggle->setText(toggleText(false));
	/// Header and section in one box without spacing: a closed section
	/// adds nothing below the toggle (the root's spacing did)
	advancedHeader_ = new QWidget(this);
	auto *advancedBox = new QVBoxLayout(advancedHeader_);
	advancedBox->setContentsMargins(0, 6, 0, 0);
	advancedBox->setSpacing(0);
	auto *advancedRow = new QHBoxLayout();
	advancedRow->addWidget(advancedToggle);
	advancedRow->addStretch();
	advancedBox->addLayout(advancedRow);
	root->addWidget(advancedHeader_);

	advancedClip_ = new Collapsible(advancedHeader_);
	advanced_ = new QWidget(advancedClip_);
	auto *advancedLayout = new QVBoxLayout(advanced_);
	advancedLayout->setContentsMargins(0, 10, 0, 0);
	advancedLayout->setSpacing(8);
	/// Non-breaking hyphens: "--websocket_port" must not wrap at its dashes
	auto *advancedNote = secondary(QStringLiteral("Only needed when OBS's settings can't be read (OBS started with "
						      "&#8209;&#8209;websocket_port or &#8209;&#8209;websocket_password, "
						      "an unusual install). Leave empty to use the settings from OBS."),
				       advanced_);
	advancedNote->setTextFormat(Qt::RichText);
	advancedLayout->addWidget(advancedNote);

	auto *grid = new QGridLayout();
	grid->setHorizontalSpacing(12);
	grid->setVerticalSpacing(8);
	obsPort_ = new QLineEdit(advanced_);
	obsPort_->setValidator(new QIntValidator(1, 65535, obsPort_));
	obsPort_->setPlaceholderText(QStringLiteral("From OBS"));
	obsPort_->setFixedWidth(180);
	obsPassword_ = new QLineEdit(advanced_);
	obsPassword_->setEchoMode(QLineEdit::Password);
	obsPassword_->setPlaceholderText(QStringLiteral("From OBS"));
	obsPassword_->setFixedWidth(180);
	auto *apply = new QPushButton(QStringLiteral("Apply"), advanced_);
	connect(apply, &QPushButton::clicked, this, [this] {
		QJsonObject command{{"cmd", "set_obs_override"}};
		const int port = obsPort_->text().toInt();
		command["port"] = port > 0 ? QJsonValue(port) : QJsonValue();
		command["password"] = obsPassword_->text().isEmpty() ? QJsonValue() : QJsonValue(obsPassword_->text());
		send_(command);
	});
	grid->addWidget(new QLabel(QStringLiteral("WebSocket port"), advanced_), 0, 0);
	grid->addWidget(obsPort_, 0, 1, Qt::AlignLeft);
	grid->addWidget(new QLabel(QStringLiteral("WebSocket password"), advanced_), 1, 0);
	grid->addWidget(obsPassword_, 1, 1, Qt::AlignLeft);
	grid->addWidget(apply, 2, 1, Qt::AlignLeft);
	grid->setColumnStretch(2, 1);
	advancedLayout->addLayout(grid);

	unpair_ = new QPushButton(QStringLiteral("Unpair This PC"), advanced_);
	connect(unpair_, &QPushButton::clicked, this, [this] {
		if (QMessageBox::question(this, QStringLiteral("Unpair This PC"),
					  QStringLiteral("All paired devices lose remote access to this PC. "
							 "They can set it up again from the OBS Blade app.")) ==
		    QMessageBox::Yes)
			send_(QJsonObject{{"cmd", "unpair"}});
	});
	auto *unpairRow = new QHBoxLayout();
	unpairRow->setContentsMargins(0, 8, 0, 0);
	unpairRow->setSpacing(12);
	unpairRow->addWidget(unpair_);
	unpairRow->addWidget(secondary(QStringLiteral("All paired devices lose remote access."), advanced_), 1);
	advancedLayout->addLayout(unpairRow);

	advancedClip_->setContent(advanced_);
	connect(advancedToggle, &QToolButton::toggled, this, [this, advancedToggle, toggleText](bool open) {
		advancedClip_->setExpanded(open);
		advancedToggle->setText(toggleText(open));
	});
	advancedBox->addWidget(advancedClip_);
	root->addStretch();
	updateSecondaryColor();
}

void RemotePanel::changeEvent(QEvent *event)
{
	/// OBS theme switches and macOS light / dark change the palette
	if (event->type() == QEvent::PaletteChange || event->type() == QEvent::StyleChange)
		updateSecondaryColor();
	QWidget::changeEvent(event);
}

void RemotePanel::updateSecondaryColor()
{
	/// Secondary text: the text color at 60 %. palette(placeholder-text)
	/// renders as full white with the macOS dark palette; OBS themes set
	/// their text color through a stylesheet, which polishing copies into
	/// the palette read here.
	const QColor color = palette().color(QPalette::WindowText);
	const QString sheet = QStringLiteral("color: rgba(%1, %2, %3, 60%);")
				      .arg(color.red())
				      .arg(color.green())
				      .arg(color.blue());
	for (QLabel *label : findChildren<QLabel *>()) {
		if (label->property(kSecondary).toBool() && label->styleSheet() != sheet)
			label->setStyleSheet(sheet);
	}
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
			status = QStringLiteral("Online \u2013 phones can reach this OBS");
		} else if (obs == "closed") {
			color = "#ffc107";
			status = shell_ == Shell::Standalone ? QStringLiteral("Online \u2013 OBS isn't running")
							     : QStringLiteral("Online \u2013 OBS is closing");
		} else if (obs == "ws_off" || obs == "auth_failed") {
			color = "#ffc107";
			status = QStringLiteral("Online \u2013 but OBS doesn't let OBS Blade Remote in");
		} else {
			status = QStringLiteral("Online \u2013 checking OBS...");
		}
	} else if (relay == "connecting") {
		status = QStringLiteral("Connecting to the OBS Blade relay...");
	} else if (relay == "offline") {
		color = "#ff453a";
		status = QStringLiteral("Can't reach the OBS Blade relay \u2013 retrying");
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
	/// The standalone didn't find obs-websocket's settings (a portable or
	/// custom install it hasn't seen running): the default port without a
	/// password didn't work either
	const bool settingsMissing = state["obs_settings_found"].isBool() && !state["obs_settings_found"].toBool() &&
				     (obs == "ws_off" || obs == "auth_failed");
	if (settingsMissing) {
		hints << QStringLiteral("Couldn't find OBS's WebSocket settings \u2013 enter the port and password from "
					"OBS's <b>Tools &rarr; WebSocket Server Settings</b> under Advanced.");
		if (!advancedShownForHint_) {
			advancedShownForHint_ = true;
			advancedToggle_->setChecked(true);
		}
	} else if (obs == "ws_off")
		hints << QStringLiteral("OBS's WebSocket server is off \u2013 turn it on in OBS under "
					"<b>Tools &rarr; WebSocket Server Settings</b>.");
	else if (obs == "auth_failed")
		hints << QStringLiteral("OBS refused the WebSocket password. If OBS was started with "
					"&#8209;&#8209;websocket_password, enter it under Advanced.");
	else if (obs == "closed" && shell_ == Shell::Standalone && relay != "deferred")
		hints << QStringLiteral("Phones can start it from the OBS Blade app.");
	const bool deferred = relay == "deferred";
	if (deferred)
		hints = {QStringLiteral("Its settings and paired devices are in OBS under "
					"<b>Tools&nbsp;&rarr;&nbsp;OBS&nbsp;Blade&nbsp;Remote</b>.")};
	hint_->setText(hints.join(QStringLiteral("<br>")));
	hint_->setVisible(!hints.isEmpty());

	openInObs_->setVisible(deferred);
	enabled_->setVisible(!deferred);
	previewSection_->setVisible(!deferred);
	advancedHeader_->setVisible(!deferred);
	devicesBox_->setVisible(paired && !deferred);
	rebuildDevices(state["devices"].toArray());

	applyPreview(state["preview_max_edge"].toInt(640), state["preview_jpeg_quality"].toInt(60));

	if (!obsPort_->hasFocus())
		obsPort_->setText(state["obs_port"].isNull() ? QString() : QString::number(state["obs_port"].toInt()));
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
		updateSecondaryColor();
		return;
	}
	const qint64 now = QDateTime::currentSecsSinceEpoch();
	for (const QJsonValue value : devices) {
		const QJsonObject device = value.toObject();
		auto *row = new QWidget(devicesBox_);
		auto *layout = new QHBoxLayout(row);
		layout->setContentsMargins(0, 2, 0, 2);
		layout->setSpacing(12);
		/// Name over "connected now · added Nov 8": model names are long
		/// ("iPad Pro 11-Inch (M5)"), and two of the same model differ in
		/// when they were added
		auto *text = new QVBoxLayout();
		text->setSpacing(1);
		auto *name = new QLabel(device["name"].toString(), row);
		name->setWordWrap(true);
		QStringList details;
		details << (device["connected"].toBool() ? QStringLiteral("connected now")
							 : relativeTime(qint64(device["last_used"].toDouble()), now));
		const qint64 added = qint64(device["created_at"].toDouble());
		if (added > 0)
			details << QStringLiteral("added %1").arg(addedDate(added, now));
		auto *when = secondary(details.join(QStringLiteral(" \u00B7 ")), row);
		text->addWidget(name);
		text->addWidget(when);
		auto *remove = new QPushButton(QStringLiteral("Remove"), row);
		const QString id = device["id"].toString();
		const QString deviceName = device["name"].toString();
		connect(remove, &QPushButton::clicked, this, [this, id, deviceName] {
			if (QMessageBox::question(this, QStringLiteral("Remove Device"),
						  QStringLiteral("%1 loses remote access to this PC.").arg(deviceName)) ==
			    QMessageBox::Yes)
				send_(QJsonObject{{"cmd", "remove_device"}, {"id", id}});
		});
		layout->addLayout(text, 1);
		layout->addWidget(remove, 0, Qt::AlignVCenter);
		/// Rows never shrink below their height: a hint appearing above
		/// must grow the panel, not squeeze the buttons together
		row->setSizePolicy(QSizePolicy::Preferred, QSizePolicy::Fixed);
		devicesList_->addWidget(row);
	}
	updateSecondaryColor();
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
			preview_->addItem(QStringLiteral("Custom \u2013 %1 px").arg(maxEdge));
		else
			preview_->setItemText(customIndex, QStringLiteral("Custom \u2013 %1 px").arg(maxEdge));
		index = customIndex;
	} else if (preview_->count() > customIndex) {
		preview_->removeItem(customIndex);
	}
	preview_->setCurrentIndex(index);
}

} // namespace obb_ui
