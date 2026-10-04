pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.theme

Panel {
    id: root

    readonly property Item page: [media, calendar, weather].find(candidate => candidate.current) ?? media

    width: 600
    transformOrigin: Theme.barAtBottom ? Item.Bottom : Item.Top

    Reveal {
        shown: root.open
        order: 0
        Layout.fillWidth: true
        implicitHeight: tabs.implicitHeight

        TabBar {
            id: tabs

            anchors.left: parent.left
            anchors.right: parent.right
            animate: root.open
            tabs: [
                {
                    id: "media",
                    glyph: "note",
                    label: "Media"
                },
                {
                    id: "calendar",
                    glyph: "calendar",
                    label: "Calendar"
                },
                {
                    id: "weather",
                    glyph: Weather.available ? Weather.glyph : "cloud",
                    label: "Weather"
                }
            ]
        }
    }

    Reveal {
        shown: root.open
        order: 1
        Layout.fillWidth: true
        implicitHeight: root.page.implicitHeight
        clip: true

        Behavior on implicitHeight {
            enabled: !Motion.reduced && root.open

            SpatialStandard {}
        }

        MediaPage {
            id: media

            anchors.left: parent.left
            anchors.right: parent.right
            open: root.open
        }

        CalendarPage {
            id: calendar

            anchors.left: parent.left
            anchors.right: parent.right
            open: root.open
        }

        WeatherPage {
            id: weather

            anchors.left: parent.left
            anchors.right: parent.right
        }
    }
}
