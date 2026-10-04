import QtQuick
import Quickshell.Bluetooth
import qs.components
import qs.services
import qs.theme

ListRow {
    id: root

    required property var modelData
    property bool pairRequested: false

    width: parent?.width ?? 0
    current: modelData?.connected ?? false
    name: modelData?.name ?? ""
    busy: !!modelData && (modelData.pairing || modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting)
    status: {
        if (!modelData)
            return "";
        if (modelData.pairing)
            return "Pairing";
        if (modelData.state === BluetoothDeviceState.Connecting)
            return "Connecting";
        if (modelData.state === BluetoothDeviceState.Disconnecting)
            return "Disconnecting";
        if (modelData.connected)
            return modelData.batteryAvailable ? `Connected · ${Math.round(modelData.battery * 100)}%` : "Connected";
        if (modelData.paired)
            return "Paired";
        return "New device";
    }
    onClicked: {
        if (modelData.pairing) {
            modelData.cancelPair();
            return;
        }
        if (modelData.connected) {
            modelData.disconnect();
            return;
        }
        if (modelData.paired) {
            modelData.connect();
            return;
        }
        pairRequested = true;
        modelData.trusted = true;
        modelData.pair();
    }

    lead: DotIcon {
        name: Radios.deviceGlyph(root.modelData?.icon ?? "")
        size: 16
        color: root.current ? Theme.fg : Theme.fg2
    }

    Connections {
        target: root.modelData

        function onPairedChanged(): void {
            if (root.pairRequested && root.modelData.paired) {
                root.pairRequested = false;
                root.modelData.connect();
            }
        }
    }
}
