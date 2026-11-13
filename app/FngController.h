#pragma once

#include <QColor>
#include <QMap>
#include <QObject>
#include <QQmlEngine>
#include <QVariantList>

class QNetworkAccessManager;
class QNetworkReply;

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
    Q_PROPERTY(QVariantList history READ history NOTIFY historyChanged)
    Q_PROPERTY(QVariantList btcPrices READ btcPrices NOTIFY historyChanged)

public:
    explicit FngController(QObject *parent = nullptr);

    int value() const { return m_value; }
    QString classification() const { return m_classification; }
    QString timestamp() const { return m_timestamp; }
    bool fetching() const { return m_fetching; }
    QString errorMsg() const { return m_errorMsg; }
    QVariantList history() const { return m_history; }
    QVariantList btcPrices() const { return m_btcPrices; }

    Q_INVOKABLE void fetch();

    Q_INVOKABLE static QColor indexColor(int val);
    Q_INVOKABLE static bool zoneActive(int val, int lo, int hi);

signals:
    void dataChanged();
    void fetchingChanged();
    void errorMsgChanged();
    void historyChanged();

private:
    void setFetching(bool v);
    void setErrorMsg(const QString &msg);
    void fetchHistory();
    void historyReplyFinished(QNetworkReply *reply, bool isPrice);

    QNetworkAccessManager *m_manager;
    int m_value = -1;
    QString m_classification;
    QString m_timestamp;
    bool m_fetching = false;
    QString m_errorMsg;
    QVariantList m_history;
    QVariantList m_btcPrices;
    QMap<qint64, int> m_fngByDay;
    QMap<qint64, double> m_priceByDay;
    int m_pendingHistory = 0;
};
