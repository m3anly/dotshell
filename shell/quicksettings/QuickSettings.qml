import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.theme

Panel {
    id: root

    property string sub: ""
    property string audioPicker: ""
    property bool compact: false
    property real expansion: compact ? 0 : 1

    fromRight: true
    onOpenChanged: {
        if (open)
            Brightness.refresh();
        if (!open) {
            sub = "";
            audioPicker = "";
            Radios.stopScanning();
        }
    }
    onSubChanged: {
        if (sub !== "bluetooth")
            Radios.stopScanning();
    }

    Item {
        visible: false

        states: State {
            name: "compact"
            when: root.compact

            PropertyChanges {
                root.expansion: 0
            }
        }

        transitions: [
            Transition {
                from: "compact"
                enabled: !Motion.reduced

                Expand {
                    property: "expansion"
                }
            },
            Transition {
                to: "compact"
                enabled: !Motion.reduced

                Exit {
                    property: "expansion"
                    duration: 220
                }
            }
        ]
    }

    function toggleSub(kind: string): void {
        sub = sub === kind ? "" : kind;
    }

    Binding {
        target: Radios.wifiDevice
        property: "scannerEnabled"
        value: true
        when: root.open && Radios.wifiEnabled && Radios.wifiDevice !== null
    }

    Header {
        shown: root.open && !root.compact
        order: 0
        visible: root.expansion > 0
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight * root.expansion
        Layout.bottomMargin: -12 * (1 - root.expansion)
    }

    Reveal {
        shown: root.open
        order: 1
        Layout.fillWidth: true
        implicitHeight: tilesColumn.implicitHeight

        ColumnLayout {
            id: tilesColumn

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RadioTile {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    glyph: "wifi"
                    on: Radios.wifiEnabled
                    expanded: root.sub === "wifi"
                    title: Radios.wifiEnabled && Radios.currentNetwork ? Radios.currentNetwork.name : "Wi-Fi"
                    subtitle: {
                        if (!Radios.wifiEnabled)
                            return "Off";
                        if (!Radios.currentNetwork)
                            return "Not connected";
                        return `${Math.round(Radios.currentNetwork.signalStrength * 100)}% · ${Radios.onlineState}`;
                    }
                    onToggled: Radios.toggleWifi()
                    onOpened: root.toggleSub("wifi")
                }

                RadioTile {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    glyph: "bt"
                    on: Radios.bluetoothEnabled
                    expanded: root.sub === "bluetooth"
                    title: Radios.bluetoothEnabled && Radios.connectedDevices.length > 0 ? Radios.connectedDevices[0].name : "Bluetooth"
                    subtitle: {
                        const connected = Radios.connectedDevices.length;
                        if (!Radios.bluetoothEnabled)
                            return "Off";
                        if (connected > 0)
                            return connected > 1 ? `Connected +${connected - 1}` : "Connected";
                        return `${Radios.pairedCount} paired`;
                    }
                    onToggled: Radios.toggleBluetooth()
                    onOpened: root.toggleSub("bluetooth")
                }
            }

            SubPanel {
                Layout.fillWidth: true
                kind: root.sub
            }
        }
    }

    BrightnessRow {
        shown: root.open && !root.compact
        order: 2
        visible: Brightness.available && root.expansion > 0
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight * root.expansion
        Layout.topMargin: -12 * (1 - root.expansion)
    }

    AudioRow {
        shown: root.open && !root.compact
        order: 3
        visible: root.expansion > 0
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight * root.expansion
        Layout.topMargin: -12 * (1 - root.expansion)
        node: Audio.sink
        glyph: Audio.glyph(Audio.sink)
        heading: "Out"
        expanded: root.audioPicker === "out"
        onPickerToggled: root.audioPicker = root.audioPicker === "out" ? "" : "out"
    }

    AudioRow {
        shown: root.open && !root.compact
        order: 4
        visible: root.expansion > 0
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight * root.expansion
        Layout.topMargin: -12 * (1 - root.expansion)
        node: Audio.source
        glyph: "mic"
        heading: "In"
        output: false
        expanded: root.audioPicker === "in"
        onPickerToggled: root.audioPicker = root.audioPicker === "in" ? "" : "in"
    }

    Footer {
        shown: root.open && !root.compact
        order: 5
        visible: root.expansion > 0
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight * root.expansion
        Layout.topMargin: -12 * (1 - root.expansion)
    }
}
