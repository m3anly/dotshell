pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.theme

Panel {
    id: root

    readonly property Item page: [monitor, shell].find(candidate => candidate.current) ?? monitor

    width: 520

    Reveal {
        shown: root.open
        order: 0
        Layout.fillWidth: true
        implicitHeight: tabs.implicitHeight

        TabBar {
            id: tabs

            anchors.left: parent.left
            anchors.right: parent.right
            group: "system"
            animate: root.open
            tabs: [
                {
                    id: "monitor",
                    glyph: "spark",
                    label: "System"
                },
                {
                    id: "shell",
                    glyph: "gear",
                    label: "Shell"
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

        MonitorPage {
            id: monitor

            anchors.left: parent.left
            anchors.right: parent.right
        }

        ShellPage {
            id: shell

            anchors.left: parent.left
            anchors.right: parent.right
            open: root.open
        }
    }
}
