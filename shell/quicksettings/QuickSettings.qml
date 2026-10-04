import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Panel {
    id: root

    property string sub: ""
    property string audioPicker: ""

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
        shown: root.open
        order: 0
        Layout.fillWidth: true
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
        shown: root.open
        order: 2
        visible: Brightness.available
        Layout.fillWidth: true
    }

    AudioRow {
        shown: root.open
        order: 3
        Layout.fillWidth: true
        node: Audio.sink
        glyph: "vol"
        heading: "Out"
        expanded: root.audioPicker === "out"
        onPickerToggled: root.audioPicker = root.audioPicker === "out" ? "" : "out"
    }

    AudioRow {
        shown: root.open
        order: 4
        Layout.fillWidth: true
        node: Audio.source
        glyph: "mic"
        heading: "In"
        output: false
        expanded: root.audioPicker === "in"
        onPickerToggled: root.audioPicker = root.audioPicker === "in" ? "" : "in"
    }

    Footer {
        shown: root.open
        order: 5
        Layout.fillWidth: true
    }
}
