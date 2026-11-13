import QtQuick
import QtQuick.Controls
import QtQuick.Shapes

// Fear & Greed index (left axis, 0-100) overlaid with BTC/USD price (right axis, log or linear scale).
// history: [{ t: msSinceEpoch, fng: int, price: real }] sorted by t ascending.
Rectangle {
    id: chart

    property var history: []
    property int rangeDays: 365
    property bool logScale: true
    readonly property var ranges: [["1M", 30], ["3M", 91], ["6M", 182], ["1Y", 365], ["3Y", 1095]]
    readonly property var zones: [[0, 24, "#ef4444"], [25, 44, "#f97316"], [45, 55, "#eab308"], [56, 75, "#84cc16"], [76, 100, "#22c55e"]]
    readonly property color fngColor: "#f59e0b"
    readonly property color priceColor: "#38bdf8"
    readonly property bool compact: width < 500

    readonly property var points: {
        if (history.length === 0)
            return []
        const from = history[history.length - 1].t - rangeDays * 86400000
        return history.filter(p => p.t >= from)
    }
    readonly property real scaleMin: scaled(Math.min(...points.map(p => p.price)))
    readonly property real scaleMax: scaled(Math.max(...points.map(p => p.price)))
    // Tap pins the tooltip, touch screens have no hover to keep it visible
    property int pinnedIndex: -1
    readonly property int hoverIndex: points.length === 0 ? -1
        : hover.hovered ? indexAt(hover.point.position.x)
        : tap.pressed ? indexAt(tap.point.position.x)
        : pinnedIndex

    onPointsChanged: pinnedIndex = -1

    color: "#0d1224"
    border.color: "#1e3a5f"
    border.width: 1
    radius: 4

    function indexAt(x) { return Math.max(0, Math.min(points.length - 1, Math.round(x / plot.width * (points.length - 1)))) }
    function xAt(i) { return plot.width * i / Math.max(1, points.length - 1) }
    function fngY(v) { return plot.height * (1 - v / 100) }
    function scaled(v) { return logScale ? Math.log(v) : v }
    function priceY(v) { return plot.height * (1 - (scaled(v) - scaleMin) / Math.max(1e-9, scaleMax - scaleMin)) }
    function priceAtFraction(f) {
        const v = scaleMin + f * (scaleMax - scaleMin)
        return logScale ? Math.exp(v) : v
    }
    function formatPrice(v) { return "$" + (v >= 1000 ? (v / 1000).toFixed(1) + "k" : v.toFixed(0)) }
    function formatDate(t) { return Qt.formatDate(new Date(t), rangeDays > 182 ? "MMM yy" : "dd MMM") }
    function zoneColor(v) { return zones.find(z => v <= z[1])[2] }

    Rectangle {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 2
        color: chart.fngColor
        radius: 2
    }

    Text {
        id: title
        anchors { top: parent.top; left: parent.left; margins: 20 }
        text: "HISTORY"
        color: "#64748b"
        font.pixelSize: 10
        font.letterSpacing: 1.5
    }

    Rectangle {
        id: infoButton
        anchors { left: title.right; leftMargin: 10; verticalCenter: title.verticalCenter }
        width: 18; height: 18; radius: 9
        color: infoArea.containsMouse || sourcesPopup.opened ? "#1e3a5f" : "transparent"
        border.color: infoArea.containsMouse || sourcesPopup.opened ? "#3b82f6" : "#475569"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: "i"
            color: infoArea.containsMouse || sourcesPopup.opened ? "#3b82f6" : "#94a3b8"
            font.pixelSize: 11
            font.bold: true
            font.family: "serif"
        }

        MouseArea {
            id: infoArea
            anchors.fill: parent
            anchors.margins: -8
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: sourcesPopup.open()
        }
    }

    Popup {
        id: sourcesPopup
        x: 20
        y: infoButton.y + infoButton.height + 10
        width: Math.min(420, chart.width - 40)
        padding: 20
        modal: true
        dim: false

        background: Rectangle {
            color: "#0b1020"
            border.color: "#1e3a5f"
            radius: 4

            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 2
                color: "#3b82f6"
                radius: 2
            }
        }

        contentItem: Column {
            spacing: 16

            Text {
                text: "DATA SOURCES"
                color: "#64748b"
                font.pixelSize: 10
                font.letterSpacing: 1.5
            }

            Repeater {
                model: [
                    { name: "FEAR & GREED INDEX", color: chart.fngColor, url: "https://alternative.me/crypto/fear-and-greed-index/",
                      host: "alternative.me", details: "Daily value 0-100, updated once a day at 00:00 UTC." },
                    { name: "BTC/USD PRICE", color: chart.priceColor, url: "https://www.binance.com/en/trade/BTC_USDT",
                      host: "binance.com", details: "Daily close of BTC/USDT spot pair, 00:00 UTC candles." }
                ]
                delegate: Row {
                    required property var modelData
                    width: sourcesPopup.availableWidth
                    spacing: 10

                    Rectangle { width: 3; height: sourceText.height; radius: 1; color: modelData.color }

                    Column {
                        id: sourceText
                        width: parent.width - 13
                        spacing: 4

                        Text { text: modelData.name; color: modelData.color; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1 }
                        Text {
                            text: "<a href=\"" + modelData.url + "\">" + modelData.host + " ↗</a>"
                            textFormat: Text.StyledText
                            linkColor: "#3b82f6"
                            font.pixelSize: 12
                            onLinkActivated: link => Qt.openUrlExternally(link)

                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                        }
                        Text { width: parent.width; text: modelData.details; color: "#94a3b8"; font.pixelSize: 12; wrapMode: Text.Wrap }
                    }
                }
            }

            Text {
                width: sourcesPopup.availableWidth
                text: "Both series are joined by UTC day. Price axis can be switched between log and linear scale. Not financial advice."
                color: "#64748b"
                font.pixelSize: 10
                wrapMode: Text.Wrap
            }
        }
    }

    Row {
        anchors { top: parent.top; right: parent.right; topMargin: 14; rightMargin: 20 }
        spacing: 4

        // Price scale toggle, icon shows the curve of the current scale
        Rectangle {
            width: chart.compact ? 30 : 36; height: 24
            radius: 2
            color: scaleArea.containsMouse ? "#111a30" : "transparent"
            border.color: "#334155"
            border.width: 1

            Shape {
                anchors.centerIn: parent
                width: 16; height: 12
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeColor: chart.priceColor; strokeWidth: 1.5; fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    startX: 0; startY: 12
                    PathQuad { x: 16; y: 0; controlX: chart.logScale ? 2 : 8; controlY: chart.logScale ? 1 : 6 }
                }
            }

            MouseArea {
                id: scaleArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: chart.logScale = !chart.logScale
            }
        }

        Item { width: 4; height: 1 }

        Repeater {
            model: chart.ranges
            delegate: Rectangle {
                required property var modelData
                readonly property bool active: chart.rangeDays === modelData[1]
                width: chart.compact ? 30 : 36; height: 24
                radius: 2
                color: active ? "#1e3a5f" : (rangeArea.containsMouse ? "#111a30" : "transparent")
                border.color: active ? chart.fngColor : "#334155"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: modelData[0]
                    color: active ? chart.fngColor : "#94a3b8"
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1
                }

                MouseArea {
                    id: rangeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: chart.rangeDays = modelData[1]
                }
            }
        }
    }

    Row {
        id: legend
        anchors { top: title.bottom; left: parent.left; topMargin: 14; leftMargin: 20 }
        spacing: 16

        Repeater {
            model: [["FEAR & GREED", chart.fngColor], ["BTC/USD (" + (chart.logScale ? "LOG SCALE" : "LINEAR") + ")", chart.priceColor]]
            delegate: Row {
                required property var modelData
                spacing: 6
                Rectangle { width: 12; height: 2; color: modelData[1]; anchors.verticalCenter: parent.verticalCenter }
                Text { text: modelData[0]; color: "#94a3b8"; font.pixelSize: 11; font.letterSpacing: 0.5 }
            }
        }
    }

    Text {
        anchors.centerIn: plot
        visible: chart.points.length === 0
        text: "LOADING HISTORY..."
        color: "#64748b"
        font.pixelSize: 11
        font.letterSpacing: 1
    }

    Item {
        id: plot
        anchors { top: legend.bottom; bottom: parent.bottom; left: parent.left; right: parent.right
                  topMargin: 16; bottomMargin: 34; leftMargin: 44; rightMargin: 64 }

        // Zone bands, same thresholds as FngController::indexColor
        Repeater {
            model: chart.zones
            delegate: Rectangle {
                required property var modelData
                y: chart.fngY(modelData[1])
                width: plot.width
                height: chart.fngY(modelData[0]) - y
                color: modelData[2]
                opacity: 0.06
            }
        }

        Repeater {
            model: 5
            delegate: Item {
                required property int index
                readonly property real fraction: index / 4
                y: plot.height * (1 - fraction)
                width: plot.width

                Rectangle { width: parent.width; height: 1; color: "#1e2d50" }
                Text {
                    anchors { right: parent.left; rightMargin: 8; verticalCenter: parent.top }
                    text: Math.round(fraction * 100)
                    color: chart.fngColor; font.pixelSize: 11
                }
                Text {
                    anchors { left: parent.right; leftMargin: 8; verticalCenter: parent.top }
                    text: chart.points.length ? chart.formatPrice(chart.priceAtFraction(fraction)) : ""
                    color: chart.priceColor; font.pixelSize: 11
                }
            }
        }

        Repeater {
            model: chart.compact ? 3 : 5
            delegate: Text {
                required property int index
                readonly property int i: Math.round((chart.points.length - 1) * index / (chart.compact ? 2 : 4))
                x: Math.max(-20, Math.min(plot.width - width + 20, chart.xAt(i) - width / 2))
                y: plot.height + 10
                text: chart.points.length ? chart.formatDate(chart.points[i].t) : ""
                color: "#64748b"; font.pixelSize: 11
            }
        }

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: chart.priceColor; strokeWidth: 1.5; fillColor: "transparent"
                PathPolyline { path: chart.points.map((p, i) => Qt.point(chart.xAt(i), chart.priceY(p.price))) }
            }
            ShapePath {
                strokeColor: chart.fngColor; strokeWidth: 1.5; fillColor: "transparent"
                PathPolyline { path: chart.points.map((p, i) => Qt.point(chart.xAt(i), chart.fngY(p.fng))) }
            }
        }

        // HoverHandler ignores touch, so on phones only the tap decides what is shown
        HoverHandler {
            id: hover
        }

        TapHandler {
            id: tap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: eventPoint => chart.pinnedIndex = chart.indexAt(eventPoint.position.x)
        }

        Item {
            visible: chart.hoverIndex >= 0
            anchors.fill: parent

            readonly property var point: chart.hoverIndex >= 0 ? chart.points[chart.hoverIndex] : ({ t: 0, fng: 0, price: 1 })
            readonly property real px: chart.xAt(chart.hoverIndex)

            Rectangle { x: parent.px; width: 1; height: plot.height; color: "#475569" }

            Repeater {
                model: [[chart.fngY(parent.point.fng), chart.fngColor], [chart.priceY(parent.point.price), chart.priceColor]]
                delegate: Rectangle {
                    required property var modelData
                    x: parent.px - 4; y: modelData[0] - 4
                    width: 8; height: 8; radius: 4
                    color: modelData[1]
                    border.color: "#0d1224"; border.width: 2
                }
            }

            Rectangle {
                id: tip
                x: parent.px + 12 + width > plot.width ? parent.px - 12 - width : parent.px + 12
                y: 8
                width: tipColumn.width + 24
                height: tipColumn.height + 20
                radius: 4
                color: "#0b1020"
                border.color: "#1e3a5f"

                Column {
                    id: tipColumn
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: Qt.formatDate(new Date(tip.parent.point.t), "dd MMM yyyy")
                        color: "#64748b"; font.pixelSize: 10; font.letterSpacing: 1
                    }
                    Row {
                        spacing: 8
                        Text { text: "F&G"; color: "#94a3b8"; font.pixelSize: 12; width: 36 }
                        Text { text: tip.parent.point.fng; color: chart.zoneColor(tip.parent.point.fng); font.pixelSize: 12; font.bold: true }
                    }
                    Row {
                        spacing: 8
                        Text { text: "BTC"; color: "#94a3b8"; font.pixelSize: 12; width: 36 }
                        Text {
                            text: "$" + Math.round(tip.parent.point.price).toLocaleString(Qt.locale("en_US"), "f", 0)
                            color: chart.priceColor; font.pixelSize: 12; font.bold: true
                        }
                    }
                }
            }
        }
    }
}
