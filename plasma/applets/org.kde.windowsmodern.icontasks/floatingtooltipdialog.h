/*
    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#ifndef FLOATINGTOOLTIPDIALOG_H
#define FLOATINGTOOLTIPDIALOG_H

#include <PlasmaQuick/PopupPlasmaWindow>

#include <QPointer>
#include <QQuickWindow>
#include <QTimer>
#include <QVariant>

class QQmlEngine;
class QQuickItem;

class FloatingToolTipDialog : public PlasmaQuick::PopupPlasmaWindow
{
    Q_OBJECT

public:
    explicit FloatingToolTipDialog();
    ~FloatingToolTipDialog() override;

    // Returns the stock DefaultToolTip item, creating it on first use in the
    // given engine (the engine of the applet that requested the tooltip).
    QQuickItem *loadDefaultItem(QQmlEngine *engine);

    void dismiss();
    void keepalive();

    bool interactive();
    void setInteractive(bool interactive);

    int hideTimeout() const;
    void setHideTimeout(int timeout);

    QObject *owner() const;
    void setOwner(QObject *owner);

protected:
    void showEvent(QShowEvent *event) override;
    void hideEvent(QHideEvent *event) override;
    bool event(QEvent *e) override;

private Q_SLOTS:
    void valueChanged(const QVariant &value);

private:
    void updateSize();

    QPointer<QQuickItem> m_lastMainItem;
    QPointer<QQuickItem> m_defaultItem;
    QTimer m_hideTimer;
    int m_hideTimeout;
    bool m_interactive;
    QObject *m_owner;
};

#endif
