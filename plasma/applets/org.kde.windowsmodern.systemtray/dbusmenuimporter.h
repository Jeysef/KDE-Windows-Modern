#pragma once
#include <QObject>
#include <QMenu>

class DBusMenuImporter : public QObject {
    Q_OBJECT
public:
    DBusMenuImporter(const QString &, const QString &, QObject *parent = nullptr) : QObject(parent) {}
    virtual ~DBusMenuImporter() {}
    QMenu *menu() const { return nullptr; }
    void updateMenu() {}
Q_SIGNALS:
    void menuUpdated(QMenu *);
protected:
    virtual QIcon iconForName(const QString &) { return QIcon(); }
    virtual void actionActivated(int) {}
    void sendClickedEvent(int) {}
};
