pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.theme
import "SettingsFormat.js" as Format

ColumnLayout {
    id: root

    property string value
    readonly property var presets: ["#F2C230", "#FF8A3D", "#4CC38A", "#5AA9FF", "#B58CFF", "#F2F2F0"]

    signal picked(string value)

    spacing: 14

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        spacing: 12

        Repeater {
            model: root.presets

            Rectangle {
                id: swatch

                required property string modelData
                readonly property bool selected: Format.normalizeColor(root.value) === modelData

                implicitWidth: 30
                implicitHeight: 30
                radius: selected ? 9 : 15
                color: modelData
                border.width: selected ? 2 : 0
                border.color: Theme.glassBase
                antialiasing: true
                scale: swatchMouse.pressed ? 0.86 : 1

                Behavior on radius {
                    enabled: !Motion.reduced

                    SpatialStandard {}
                }
                Behavior on scale {
                    enabled: !Motion.reduced

                    SpatialFast {
                        epsilon: 0.002
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: parent.radius + 3
                    color: "transparent"
                    border.width: 1
                    border.color: swatch.selected ? Theme.fg : "transparent"
                    antialiasing: true

                    Behavior on border.color {
                        EffectsColor {}
                    }
                }

                MouseArea {
                    id: swatchMouse

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(swatch.modelData)
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        TextField {
            implicitWidth: 120
            text: root.value
            valid: Format.normalizeColor(input.text) !== ""
            onCommitted: value => {
                const normalized = Format.normalizeColor(value);
                if (normalized !== "")
                    root.picked(normalized);
            }
        }
    }

    Row {
        Layout.leftMargin: 4
        spacing: 12

        Repeater {
            model: ["empty", "occupied", "urgent", "active", "occupied"]

            Item {
                id: preview

                required property string modelData

                width: 8
                height: 8

                Rectangle {
                    anchors.centerIn: parent
                    visible: preview.modelData === "active"
                    width: 16
                    height: 16
                    radius: 8
                    color: Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.22)
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    border.width: preview.modelData === "empty" ? 1 : 0
                    border.color: Theme.fg2
                    color: {
                        if (preview.modelData === "urgent")
                            return Format.normalizeColor(root.value) || Theme.urgent;
                        if (preview.modelData === "active")
                            return Theme.red;
                        if (preview.modelData === "occupied")
                            return Theme.fg2;
                        return "transparent";
                    }

                    Behavior on color {
                        EffectsColor {}
                    }
                }
            }
        }
    }
}
