/*
    SPDX-FileCopyrightText: 2011 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2011 Artur Duque de Souza <asouza@kde.org>
    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#ifndef FLOATINGTOOLTIPAREA_H
#define FLOATINGTOOLTIPAREA_H

#include <Plasma/Plasma>

#include <QPointer>
#include <QQuickItem>
#include <QTimer>
#include <QVariant>

#include <KConfigWatcher>

class QQuickItem;
class FloatingToolTipDialog;

class FloatingToolTipArea : public QQuickItem
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QQuickItem *mainItem READ mainItem WRITE setMainItem NOTIFY mainItemChanged)
    Q_PROPERTY(QString mainText READ mainText WRITE setMainText NOTIFY mainTextChanged)
    Q_PROPERTY(QString subText READ subText WRITE setSubText NOTIFY subTextChanged)
    Q_PROPERTY(int textFormat READ textFormat WRITE setTextFormat NOTIFY textFormatChanged)
    Q_PROPERTY(QVariant icon READ icon WRITE setIcon NOTIFY iconChanged)
    Q_PROPERTY(bool containsMouse READ containsMouse NOTIFY containsMouseChanged)
    Q_PROPERTY(Plasma::Types::Location location READ location WRITE setLocation NOTIFY locationChanged)
    Q_PROPERTY(QVariant image READ image WRITE setImage NOTIFY imageChanged)
    Q_PROPERTY(bool active MEMBER m_active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(bool interactive MEMBER m_interactive WRITE setInteractive NOTIFY interactiveChanged)
    Q_PROPERTY(int timeout MEMBER m_timeout WRITE setTimeout)

    Q_PROPERTY(int margin READ margin WRITE setMargin NOTIFY marginChanged)

public:
    explicit FloatingToolTipArea(QQuickItem *parent = nullptr);
    ~FloatingToolTipArea() override;

    QQuickItem *mainItem() const;
    void setMainItem(QQuickItem *mainItem);

    QString mainText() const;
    void setMainText(const QString &mainText);

    QString subText() const;
    void setSubText(const QString &subText);

    int textFormat() const;
    void setTextFormat(int format);

    QVariant icon() const;
    void setIcon(const QVariant &icon);

    QVariant image() const;
    void setImage(const QVariant &image);

    Plasma::Types::Location location() const;
    void setLocation(Plasma::Types::Location location);

    bool containsMouse() const;
    void setContainsMouse(bool contains);

    void setActive(bool active);
    void setInteractive(bool interactive);
    void setTimeout(int timeout);

    int margin() const;
    void setMargin(int margin);

public Q_SLOTS:
    void showToolTip();
    void hideToolTip();
    void hideImmediately();

protected:
    bool childMouseEventFilter(QQuickItem *item, QEvent *event) override;
    void hoverEnterEvent(QHoverEvent *event) override;
    void hoverLeaveEvent(QHoverEvent *event) override;

    FloatingToolTipDialog *tooltipDialogInstance();

Q_SIGNALS:
    void mainItemChanged();
    void mainTextChanged();
    void subTextChanged();
    void textFormatChanged();
    void iconChanged();
    void imageChanged();
    void containsMouseChanged();
    void locationChanged();
    void activeChanged();
    void interactiveChanged();
    void marginChanged();
    void aboutToShow();
    void toolTipVisibleChanged(bool toolTipVisible);

private Q_SLOTS:
    void settingsChanged(const KConfigGroup &group, const QByteArrayList &names);

private:
    bool isValid() const;
    void loadSettings(const KConfigGroup &cfg);

    bool m_tooltipsEnabledGlobally;
    bool m_containsMouse;
    Plasma::Types::Location m_location;
    QPointer<QQuickItem> m_mainItem;
    QTimer m_showTimer;
    QString m_mainText;
    QString m_subText;
    int m_textFormat;
    QVariant m_image;
    QVariant m_icon;
    bool m_active;
    bool m_interactive;
    int m_interval;
    int m_timeout;
    int m_margin;

    bool m_usingDialog : 1;
    static FloatingToolTipDialog *s_dialog;
    static int s_dialogUsers;

    KConfigWatcher::Ptr m_plasmarcWatcher;
};

#endif
