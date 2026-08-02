#include "FngController.h"

#include <QDateTime>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QTimeZone>

namespace {
const QUrl kFngApiUrl("https://api.alternative.me/fng/?limit=1");
}

FngController::FngController(QObject *parent)
    : QObject(parent)
    , m_manager(new QNetworkAccessManager(this))
{
}

void FngController::fetch()
{
    if (m_fetching)
        return;

    setFetching(true);
    setErrorMsg(QString());

    QNetworkReply *reply = m_manager->get(QNetworkRequest(kFngApiUrl));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        setFetching(false);

        if (reply->error() != QNetworkReply::NoError) {
            setErrorMsg(QStringLiteral("HTTP request failed: %1").arg(reply->errorString()));
            return;
        }

        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        const QJsonArray data = doc.object().value("data").toArray();
        if (data.isEmpty()) {
            setErrorMsg(QStringLiteral("Parse error: unexpected response format"));
            return;
        }

        const QJsonObject entry = data.first().toObject();
        bool ok = false;
        const int parsed = entry.value("value").toString().toInt(&ok);
        if (!ok) {
            setErrorMsg(QStringLiteral("Parse error: unexpected value format"));
            return;
        }

        m_value = parsed;
        m_classification = entry.value("value_classification").toString();
        const qint64 ts = entry.value("timestamp").toString().toLongLong();
        m_timestamp = QDateTime::fromSecsSinceEpoch(ts, QTimeZone::UTC).toString("yyyy-MM-dd hh:mm");
        emit dataChanged();
    });
}

QColor FngController::indexColor(int val)
{
    if (val <= 24) return QColor("#ef4444");
    if (val <= 44) return QColor("#f97316");
    if (val <= 55) return QColor("#eab308");
    if (val <= 75) return QColor("#84cc16");
    return QColor("#22c55e");
}

bool FngController::zoneActive(int val, int lo, int hi)
{
    return val >= lo && val <= hi;
}

void FngController::setFetching(bool v)
{
    if (m_fetching == v)
        return;
    m_fetching = v;
    emit fetchingChanged();
}

void FngController::setErrorMsg(const QString &msg)
{
    if (m_errorMsg == msg)
        return;
    m_errorMsg = msg;
    emit errorMsgChanged();
}
