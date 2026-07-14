/*
    SPDX-FileCopyrightText: 2011 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2011 Artur Duque de Souza <asouza@kde.org>
    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2023 David Edmundson <davidedmundson@kde.org>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "floatingtooltiparea.h"
#include "floatingtooltipdialog.h"

#include <PlasmaQuick/AppletQuickItem>

#include <QDebug>
#include <QQmlEngine>
#include <QStandardPaths>

#include <KSharedConfig>
#include <KWindowEffects>
#include <Plasma/Applet>

using namespace Qt::Literals;

FloatingToolTipDialog *FloatingToolTipArea::s_dialog = nullptr;
int FloatingToolTipArea::s_dialogUsers = 0;

FloatingToolTipArea::FloatingToolTipArea(QQuickItem *parent)
    : QQuickItem(parent)
    , m_tooltipsEnabledGlobally(false)
    , m_containsMouse(false)
    , m_location(Plasma::Types::Floating)
    , m_textFormat(Qt::AutoText)
    , m_active(true)
    , m_interactive(false)
    , m_timeout(-1)
    , m_margin(0)
    , m_usingDialog(false)
{
    setAcceptHoverEvents(true);
    setFiltersChildMouseEvents(true);

    m_showTimer.setSingleShot(true);
    connect(&m_showTimer, &QTimer::timeout, this, &FloatingToolTipArea::showToolTip);

    m_plasmarcWatcher = KConfigWatcher::create(KSharedConfig::openConfig(u"plasmarc"_s));
    connect(m_plasmarcWatcher.get(), &KConfigWatcher::configChanged, this, &FloatingToolTipArea::settingsChanged);
    loadSettings(m_plasmarcWatcher->config()->group(u"PlasmaToolTips"_s));
}

FloatingToolTipArea::~FloatingToolTipArea()
{
    if (s_dialog && s_dialog->owner() == this) {
        s_dialog->setVisible(false);
    }

    if (m_usingDialog) {
        --s_dialogUsers;
    }

    if (s_dialogUsers == 0) {
        delete s_dialog;
        s_dialog = nullptr;
    }
}

void FloatingToolTipArea::settingsChanged(const KConfigGroup &group, const QByteArrayList &)
{
    if (group.name() == u"PlasmaToolTips") {
        loadSettings(group);
    }
}

void FloatingToolTipArea::loadSettings(const KConfigGroup &cfg)
{
    m_interval = cfg.readEntry("Delay", 700);
    m_tooltipsEnabledGlobally = (m_interval > 0);
}

QQuickItem *FloatingToolTipArea::mainItem() const
{
    return m_mainItem.data();
}

FloatingToolTipDialog *FloatingToolTipArea::tooltipDialogInstance()
{
    if (!s_dialog) {
        s_dialog = new FloatingToolTipDialog;
    }

    if (!m_usingDialog) {
        s_dialogUsers++;
        m_usingDialog = true;
    }

    return s_dialog;
}

void FloatingToolTipArea::setMainItem(QQuickItem *mainItem)
{
    if (m_mainItem.data() != mainItem) {
        m_mainItem = mainItem;
        Q_EMIT mainItemChanged();

        if (!isValid() && s_dialog && s_dialog->owner() == this) {
            s_dialog->setVisible(false);
        }
    }
}

void FloatingToolTipArea::showToolTip()
{
    if (!m_active) {
        return;
    }

    Q_EMIT aboutToShow();

    FloatingToolTipDialog *dlg = tooltipDialogInstance();

    if (!mainItem()) {
        setMainItem(dlg->loadDefaultItem());
    }

    dlg->setMainItem(nullptr);

    Plasma::Types::Location location = m_location;
    if (m_location == Plasma::Types::Floating) {
        QQuickItem *p = parentItem();
        while (p) {
            PlasmaQuick::AppletQuickItem *appletItem = qobject_cast<PlasmaQuick::AppletQuickItem *>(p);
            if (appletItem) {
                location = appletItem->applet()->location();
                break;
            }
            p = p->parentItem();
        }
    }

    if (mainItem()) {
        mainItem()->setProperty("toolTip", QVariant::fromValue(this));
        mainItem()->setVisible(true);
    }

    connect(dlg, &FloatingToolTipDialog::visibleChanged, this, &FloatingToolTipArea::toolTipVisibleChanged, Qt::UniqueConnection);

    dlg->setHideTimeout(m_timeout);
    dlg->setOwner(this);
    dlg->setVisualParent(this);
    dlg->setMainItem(mainItem());
    dlg->setInteractive(m_interactive);
    dlg->setMargin(m_margin);

    switch (location) {
    case Plasma::Types::Floating:
    case Plasma::Types::Desktop:
    case Plasma::Types::FullScreen:
        dlg->setFloating(true);
        dlg->setPopupDirection(Qt::BottomEdge);
        break;
    case Plasma::Types::TopEdge:
        dlg->setFloating(false);
        dlg->setPopupDirection(Qt::BottomEdge);
        break;
    case Plasma::Types::BottomEdge:
        dlg->setFloating(false);
        dlg->setPopupDirection(Qt::TopEdge);
        break;
    case Plasma::Types::LeftEdge:
        dlg->setFloating(false);
        dlg->setPopupDirection(Qt::RightEdge);
        break;
    case Plasma::Types::RightEdge:
        dlg->setFloating(false);
        dlg->setPopupDirection(Qt::LeftEdge);
        break;
    }

    dlg->setVisible(true);
    dlg->keepalive();
}

QString FloatingToolTipArea::mainText() const
{
    return m_mainText;
}

void FloatingToolTipArea::setMainText(const QString &mainText)
{
    if (mainText == m_mainText) {
        return;
    }
    m_mainText = mainText;
    Q_EMIT mainTextChanged();

    if (!isValid() && s_dialog && s_dialog->owner() == this) {
        s_dialog->setVisible(false);
    }
}

QString FloatingToolTipArea::subText() const
{
    return m_subText;
}

void FloatingToolTipArea::setSubText(const QString &subText)
{
    if (subText == m_subText) {
        return;
    }
    m_subText = subText;
    Q_EMIT subTextChanged();

    if (!isValid() && s_dialog && s_dialog->owner() == this) {
        s_dialog->setVisible(false);
    }
}

int FloatingToolTipArea::textFormat() const
{
    return m_textFormat;
}

void FloatingToolTipArea::setTextFormat(int format)
{
    if (m_textFormat == format) {
        return;
    }
    m_textFormat = format;
    Q_EMIT textFormatChanged();
}

Plasma::Types::Location FloatingToolTipArea::location() const
{
    return m_location;
}

void FloatingToolTipArea::setLocation(Plasma::Types::Location location)
{
    if (m_location == location) {
        return;
    }
    m_location = location;
    Q_EMIT locationChanged();
}

void FloatingToolTipArea::setActive(bool active)
{
    if (m_active == active) {
        return;
    }
    m_active = active;
    if (!active) {
        tooltipDialogInstance()->dismiss();
    }
    Q_EMIT activeChanged();
}

void FloatingToolTipArea::setInteractive(bool interactive)
{
    if (m_interactive == interactive) {
        return;
    }
    m_interactive = interactive;
    Q_EMIT interactiveChanged();
}

void FloatingToolTipArea::setTimeout(int timeout)
{
    m_timeout = timeout;
}

int FloatingToolTipArea::margin() const
{
    return m_margin;
}

void FloatingToolTipArea::setMargin(int margin)
{
    if (m_margin == margin) {
        return;
    }
    m_margin = margin;
    Q_EMIT marginChanged();
}

void FloatingToolTipArea::hideToolTip()
{
    m_showTimer.stop();
    tooltipDialogInstance()->dismiss();
}

void FloatingToolTipArea::hideImmediately()
{
    m_showTimer.stop();
    tooltipDialogInstance()->setVisible(false);
}

QVariant FloatingToolTipArea::icon() const
{
    if (m_icon.isValid()) {
        return m_icon;
    }
    return QString();
}

void FloatingToolTipArea::setIcon(const QVariant &icon)
{
    if (icon == m_icon) {
        return;
    }
    m_icon = icon;
    Q_EMIT iconChanged();
}

QVariant FloatingToolTipArea::image() const
{
    if (m_image.isValid()) {
        return m_image;
    }
    return QString();
}

void FloatingToolTipArea::setImage(const QVariant &image)
{
    if (image == m_image) {
        return;
    }
    m_image = image;
    Q_EMIT imageChanged();
}

bool FloatingToolTipArea::containsMouse() const
{
    return m_containsMouse;
}

void FloatingToolTipArea::setContainsMouse(bool contains)
{
    if (m_containsMouse != contains) {
        m_containsMouse = contains;
        Q_EMIT containsMouseChanged();
    }
    if (!contains && tooltipDialogInstance()->owner() == this) {
        tooltipDialogInstance()->dismiss();
    }
}

void FloatingToolTipArea::hoverEnterEvent(QHoverEvent *event)
{
    Q_UNUSED(event)
    setContainsMouse(true);

    if (!m_tooltipsEnabledGlobally) {
        return;
    }

    if (!isValid()) {
        return;
    }

    if (tooltipDialogInstance()->isVisible()) {
        if (m_active) {
            tooltipDialogInstance()->keepalive();
            showToolTip();
        }
    } else {
        m_showTimer.start(m_interval);
    }
}

void FloatingToolTipArea::hoverLeaveEvent(QHoverEvent *event)
{
    Q_UNUSED(event)
    setContainsMouse(false);
    m_showTimer.stop();
}

bool FloatingToolTipArea::childMouseEventFilter(QQuickItem *item, QEvent *event)
{
    if (event->type() == QEvent::MouseButtonPress) {
        hideToolTip();
    }
    return QQuickItem::childMouseEventFilter(item, event);
}

bool FloatingToolTipArea::isValid() const
{
    return m_mainItem || !mainText().isEmpty() || !subText().isEmpty();
}
