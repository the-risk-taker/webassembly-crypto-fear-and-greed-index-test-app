#pragma once

#include <QColor>
#include <QObject>
#include <QQmlEngine>

class QNetworkAccessManager;

// Fetches and holds the current Fear & Greed index reading from
// api.alternative.me. QML only binds to the properties and calls fetch().
class FngController : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int value READ value NOTIFY dataChanged)
    Q_PROPERTY(QString classification READ classification NOTIFY dataChanged)
    Q_PROPERTY(QString timestamp READ timestamp NOTIFY dataChanged)
    Q_PROPERTY(bool fetching READ fetching NOTIFY fetchingChanged)
    Q_PROPERTY(QString errorMsg READ errorMsg NOTIFY errorMsgChanged)

public:
    explicit FngController(QObject *parent = nullptr);

    int value() const { return m_value; }
    QString classification() const { return m_classification; }
    QString timestamp() const { return m_timestamp; }
    bool fetching() const { return m_fetching; }
    QString errorMsg() const { return m_errorMsg; }

    Q_INVOKABLE void fetch();

    Q_INVOKABLE static QColor indexColor(int val);
    Q_INVOKABLE static bool zoneActive(int val, int lo, int hi);

signals:
    void dataChanged();
    void fetchingChanged();
    void errorMsgChanged();

private:
    void setFetching(bool v);
    void setErrorMsg(const QString &msg);

    QNetworkAccessManager *m_manager;
    int m_value = -1;
    QString m_classification;
    QString m_timestamp;
    bool m_fetching = false;
    QString m_errorMsg;
};
