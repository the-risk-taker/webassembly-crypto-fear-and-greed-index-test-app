#include "SessionStore.h"

#include <QSettings>

#ifdef Q_OS_WASM
#include <emscripten.h>

EM_JS(void, js_set_session_expiry, (double value), {
    localStorage.setItem("session_expiresAt", value);
});

EM_JS(double, js_get_session_expiry, (), {
    var v = localStorage.getItem("session_expiresAt");
    return v === null ? 0 : parseFloat(v);
});
#endif

SessionStore::SessionStore(QObject *parent)
    : QObject(parent)
#ifndef Q_OS_WASM
    , m_settings(new QSettings(this))
#endif
{
    m_expiresAt = load();
}

double SessionStore::expiresAt() const
{
    return m_expiresAt;
}

void SessionStore::setExpiresAt(double v)
{
    if (m_expiresAt == v)
        return;
    m_expiresAt = v;
    save(v);
    emit expiresAtChanged();
}

double SessionStore::load() const
{
#ifdef Q_OS_WASM
    return js_get_session_expiry();
#else
    return m_settings->value("session/expiresAt", 0).toDouble();
#endif
}

void SessionStore::save(double v)
{
#ifdef Q_OS_WASM
    js_set_session_expiry(v);
#else
    m_settings->setValue("session/expiresAt", v);
#endif
}
