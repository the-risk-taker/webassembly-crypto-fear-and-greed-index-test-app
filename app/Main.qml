import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import webassembly

Window {
    id: root
    width: 1024
    height: 640
    visible: true
    title: "CRYPTO FEAR & GREED"
    color: "#080c18"

    property string appState: "login"
    property string errorMsg: ""
    property bool isMobile: width < 700
    readonly property int sessionDurationMs: 15 * 60 * 1000

    FngController {
        id: fng
    }

    // WARNING: credentials are checked client-side and visible in the binary - this is UI-only gatekeeping, not real auth
    readonly property string validUser: "admin"
    readonly property string validPass: "cyber"

    // ── TOP BAR ───────────────────────────────────────────────────────────────
    Rectangle {
        id: topBar
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 40
        color: "#0d1224"
        border.color: "#1e2d50"
        border.width: 1

        Row {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 16 }
            spacing: 8

            Rectangle {
                width: 20; height: 20
                radius: 2
                color: "#f59e0b"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "⚡"
                    font.pixelSize: 11
                    color: "#000"
                }
            }

            Text {
                text: isMobile ? "F&G INDEX" : "CRYPTO FEAR & GREED INDEX"
                color: "#e2e8f0"
                font.pixelSize: isMobile ? 12 : 13
                font.bold: true
                font.letterSpacing: isMobile ? 1 : 2
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 16 }
            spacing: 12

            // Live indicator
            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter
                visible: appState === "dashboard"

                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: "#22c55e"
                    anchors.verticalCenter: parent.verticalCenter

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: true
                        NumberAnimation { to: 0.3; duration: 800 }
                        NumberAnimation { to: 1.0; duration: 800 }
                    }
                }

                Text {
                    text: "LIVE"
                    color: "#22c55e"
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle {
                visible: appState === "dashboard"
                width: 80; height: 22
                radius: 2
                color: refreshArea.pressed ? "#1d4ed8" : (refreshArea.containsMouse ? "#1e3a5f" : "transparent")
                border.color: "#3b82f6"
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "↻ REFRESH"
                    color: "#3b82f6"
                    font.pixelSize: 10
                    font.letterSpacing: 1
                }

                MouseArea {
                    id: refreshArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: fng.fetch()
                }
            }

            // Logout button
            Rectangle {
                visible: appState === "dashboard"
                width: 70; height: 22
                radius: 2
                color: logoutHover.containsMouse ? "#1e1e3a" : "transparent"
                border.color: "#334155"
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "LOGOUT"
                    color: "#94a3b8"
                    font.pixelSize: 10
                    font.letterSpacing: 1
                }

                MouseArea {
                    id: logoutHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: logout()
                }
            }
        }
    }

    // ── LOGIN SCREEN ──────────────────────────────────────────────────────────
    Item {
        anchors { top: topBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        visible: appState === "login"

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(380, root.width - 32)
            height: 300
            color: "#0d1224"
            border.color: "#1e3a5f"
            border.width: 1
            radius: 4

            // Blue top accent line
            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 2
                color: "#3b82f6"
                radius: 2
            }

            Column {
                anchors { fill: parent; margins: isMobile ? 20 : 28 }
                spacing: 0

                Text {
                    text: "AUTHENTICATION"
                    color: "#94a3b8"
                    font.pixelSize: 11
                    font.letterSpacing: 2
                    bottomPadding: 20
                }

                // Username
                Text {
                    text: "USERNAME"
                    color: "#475569"
                    font.pixelSize: 10
                    font.letterSpacing: 1
                    bottomPadding: 6
                }

                Rectangle {
                    width: parent.width
                    height: 34
                    color: "#060a14"
                    border.color: userField.activeFocus ? "#3b82f6" : "#1e2d50"
                    border.width: 1
                    radius: 2

                    TextInput {
                        id: userField
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#e2e8f0"
                        font.pixelSize: 13
                        selectionColor: "#3b82f644"
                        Keys.onReturnPressed: passField.forceActiveFocus()
                        Keys.onEnterPressed: passField.forceActiveFocus()
                        Keys.onTabPressed: passField.forceActiveFocus()
                    }
                }

                Item { width: 1; height: 14 }

                // Password
                Text {
                    text: "PASSWORD"
                    color: "#475569"
                    font.pixelSize: 10
                    font.letterSpacing: 1
                    bottomPadding: 6
                }

                Rectangle {
                    width: parent.width
                    height: 34
                    color: "#060a14"
                    border.color: passField.activeFocus ? "#3b82f6" : "#1e2d50"
                    border.width: 1
                    radius: 2

                    TextInput {
                        id: passField
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#e2e8f0"
                        font.pixelSize: 13
                        echoMode: TextInput.Password
                        selectionColor: "#3b82f644"
                        Keys.onReturnPressed: doLogin()
                        Keys.onEnterPressed: doLogin()
                        Keys.onTabPressed: userField.forceActiveFocus()
                    }
                }

                Item { width: 1; height: 8 }

                Text {
                    text: errorMsg
                    color: "#ef4444"
                    font.pixelSize: 11
                    height: 18
                    visible: errorMsg !== ""
                }

                Item { width: 1; height: 6 }

                // Login button
                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 2
                    color: loginArea.pressed ? "#1d4ed8" : (loginArea.containsMouse ? "#2563eb" : "#1e40af")
                    border.color: "#3b82f6"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "AUTHENTICATE"
                        color: "#fff"
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 2
                    }

                    MouseArea {
                        id: loginArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: doLogin()
                    }
                }
            }
        }
    }

    // ── DASHBOARD ─────────────────────────────────────────────────────────────
    Item {
        anchors { top: topBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        visible: appState === "dashboard"

        // Background grid pattern
        Canvas {
            anchors.fill: parent
            opacity: 0.03
            onPaint: {
                var ctx = getContext("2d")
                ctx.strokeStyle = "#4488ff"
                ctx.lineWidth = 1
                for (var x = 0; x < width; x += 40) {
                    ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke()
                }
                for (var y = 0; y < height; y += 40) {
                    ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke()
                }
            }
        }

        // Main content
        Flickable {
            id: dashboardView
            anchors { fill: parent; margins: isMobile ? 16 : 24 }
            contentWidth: width
            contentHeight: cardsFlow.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Flow {
                id: cardsFlow
                width: parent.width
                readonly property real cardWidth: isMobile ? width : (width - 3 * spacing) / 4
                spacing: 16

                // ── BTC PRICE CARD ───────────────────────────────────────────
                Rectangle {
                    id: btcCard
                    width: cardsFlow.cardWidth
                    height: 260
                    color: "#0d1224"
                    border.color: "#1e3a5f"
                    border.width: 1
                    radius: 4

                    readonly property var prices: fng.btcPrices
                    readonly property bool hasPrice: prices.length > 0

                    function usd(v) { return "$" + Number(v).toLocaleString(Qt.locale("en_US"), "f", 0) }

                    Rectangle {
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: 2
                        color: "#f59e0b"
                        radius: 2
                    }

                    Column {
                        anchors { fill: parent; margins: 20 }
                        spacing: 0

                        Text {
                            text: "BTC / USD"
                            color: "#64748b"
                            font.pixelSize: 10
                            font.letterSpacing: 1.5
                            bottomPadding: 24
                        }

                        Text {
                            width: parent.width
                            text: btcCard.hasPrice ? btcCard.usd(btcCard.prices[0]) : "--"
                            color: btcCard.hasPrice ? "#f59e0b" : "#1e3a5f"
                            font.pixelSize: 40
                            font.bold: true
                            fontSizeMode: Text.HorizontalFit
                            minimumPixelSize: 20
                            bottomPadding: 24
                        }

                        Repeater {
                            model: [
                                { label: "1D AGO", index: 1 },
                                { label: "3D AGO", index: 2 },
                                { label: "7D AGO", index: 3 }
                            ]

                            delegate: Item {
                                id: priceRow
                                width: parent.width
                                height: 26

                                readonly property real past: btcCard.hasPrice ? btcCard.prices[modelData.index] : 0
                                readonly property real change: past > 0 ? (btcCard.prices[0] - past) / past * 100 : 0

                                Text {
                                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                    text: modelData.label
                                    color: "#475569"
                                    font.pixelSize: 10
                                    font.letterSpacing: 1
                                }

                                Text {
                                    anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
                                    text: priceRow.past > 0 ? btcCard.usd(priceRow.past) : "--"
                                    color: "#94a3b8"
                                    font.pixelSize: 12
                                }

                                Text {
                                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                    text: priceRow.past > 0 ? (priceRow.change >= 0 ? "+" : "") + priceRow.change.toFixed(2) + "%" : ""
                                    color: priceRow.change >= 0 ? "#22c55e" : "#ef4444"
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }
                }

                // ── INDEX CARD ───────────────────────────────────────────────
                Rectangle {
                    id: indexCard
                    width: cardsFlow.cardWidth
                    height: 260
                    color: "#0d1224"
                    border.color: "#1e3a5f"
                    border.width: 1
                    radius: 4

                    Rectangle {
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: 2
                        color: fng.value >= 0 ? fng.indexColor(fng.value) : "#3b82f6"
                        radius: 2
                        Behavior on color { ColorAnimation { duration: 800 } }
                    }

                    Column {
                        anchors { fill: parent; margins: 20 }
                        spacing: 0

                        Row {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: "FEAR & GREED INDEX"
                                color: "#64748b"
                                font.pixelSize: 10
                                font.letterSpacing: 1.5
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Item { width: 1; height: 16 }

                        // Big number
                        Item {
                            width: parent.width
                            height: 90

                            Text {
                                anchors.centerIn: parent
                                text: fng.value >= 0 ? fng.value : "--"
                                color: fng.value >= 0 ? fng.indexColor(fng.value) : "#1e3a5f"
                                font.pixelSize: 80
                                font.bold: true

                                Behavior on color { ColorAnimation { duration: 800 } }
                            }

                            // Spinner
                            Text {
                                anchors.centerIn: parent
                                visible: fng.fetching
                                text: "..."
                                color: "#3b82f6"
                                font.pixelSize: 40
                                font.bold: true

                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    running: fng.fetching
                                    NumberAnimation { to: 0.2; duration: 400 }
                                    NumberAnimation { to: 1.0; duration: 400 }
                                }
                            }
                        }

                        // Classification badge
                        Rectangle {
                            width: classLabel.implicitWidth + 20
                            height: 24
                            radius: 12
                            color: fng.value >= 0 ? Qt.rgba(
                                fng.indexColor(fng.value).r,
                                fng.indexColor(fng.value).g,
                                fng.indexColor(fng.value).b, 0.15) : "#111827"
                            border.color: fng.value >= 0 ? fng.indexColor(fng.value) : "#1e3a5f"
                            border.width: 1
                            visible: fng.classification !== ""

                            Text {
                                id: classLabel
                                anchors.centerIn: parent
                                text: fng.classification.toUpperCase()
                                color: fng.value >= 0 ? fng.indexColor(fng.value) : "#64748b"
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 1
                            }
                        }

                        Item { width: 1; height: 14 }

                        // Gauge bar
                        Column {
                            width: parent.width
                            spacing: 4
                            visible: fng.value >= 0

                            Rectangle {
                                width: parent.width
                                height: 6
                                radius: 3
                                color: "#0f1929"
                                border.color: "#1e2d50"
                                border.width: 1

                                Rectangle {
                                    width: parent.width * (fng.value / 100)
                                    height: parent.height
                                    radius: 3
                                    color: fng.indexColor(fng.value)
                                    Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
                                    Behavior on color { ColorAnimation { duration: 800 } }
                                }
                            }

                            Row {
                                width: parent.width

                                Text {
                                    text: "0  FEAR"
                                    color: "#ef4444"
                                    font.pixelSize: 10
                                    font.letterSpacing: 0.5
                                    width: parent.width / 2
                                }

                                Text {
                                    text: "GREED  100"
                                    color: "#22c55e"
                                    font.pixelSize: 10
                                    font.letterSpacing: 0.5
                                    width: parent.width / 2
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }
                }

                // ── METADATA CARD ────────────────────────────────────────────
                Rectangle {
                    width: cardsFlow.cardWidth
                    height: 260
                    color: "#0d1224"
                    border.color: "#1e3a5f"
                    border.width: 1
                    radius: 4

                    Rectangle {
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: 2
                        color: "#1e40af"
                        radius: 2
                    }

                    Column {
                        anchors { fill: parent; margins: 20 }
                        spacing: 0

                        Text {
                            text: "SIGNAL METADATA"
                            color: "#64748b"
                            font.pixelSize: 10
                            font.letterSpacing: 1.5
                            bottomPadding: 20
                        }

                        Repeater {
                            model: [
                                { label: "SOURCE",     value: "alternative.me" },
                                { label: "ENDPOINT",   value: "/fng/?limit=1" },
                                { label: "UPDATED",    value: fng.timestamp !== "" ? fng.timestamp : "--" },
                                { label: "RANGE",      value: "0 (Fear) – 100 (Greed)" },
                                { label: "STATUS",     value: fng.fetching ? "FETCHING..." : (fng.value >= 0 ? "OK" : (fng.errorMsg !== "" ? "ERROR" : "--")) }
                            ]

                            delegate: Column {
                                width: parent.width
                                spacing: 2
                                bottomPadding: 14

                                Text {
                                    text: modelData.label
                                    color: "#475569"
                                    font.pixelSize: 10
                                    font.letterSpacing: 1
                                }

                                Text {
                                    text: modelData.value
                                    color: modelData.label === "STATUS"
                                        ? (fng.value >= 0 ? "#22c55e" : (fng.errorMsg !== "" ? "#ef4444" : "#64748b"))
                                        : "#94a3b8"
                                    font.pixelSize: 12
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                // ── ZONE BREAKDOWN CARD ──────────────────────────────────────
                Rectangle {
                    width: cardsFlow.cardWidth
                    height: 260
                    color: "#0d1224"
                    border.color: "#1e3a5f"
                    border.width: 1
                    radius: 4

                    Rectangle {
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: 2
                        color: "#7c3aed"
                        radius: 2
                    }

                    Column {
                        anchors { fill: parent; margins: 20 }
                        spacing: 0

                        Text {
                            text: "ZONE BREAKDOWN"
                            color: "#64748b"
                            font.pixelSize: 10
                            font.letterSpacing: 1.5
                            bottomPadding: 16
                        }

                        Repeater {
                            model: [
                                { label: "EXTREME FEAR",  range: "0–24",   lo: 0,  hi: 24,  color: "#ef4444" },
                                { label: "FEAR",          range: "25–44",  lo: 25, hi: 44,  color: "#f97316" },
                                { label: "NEUTRAL",       range: "45–55",  lo: 45, hi: 55,  color: "#eab308" },
                                { label: "GREED",         range: "56–75",  lo: 56, hi: 75,  color: "#84cc16" },
                                { label: "EXTREME GREED", range: "76–100", lo: 76, hi: 100, color: "#22c55e" }
                            ]

                            delegate: Row {
                                width: parent.width
                                height: 28
                                spacing: 10

                                Rectangle {
                                    width: 3; height: 22
                                    color: modelData.color
                                    radius: 1
                                    opacity: fng.value >= 0 && fng.zoneActive(fng.value, modelData.lo, modelData.hi) ? 1.0 : 0.25
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 1

                                    Text {
                                        text: modelData.label
                                        color: fng.value >= 0 && fng.zoneActive(fng.value, modelData.lo, modelData.hi) ? modelData.color : "#334155"
                                        font.pixelSize: 11
                                        font.bold: fng.value >= 0 && fng.zoneActive(fng.value, modelData.lo, modelData.hi)
                                        font.letterSpacing: 0.5
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.range
                                    color: "#475569"
                                    font.pixelSize: 10
                                }
                            }
                        }
                    }
                }
                HistoryChart {
                    width: parent.width
                    height: isMobile ? 300 : Math.max(360, dashboardView.height - 260 - cardsFlow.spacing)
                    history: fng.history
                }

                Text {
                    width: parent.width
                    text: fng.errorMsg
                    color: "#ef4444"
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    visible: fng.errorMsg !== ""
                }
            } // cardsFlow

        }
    }

    Timer {
        id: sessionTimer
        interval: 1000
        running: appState === "dashboard"
        repeat: true
        onTriggered: {
            if (Date.now() >= SessionStore.expiresAt) logout()
        }
    }

    Component.onCompleted: {
        if (SessionStore.expiresAt > Date.now()) {
            appState = "dashboard"
            fng.fetch()
        } else {
            SessionStore.expiresAt = 0
            // On mobile an auto-focused field pops up the keyboard on the first tap anywhere
            if (!isMobile)
                userField.forceActiveFocus()
        }
    }

    function logout() {
        SessionStore.expiresAt = 0
        appState = "login"
        errorMsg = ""
        userField.text = ""; passField.text = ""
    }

    function doLogin() {
        errorMsg = ""
        if (userField.text === validUser && passField.text === validPass) {
            SessionStore.expiresAt = Date.now() + sessionDurationMs
            appState = "dashboard"
            // Move focus off the hidden text fields so the mobile keyboard closes and stays closed
            userField.focus = false
            passField.focus = false
            fng.fetch()
        } else {
            errorMsg = "Invalid credentials."
            passField.text = ""
            passField.forceActiveFocus()
        }
    }
}
