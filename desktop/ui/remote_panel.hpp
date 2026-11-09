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
class QToolButton;
class QLineEdit;
class QPushButton;
class QVariantAnimation;
class QVBoxLayout;
class QWidget;

namespace obb_ui {

enum class Shell { Plugin, Standalone };

/// A section that opens / closes by animating its height: the content
/// keeps its full height and is clipped (revealed from the bottom, never
/// squeezed), and the window follows frame by frame (fitWindowToContent)
class Collapsible : public QWidget {
public:
	explicit Collapsible(QWidget *parent);
	void setContent(QWidget *content);
	void setExpanded(bool open);

	bool hasHeightForWidth() const override { return true; }
	int heightForWidth(int width) const override;
	QSize sizeHint() const override;
	QSize minimumSizeHint() const override { return {0, 0}; }

protected:
	void resizeEvent(QResizeEvent *event) override;

private:
	int contentHeight(int width) const;
	void layoutContent();

	QWidget *content_ = nullptr;
	QVariantAnimation *animation_;
	qreal progress_ = 0.0;
};

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
	Collapsible *advancedClip_;
	QToolButton *advancedToggle_;
	/// Advanced opened by itself once, for the "settings not found" hint
	bool advancedShownForHint_ = false;
	QWidget *advancedHeader_;
	QWidget *previewSection_;
	QPushButton *openInObs_;
	QLineEdit *obsPort_;
	QLineEdit *obsPassword_;
	QPushButton *unpair_;
	std::function<void(bool)> onStartAtLogin_;
};

/// Sizes `window` to its content: a fixed width, and exactly the height
/// the content needs at it - updated on every layout change, so an
/// animating Collapsible moves the window's bottom edge with it and a
/// closed section leaves no empty room. Top-level windows don't follow
/// heightForWidth on their own (both shells' windows use it).
void fitWindowToContent(QWidget *window, int width = 440);

/// "2 min ago", "3 days ago" for a unix timestamp (exposed for tests)
QString relativeTime(qint64 unixSeconds, qint64 nowSeconds);

/// "Nov 8", or "Nov 8, 2025" from another year (exposed for tests)
QString addedDate(qint64 unixSeconds, qint64 nowSeconds);

} // namespace obb_ui
