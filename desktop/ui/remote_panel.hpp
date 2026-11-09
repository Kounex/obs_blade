// OBS Blade Remote - the settings panel both shells show (plugin: Tools ->
// OBS Blade Remote, standalone: its tray window). Qt6 Widgets only.
//
// It renders the core's `state` event (desktop/core/src/shared.rs
// emit_state) and sends core commands (desktop/core/src/api.rs) through
// the shell's callback - it never talks to the core itself.
#pragma once

#include <QJsonObject>
#include <QWidget>

#include <functional>

class QCheckBox;
class QComboBox;
class QLabel;
class QLineEdit;
class QPushButton;
class QVBoxLayout;
class QWidget;

namespace obb_ui {

enum class Shell { Plugin, Standalone };

class RemotePanel : public QWidget {
	Q_OBJECT

public:
	using Send = std::function<void(const QJsonObject &command)>;

	RemotePanel(Send send, Shell shell, QWidget *parent = nullptr);

	/// Standalone only: the "Start at login" switch (the shell owns it)
	void setStartAtLogin(bool on, std::function<void(bool)> onChange);

public slots:
	/// A `state` event from the core (any thread -> call on the UI thread)
	void applyState(const QJsonObject &state);

protected:
	void changeEvent(QEvent *event) override;

private:
	void updateSecondaryColor();
	void rebuildDevices(const QJsonArray &devices);
	void applyPreview(int maxEdge, int jpegQuality);

	Send send_;
	Shell shell_;
	bool applying_ = false;

	QLabel *version_;
	QCheckBox *enabled_;
	QLabel *statusDot_;
	QLabel *status_;
	QLabel *hint_;
	QWidget *devicesBox_;
	QVBoxLayout *devicesList_;
	QComboBox *preview_;
	QCheckBox *startAtLogin_;
	QWidget *advanced_;
	QLineEdit *obsPort_;
	QLineEdit *obsPassword_;
	QPushButton *unpair_;
	std::function<void(bool)> onStartAtLogin_;
};

/// Keeps `window` at least as tall as its content needs at its current
/// width - wrapped text grows taller when the window narrows, and opening
/// Advanced or a new hint adds rows. Top-level windows don't follow
/// heightForWidth on their own (both shells' windows use it).
void fitWindowToContent(QWidget *window);

/// "2 min ago", "3 days ago" for a unix timestamp (exposed for tests)
QString relativeTime(qint64 unixSeconds, qint64 nowSeconds);

} // namespace obb_ui
