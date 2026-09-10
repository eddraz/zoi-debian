pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../Commons"
import "../Ui"

Column {
    id: root

    spacing: 8
    width: parent ? parent.width : 252

    property int cursor: -1

    function nextSection(back) {
        if (cursor < 0) cursor = back ? 4 : 0;
        else cursor = back ? (cursor - 1 + 5) % 5 : (cursor + 1) % 5;
    }

    function focusItem(entry) {
        cursor = entry.index;
    }

    readonly property var searchEntries: [
        { "label": "year prev anterior año", "index": 0 },
        { "label": "month prev mes anterior", "index": 1 },
        { "label": "today hoy actual", "index": 2 },
        { "label": "month next siguiente mes", "index": 3 },
        { "label": "year next siguiente año", "index": 4 }
    ]

    function runSlot(id) {
        if (id === 0) root.year -= 1;
        else if (id === 1) root.prevMonth();
        else if (id === 2) root.goToday();
        else if (id === 3) root.nextMonth();
        else if (id === 4) root.year += 1;
    }

    function handleKey(event) {
        const jump = KeyNav.jump(event, 5);
        if (jump >= 0) {
            cursor = jump;
            runSlot(jump);
            return true;
        }
        if (KeyNav.isLeft(event)) {
            if (cursor >= 0) cursor = Math.max(0, cursor - 1);
            else prevMonth();
            return true;
        }
        if (KeyNav.isRight(event)) {
            if (cursor >= 0) cursor = Math.min(4, cursor + 1);
            else nextMonth();
            return true;
        }
        if (KeyNav.isPrev(event)) { year -= 1; return true; }
        if (KeyNav.isNext(event)) { year += 1; return true; }
        if (KeyNav.isActivate(event)) {
            if (cursor >= 0) runSlot(cursor);
            else goToday();
            return true;
        }
        return false;
    }

    property int year: todayDate.getFullYear()
    property int month: todayDate.getMonth() + 1
    // todayDate se reasigna en goToday(); las propiedades today* dependen de él.
    property var todayDate: new Date()
    readonly property int todayYear: todayDate.getFullYear()
    readonly property int todayMonth: todayDate.getMonth() + 1
    readonly property int todayDay: todayDate.getDate()
    readonly property int daysInMonth: new Date(year, month, 0).getDate()
    readonly property int startOffset: {
        const weekday = new Date(year, month - 1, 1).getDay();
        return (weekday + 6) % 7;
    }

    // --- Holidays ---
    readonly property string holidayHelper: Quickshell.env("HOME") + "/.local/bin/qs-holidays"
    property var holidays: ({})          // { "YYYY-MM-DD": "name", ... }
    property int loadedYear: -1

    function loadHolidays() {
        if (year !== loadedYear) {
            holidayFetch.running = false;
            holidayFetch.running = true;
        }
    }

    function parseHolidays(raw) {
        try {
            const data = JSON.parse(raw);
            holidays = data;
            loadedYear = year;
        } catch (e) {
            holidays = {};
        }
    }

    function holidayName(day) {
        const key = year + "-" + String(month).padStart(2, "0") + "-" + String(day).padStart(2, "0");
        return holidays[key] || "";
    }

    function isWeekend(day) {
        const d = new Date(year, month - 1, day);
        const dow = d.getDay();
        return dow === 0 || dow === 6;  // Sunday=0, Saturday=6
    }

    Process {
        id: holidayFetch
        command: [root.holidayHelper, String(root.year)]
        stdout: StdioCollector {
            onStreamFinished: root.parseHolidays(text)
        }
    }

    onVisibleChanged: {
        if (visible) {
            goToday();
            loadHolidays();
        }
    }

    onYearChanged: loadHolidays()

    function goToday() {
        const date = new Date();
        year = date.getFullYear();
        month = date.getMonth() + 1;
        todayDate = date;
    }

    function prevMonth() {
        if (month === 1) {
            month = 12;
            year -= 1;
        } else {
            month -= 1;
        }
    }

    function nextMonth() {
        if (month === 12) {
            month = 1;
            year += 1;
        } else {
            month += 1;
        }
    }

    // ── Header: navigation row ──
    Row {
        width: parent.width
        spacing: 4

        Repeater {
            model: [
                { icon: "chev-double-left", action: "year-prev" },
                { icon: "chev-left", action: "month-prev" }
            ]

            Rectangle {
                required property var modelData
                required property int index
                width: 28
                height: 24
                radius: Style.radius
                color: root.cursor === index ? Color.focusFill : Color.surface
                border.width: root.cursor === index ? 1 : 0
                border.color: Color.accent

                StatusIcon {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    icon: parent.modelData.icon
                    stroke: parent.modelData && root.cursor === parent.index ? Color.accent : Color.popupText
                }

                HoverMouse {
                    onClicked: {
                        root.cursor = index;
                        if (modelData.action === "year-prev")
                            root.year -= 1;
                        else
                            root.prevMonth();
                    }
                }
            }
        }

        Rectangle {
            width: parent.width - 28 * 4 - 4 * 4
            height: 34
            radius: Style.radius
            color: root.cursor === 2 ? Color.focusFill : "transparent"
            border.width: root.cursor === 2 ? 1 : 0
            border.color: Color.accent

            Column {
                anchors.centerIn: parent
                spacing: 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: root.cursor === 2 ? Color.accent : Color.popupText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    font.bold: true
                    text: Qt.locale().monthName(root.month - 1, Locale.LongFormat) + " " + root.year
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: Weather.country !== ""
                    color: Color.popupMuted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontBadge
                    text: Weather.city !== "" ? (Weather.city + " · " + Weather.country) : Weather.country
                }
            }

            HoverMouse {
                onClicked: {
                    root.cursor = 2;
                    root.goToday();
                }
            }
        }

        Repeater {
            model: [
                { icon: "chev-right", action: "month-next" },
                { icon: "chev-double-right", action: "year-next" }
            ]

            Rectangle {
                required property var modelData
                required property int index
                width: 28
                height: 24
                radius: Style.radius
                color: root.cursor === index + 3 ? Color.focusFill : Color.surface
                border.width: root.cursor === index + 3 ? 1 : 0
                border.color: Color.accent

                StatusIcon {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    icon: parent.modelData.icon
                    stroke: root.cursor === parent.index + 3 ? Color.accent : Color.popupText
                }

                HoverMouse {
                    onClicked: {
                        root.cursor = index + 3;
                        if (modelData.action === "year-next")
                            root.year += 1;
                        else
                            root.nextMonth();
                    }
                }
            }
        }
    }

    // ── Day-of-week headers ──
    Row {
        width: parent.width

        Repeater {
            model: 7

            Text {
                required property int index
                width: root.width / 7
                height: 18
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                // Highlight weekend headers (Sat=5, Sun=6 in our Mon-first layout)
                color: (index >= 5) ? Color.peach : Color.popupMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                font.bold: index >= 5
                text: Qt.locale().dayName(index === 6 ? 7 : index + 1, Locale.ShortFormat)
            }
        }
    }

    // ── Day grid ──
    Grid {
        id: grid
        width: parent.width
        columns: 7
        rows: 6

        Repeater {
            model: 42

            Item {
                required property int index
                readonly property int day: index - root.startOffset + 1
                readonly property bool inMonth: day >= 1 && day <= root.daysInMonth
                readonly property bool isToday: inMonth && day === root.todayDay && root.month === root.todayMonth && root.year === root.todayYear
                readonly property bool isWeekend: inMonth && root.isWeekend(day)
                readonly property string holiday: inMonth ? root.holidayName(day) : ""
                readonly property bool isHoliday: holiday !== ""

                width: grid.width / 7
                height: 26

                Rectangle {
                    id: dayCell
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    radius: 4
                    visible: parent.inMonth
                    color: {
                        if (parent.isToday)
                            return Color.accent;
                        if (dayMouse.containsMouse) {
                            if (parent.isHoliday)
                                return Qt.rgba(Color.urgent.r, Color.urgent.g, Color.urgent.b, 0.18);
                            if (parent.isWeekend)
                                return Qt.rgba(Color.peach.r, Color.peach.g, Color.peach.b, 0.18);
                            return Color.focusFill;
                        }
                        return "transparent";
                    }

                    Text {
                        anchors.centerIn: parent
                        color: {
                            if (dayCell.parent.isToday)
                                return Color.crust;
                            if (dayCell.parent.isHoliday)
                                return Color.urgent;
                            if (dayCell.parent.isWeekend)
                                return Color.peach;
                            return Color.popupText;
                        }
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        font.bold: dayCell.parent.isToday || dayCell.parent.isHoliday
                        text: dayCell.parent.day
                    }

                    // Holiday dot indicator
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 1
                        width: 3
                        height: 3
                        radius: 1.5
                        color: dayCell.parent.isToday ? Color.crust : Color.urgent
                        visible: dayCell.parent.isHoliday
                    }

                    MouseArea {
                        id: dayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: dayCell.parent.isHoliday ? Qt.PointingHandCursor : Qt.ArrowCursor

                        onContainsMouseChanged: {
                            if (containsMouse && dayCell.parent.isHoliday)
                                HoverTip.show(dayCell, dayCell.parent.holiday);
                            else
                                HoverTip.hide();
                        }
                    }
                }
            }
        }
    }

    // ── Legend row ──
    Row {
        width: parent.width
        spacing: 8
        topPadding: 2

        // Today
        Row {
            spacing: 4
            Rectangle {
                width: 8; height: 8; radius: 2
                color: Color.accent
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                color: Color.popupMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontBadge
                text: "Hoy"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Weekend
        Row {
            spacing: 4
            Rectangle {
                width: 8; height: 8; radius: 2
                color: Color.peach
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                color: Color.popupMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontBadge
                text: "Fin de semana"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Holiday
        Row {
            spacing: 4
            Rectangle {
                width: 8; height: 8; radius: 2
                color: Color.urgent
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                color: Color.popupMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontBadge
                text: "Festivo"
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}

