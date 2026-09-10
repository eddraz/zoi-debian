pragma ComponentBehavior: Bound

import QtQuick
import "../Commons"
import "../Ui"

Column {
    id: root

    spacing: 8
    width: parent ? parent.width : 252

    function handleKey(event) {
        if (KeyNav.isLeft(event)) { prevMonth(); return true; }
        if (KeyNav.isRight(event)) { nextMonth(); return true; }
        if (KeyNav.isPrev(event)) { year -= 1; return true; }
        if (KeyNav.isNext(event)) { year += 1; return true; }
        if (KeyNav.isActivate(event)) { goToday(); return true; }
        return false;
    }

    property int year: now.getFullYear()
    property int month: now.getMonth() + 1
    readonly property var now: new Date()
    readonly property int todayYear: now.getFullYear()
    readonly property int todayMonth: now.getMonth() + 1
    readonly property int todayDay: now.getDate()
    readonly property int daysInMonth: new Date(year, month, 0).getDate()
    readonly property int startOffset: {
        const weekday = new Date(year, month - 1, 1).getDay();
        return (weekday + 6) % 7;
    }

    onVisibleChanged: if (visible)
        goToday()

    function goToday() {
        const date = new Date();
        year = date.getFullYear();
        month = date.getMonth() + 1;
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

    Row {
        width: parent.width
        spacing: 4

        Repeater {
            model: [
                { label: "<<", action: "year-prev" },
                { label: "<", action: "month-prev" }
            ]

            Rectangle {
                required property var modelData
                width: 28
                height: 24
                radius: Style.radius
                color: Color.surface

                Text {
                    anchors.centerIn: parent
                    color: Color.popupText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    font.bold: true
                    text: modelData.label
                }

                HoverMouse {
                    onClicked: {
                        if (modelData.action === "year-prev")
                            root.year -= 1;
                        else
                            root.prevMonth();
                    }
                }
            }
        }

        Item {
            width: parent.width - 28 * 4 - 4 * 4
            height: 24

            Text {
                anchors.centerIn: parent
                color: Color.popupText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                font.bold: true
                text: Qt.locale().monthName(root.month, Locale.LongFormat) + " " + root.year

                HoverMouse {
                    onClicked: root.goToday()
                }
            }
        }

        Repeater {
            model: [
                { label: ">", action: "month-next" },
                { label: ">>", action: "year-next" }
            ]

            Rectangle {
                required property var modelData
                width: 28
                height: 24
                radius: Style.radius
                color: Color.surface

                Text {
                    anchors.centerIn: parent
                    color: Color.popupText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    font.bold: true
                    text: modelData.label
                }

                HoverMouse {
                    onClicked: {
                        if (modelData.action === "year-next")
                            root.year += 1;
                        else
                            root.nextMonth();
                    }
                }
            }
        }
    }

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
                color: Color.popupMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                text: Qt.locale().dayName(index === 6 ? 7 : index + 1, Locale.ShortFormat)
            }
        }
    }

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

                width: grid.width / 7
                height: 26

                Rectangle {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    radius: 4
                    visible: parent.inMonth
                    color: parent.isToday ? Color.accent : "transparent"

                    Text {
                        anchors.centerIn: parent
                        color: parent.parent.isToday ? Color.background : Color.popupText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        font.bold: parent.parent.isToday
                        text: parent.parent.day
                    }
                }
            }
        }
    }
}
