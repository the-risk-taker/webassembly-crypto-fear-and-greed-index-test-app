#pragma once

#include <QObject>
#include <QQmlEngine>

class QSettings;

// Persists the login session expiry across page reloads: browser localStorage
// on WASM (QSettings has no writable backend there), QSettings natively.
class SessionStore : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(double expiresAt READ expiresAt WRITE setExpiresAt NOTIFY expiresAtChanged)

public:
    explicit SessionStore(QObject *parent = nullptr);

    double expiresAt() const;
    void setExpiresAt(double v);

signals:
    void expiresAtChanged();

private:
    double load() const;
    void save(double v);

    double m_expiresAt = 0;
#ifndef Q_OS_WASM
    QSettings *m_settings = nullptr;
#endif
};
