pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.theme
import "SettingsFormat.js" as Format
import "../components/Glyphs.js" as Glyphs

ColumnLayout {
    id: root

    property var map: ({})
    property var suggestions: []
    property bool glyphs: false
    property string keyPlaceholder: "Key"
    property string valuePlaceholder: "Value"
    property var suggest: key => ""
    readonly property var keys: Object.keys(map).sort((a, b) => a.localeCompare(b))
    readonly property var missing: suggestions.filter(key => key !== "" && !(key in map))

    signal edited(var map)

    function validValue(value: string): bool {
        return value !== "" && (!glyphs || Glyphs.iconDots(value).length > 0);
    }

    spacing: 8

    component Keycap: Rectangle {
        property alias text: keyLabel.text

        implicitWidth: Math.min(keyLabel.implicitWidth + 20, 260)
        implicitHeight: 32
        radius: 6
        color: Theme.fill
        border.width: 1
        border.color: Theme.line

        Body {
            id: keyLabel

            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            font.pixelSize: 12
        }
    }

    Repeater {
        model: root.keys

        RowLayout {
            id: entry

            required property string modelData

            Layout.fillWidth: true
            spacing: 10

            Keycap {
                text: entry.modelData
            }

            DotIcon {
                visible: root.glyphs
                name: "chev"
                size: 10
                rotation: -90
                color: Theme.fg3
            }

            Item {
                Layout.fillWidth: true
            }

            DotIcon {
                visible: root.glyphs
                name: root.map[entry.modelData]
                color: Theme.fg
            }

            TextField {
                implicitWidth: 120
                text: root.map[entry.modelData] ?? ""
                valid: root.validValue(text)
                onCommitted: value => {
                    if (root.validValue(value.trim()))
                        root.edited(Format.withEntry(root.map, entry.modelData, value.trim()));
                }
            }

            MorphButton {
                implicitWidth: 32
                implicitHeight: 32
                restColor: "transparent"
                hoverColor: Theme.hover
                outline: "transparent"
                onClicked: root.edited(Format.withEntry(root.map, entry.modelData, undefined))

                DotIcon {
                    anchors.centerIn: parent
                    name: "close"
                    size: 12
                    color: Theme.fg2
                }
            }
        }
    }

    Flow {
        Layout.fillWidth: true
        visible: root.missing.length > 0
        spacing: 6

        Repeater {
            model: root.missing

            Pill {
                required property string modelData

                implicitHeight: 30
                text: `+ ${modelData}`
                onClicked: {
                    newKey.input.text = modelData;
                    newValue.input.text = root.suggest(modelData);
                    newValue.input.forceActiveFocus();
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        TextField {
            id: newKey

            Layout.fillWidth: true
            Layout.preferredWidth: 120
            controlled: false
            placeholder: root.keyPlaceholder
        }

        TextField {
            id: newValue

            implicitWidth: 120
            controlled: false
            placeholder: root.valuePlaceholder
            valid: input.text === "" || root.validValue(input.text.trim())
        }

        Pill {
            text: "Add"
            enabled: newKey.input.text.trim() !== "" && root.validValue(newValue.input.text.trim())
            onClicked: {
                root.edited(Format.withEntry(root.map, newKey.input.text.trim(), newValue.input.text.trim()));
                newKey.input.text = "";
                newValue.input.text = "";
                newKey.input.focus = false;
                newValue.input.focus = false;
            }
        }
    }
}
