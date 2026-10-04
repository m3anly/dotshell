pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.theme

TabPage {
    id: root

    property bool open: false
    readonly property date today: Time.date
    readonly property int dayOfYear: Math.round((new Date(today.getFullYear(), today.getMonth(), today.getDate()) - new Date(today.getFullYear(), 0, 1)) / 86400000) + 1
    readonly property int daysInYear: new Date(today.getFullYear(), 1, 29).getDate() === 29 ? 366 : 365
    readonly property int isoWeek: {
        const day = new Date(Date.UTC(today.getFullYear(), today.getMonth(), today.getDate()));
        const weekday = day.getUTCDay() || 7;
        day.setUTCDate(day.getUTCDate() + 4 - weekday);
        const yearStart = new Date(Date.UTC(day.getUTCFullYear(), 0, 1));
        return Math.ceil(((day - yearStart) / 86400000 + 1) / 7);
    }

    tab: "calendar"
    implicitHeight: layout.implicitHeight

    onOpenChanged: {
        if (open)
            calendar.jumpToToday();
    }

    RowLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 22

        ColumnLayout {
            Layout.fillWidth: false
            Layout.preferredWidth: 190
            Layout.maximumWidth: 190
            Layout.alignment: Qt.AlignTop
            Layout.leftMargin: 4
            spacing: 4

            Label {
                text: Time.dayName(root.today.getDay())
                pixelSize: 12
                color: Theme.red
            }

            DisplayText {
                text: Time.pad(root.today.getDate())
                font.pixelSize: 104
                Layout.topMargin: -10
                Layout.bottomMargin: -14
            }

            Label {
                text: `${Time.monthName(root.today.getMonth())} ${root.today.getFullYear()}`
                pixelSize: 13
            }

            Item {
                Layout.preferredHeight: 18
            }

            DottedLine {
                Layout.fillWidth: true
                vertical: false
            }

            Item {
                Layout.preferredHeight: 10
            }

            Label {
                text: `Week ${root.isoWeek}`
                pixelSize: 11
                color: Theme.fg2
            }

            Label {
                text: `Day ${root.dayOfYear} · ${root.daysInYear - root.dayOfYear} left`
                pixelSize: 11
                color: Theme.fg2
            }

            Grid {
                Layout.topMargin: 10
                columns: 26
                spacing: 1.6

                Repeater {
                    model: 52

                    Rectangle {
                        required property int index

                        width: 5.6
                        height: 5.6
                        radius: 2.8
                        color: index === root.isoWeek - 1 ? Theme.red : index < root.isoWeek - 1 ? Theme.fg2 : Theme.off
                        antialiasing: true
                    }
                }
            }
        }

        MonthCalendar {
            id: calendar

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
        }
    }
}
