import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root
    width: 1024
    height: 640
    visible: true
    title: "CRYPTO FEAR & GREED"
    color: "#080c18"

    readonly property string fngApiUrl: "https://api.alternative.me/fng/?limit=1"

    property string appState: "login"
    property int fngValue: -1
    property string fngClassification: ""
    property string fngTimestamp: ""
    property string errorMsg: ""
    property bool fetching: false

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
                text: "CRYPTO FEAR & GREED INDEX"
                color: "#e2e8f0"
                font.pixelSize: 13
                font.bold: true
                font.letterSpacing: 2
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
                    onClicked: {
                        appState = "login"
                        fngValue = -1; fngClassification = ""; fngTimestamp = ""
                        errorMsg = ""
                        userField.text = ""; passField.text = ""
                    }
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
            width: 380
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
                anchors { fill: parent; margins: 28 }
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
        Item {
            anchors { fill: parent; margins: 24 }

            // ── INDEX CARD ────────────────────────────────────────────────────
            Rectangle {
                id: indexCard
                anchors { top: parent.top; left: parent.left }
                width: 320
                height: 260
                color: "#0d1224"
                border.color: "#1e3a5f"
                border.width: 1
                radius: 4

                Rectangle {
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: 2
                    color: fngValue >= 0 ? indexColor(fngValue) : "#3b82f6"
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
                            text: fngValue >= 0 ? fngValue : "--"
                            color: fngValue >= 0 ? indexColor(fngValue) : "#1e3a5f"
                            font.pixelSize: 80
                            font.bold: true

                            Behavior on color { ColorAnimation { duration: 800 } }
                        }

                        // Spinner
                        Text {
                            anchors.centerIn: parent
                            visible: fetching
                            text: "..."
                            color: "#3b82f6"
                            font.pixelSize: 40
                            font.bold: true

                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: fetching
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
                        color: fngValue >= 0 ? Qt.rgba(
                            Qt.color(indexColor(fngValue)).r,
                            Qt.color(indexColor(fngValue)).g,
                            Qt.color(indexColor(fngValue)).b, 0.15) : "#111827"
                        border.color: fngValue >= 0 ? indexColor(fngValue) : "#1e3a5f"
                        border.width: 1
                        visible: fngClassification !== ""

                        Text {
                            id: classLabel
                            anchors.centerIn: parent
                            text: fngClassification.toUpperCase()
                            color: fngValue >= 0 ? indexColor(fngValue) : "#64748b"
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
                        visible: fngValue >= 0

                        Rectangle {
                            width: parent.width
                            height: 6
                            radius: 3
                            color: "#0f1929"
                            border.color: "#1e2d50"
                            border.width: 1

                            Rectangle {
                                width: parent.width * (fngValue / 100)
                                height: parent.height
                                radius: 3
                                color: indexColor(fngValue)
                                Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 800 } }
                            }
                        }

                        Row {
                            width: parent.width

                            Text {
                                text: "0  FEAR"
                                color: "#ef4444"
                                font.pixelSize: 9
                                font.letterSpacing: 0.5
                                width: parent.width / 2
                            }

                            Text {
                                text: "GREED  100"
                                color: "#22c55e"
                                font.pixelSize: 9
                                font.letterSpacing: 0.5
                                width: parent.width / 2
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }

            // ── METADATA CARD ─────────────────────────────────────────────────
            Rectangle {
                anchors { top: parent.top; left: indexCard.right; leftMargin: 16 }
                width: 280
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
                            { label: "UPDATED",    value: fngTimestamp !== "" ? fngTimestamp.substring(0, 16) : "--" },
                            { label: "RANGE",      value: "0 (Fear) – 100 (Greed)" },
                            { label: "STATUS",     value: fetching ? "FETCHING..." : (fngValue >= 0 ? "OK" : (errorMsg !== "" ? "ERROR" : "--")) }
                        ]

                        delegate: Column {
                            width: parent.width
                            spacing: 2
                            bottomPadding: 14

                            Text {
                                text: modelData.label
                                color: "#334155"
                                font.pixelSize: 9
                                font.letterSpacing: 1
                            }

                            Text {
                                text: modelData.value
                                color: modelData.label === "STATUS"
                                    ? (fngValue >= 0 ? "#22c55e" : (errorMsg !== "" ? "#ef4444" : "#64748b"))
                                    : "#94a3b8"
                                font.pixelSize: 12
                                width: parent.width
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            // ── ZONE BREAKDOWN CARD ───────────────────────────────────────────
            Rectangle {
                anchors { top: parent.top; left: indexCard.right; leftMargin: 16 + 280 + 16 }
                width: 280
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
                            { label: "EXTREME FEAR",  range: "0–24",  color: "#ef4444" },
                            { label: "FEAR",          range: "25–44", color: "#f97316" },
                            { label: "NEUTRAL",       range: "45–55", color: "#eab308" },
                            { label: "GREED",         range: "56–75", color: "#84cc16" },
                            { label: "EXTREME GREED", range: "76–100",color: "#22c55e" }
                        ]

                        delegate: Row {
                            width: parent.width
                            height: 28
                            spacing: 10

                            Rectangle {
                                width: 3; height: 22
                                color: modelData.color
                                radius: 1
                                opacity: fngValue >= 0 && zoneActive(fngValue, modelData.range) ? 1.0 : 0.25
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                Text {
                                    text: modelData.label
                                    color: fngValue >= 0 && zoneActive(fngValue, modelData.range) ? modelData.color : "#334155"
                                    font.pixelSize: 11
                                    font.bold: fngValue >= 0 && zoneActive(fngValue, modelData.range)
                                    font.letterSpacing: 0.5
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.range
                                color: "#1e3a5f"
                                font.pixelSize: 10
                            }
                        }
                    }
                }
            }

            // ── BOTTOM ACTION BAR ─────────────────────────────────────────────
            Row {
                anchors { top: indexCard.bottom; topMargin: 16; left: parent.left }
                spacing: 12

                Rectangle {
                    width: 120; height: 34
                    radius: 2
                    color: refreshArea.pressed ? "#1d4ed8" : (refreshArea.containsMouse ? "#1e3a5f" : "transparent")
                    border.color: "#3b82f6"
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "↻"
                            color: "#3b82f6"
                            font.pixelSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "REFRESH"
                            color: "#3b82f6"
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: refreshArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: fetchFng()
                    }
                }

                Text {
                    text: errorMsg
                    color: "#ef4444"
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                    visible: errorMsg !== ""
                }
            }
        }
    }

    Component.onCompleted: userField.forceActiveFocus()

    function doLogin() {
        errorMsg = ""
        if (userField.text === validUser && passField.text === validPass) {
            appState = "dashboard"
            fetchFng()
        } else {
            errorMsg = "Invalid credentials."
            passField.text = ""
            passField.forceActiveFocus()
        }
    }

    function fetchFng() {
        fetching = true
        errorMsg = ""
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                fetching = false
                if (xhr.status === 200) {
                    try {
                        var json = JSON.parse(xhr.responseText)
                        var entry = json.data[0]
                        var parsed = parseInt(entry.value)
                        if (isNaN(parsed)) {
                            errorMsg = "Parse error: unexpected value format"
                            return
                        }
                        fngValue = parsed
                        fngClassification = entry.value_classification
                        var d = new Date(parseInt(entry.timestamp) * 1000)
                        fngTimestamp = d.toISOString().replace("T", " ")
                    } catch (e) {
                        errorMsg = "Parse error: unexpected response format"
                    }
                } else {
                    errorMsg = "HTTP " + xhr.status + " - fetch failed"
                }
            }
        }
        xhr.open("GET", fngApiUrl)
        xhr.send()
    }

    function indexColor(val) {
        if (val <= 24) return "#ef4444"
        if (val <= 44) return "#f97316"
        if (val <= 55) return "#eab308"
        if (val <= 75) return "#84cc16"
        return "#22c55e"
    }

    function zoneActive(val, range) {
        var parts = range.split("–")
        if (parts.length !== 2) return false
        var lo = parseInt(parts[0])
        var hi = parseInt(parts[1])
        return !isNaN(lo) && !isNaN(hi) && val >= lo && val <= hi
    }
}
