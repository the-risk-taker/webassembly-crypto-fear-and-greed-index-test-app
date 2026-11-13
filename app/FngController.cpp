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
constexpr int kHistoryDays = 1095;
constexpr int kBinanceMaxLimit = 1000;
constexpr qint64 kDayMs = 86400000;
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

    fetchHistory();

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

void FngController::fetchHistory()
{
    if (m_pendingHistory > 0)
        return;

    m_fngByDay.clear();
    m_priceByDay.clear();

    // Binance returns at most 1000 klines per request, so the 3 years are split in two calls
    const qint64 olderEnd = QDateTime::currentMSecsSinceEpoch() - qint64(kBinanceMaxLimit) * kDayMs;
    const QString klines = QStringLiteral("https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1d&limit=%1");
    const QList<QPair<QUrl, bool>> requests = {
        { QUrl(QStringLiteral("https://api.alternative.me/fng/?limit=%1").arg(kHistoryDays)), false },
        { QUrl(klines.arg(kBinanceMaxLimit)), true },
        { QUrl(klines.arg(kHistoryDays - kBinanceMaxLimit) + QStringLiteral("&endTime=%1").arg(olderEnd)), true },
    };

    m_pendingHistory = requests.size();
    for (const auto &[url, isPrice] : requests) {
        QNetworkReply *reply = m_manager->get(QNetworkRequest(url));
        const auto onFinished = [this, reply, isPrice]() { historyReplyFinished(reply, isPrice); };
        connect(reply, &QNetworkReply::finished, this, onFinished);
    }
}

void FngController::historyReplyFinished(QNetworkReply *reply, bool isPrice)
{
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        setErrorMsg(QStringLiteral("History request failed: %1").arg(reply->errorString()));
    } else {
        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        if (isPrice) {
            // Kline row: [openTime ms, open, high, low, close, ...]
            for (const QJsonValue &row : doc.array()) {
                const QJsonArray kline = row.toArray();
                m_priceByDay.insert(qint64(kline.at(0).toDouble()) / kDayMs, kline.at(4).toString().toDouble());
            }
        } else {
            for (const QJsonValue &entry : doc.object().value("data").toArray()) {
                const QJsonObject obj = entry.toObject();
                m_fngByDay.insert(obj.value("timestamp").toString().toLongLong() / 86400, obj.value("value").toString().toInt());
            }
        }
    }

    if (--m_pendingHistory > 0)
        return;

    m_history.clear();
    for (auto it = m_fngByDay.cbegin(); it != m_fngByDay.cend(); ++it) {
        if (!m_priceByDay.contains(it.key()))
            continue;
        m_history.append(QVariantMap{
            { "t", double(it.key() * kDayMs) },
            { "fng", it.value() },
            { "price", m_priceByDay.value(it.key()) },
        });
    }

    // Today's daily kline close is the latest price, followed by closes 1, 3 and 7 days ago
    m_btcPrices.clear();
    if (!m_priceByDay.isEmpty()) {
        const qint64 today = m_priceByDay.lastKey();
        for (int daysAgo : { 0, 1, 3, 7 })
            m_btcPrices.append(m_priceByDay.value(today - daysAgo));
    }
    emit historyChanged();
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
