pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking

Singleton {
    id: root

    readonly property var wifiDevice: Networking.devices.values.find(device => device.type === DeviceType.Wifi) ?? null
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiConnected: wifiEnabled && (wifiDevice?.connected ?? false)
    readonly property var wifiNetworks: wifiDevice ? wifiDevice.networks.values.filter(network => network.name !== "").sort(compareNetworks) : []
    readonly property var currentNetwork: wifiNetworks.find(network => network.connected) ?? null
    property bool wifiScanning: false
    readonly property string onlineState: {
        switch (Networking.connectivity) {
        case NetworkConnectivity.None:
            return "offline";
        case NetworkConnectivity.Portal:
            return "portal";
        case NetworkConnectivity.Limited:
            return "limited";
        default:
            return "online";
        }
    }

    readonly property BluetoothAdapter bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property bool bluetoothEnabled: bluetoothAdapter?.enabled ?? false
    readonly property bool discovering: bluetoothAdapter?.discovering ?? false
    property bool showNewDevices: false
    readonly property var bluetoothDevices: bluetoothAdapter ? bluetoothAdapter.devices.values.filter(device => device.paired || device.connected || (showNewDevices && device.name !== "")).sort(compareDevices) : []
    readonly property var connectedDevices: bluetoothDevices.filter(device => device.connected)
    readonly property int pairedCount: bluetoothDevices.filter(device => device.paired).length

    function signalBars(strength: real): int {
        return Math.max(0, Math.min(3, Math.floor(strength * 4)));
    }

    function compareNetworks(a: var, b: var): int {
        return (b.connected - a.connected) || (b.known - a.known) || (signalBars(b.signalStrength) - signalBars(a.signalStrength)) || a.name.localeCompare(b.name);
    }

    function compareDevices(a: var, b: var): int {
        return (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name);
    }

    function toggleWifi(): void {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function scanWifi(): void {
        if (!wifiEnabled || wifiScanning)
            return;
        wifiScanning = true;
        Quickshell.execDetached(["nmcli", "device", "wifi", "rescan"]);
        wifiScanTimeout.restart();
    }

    function toggleBluetooth(): void {
        if (bluetoothAdapter)
            bluetoothAdapter.enabled = !bluetoothAdapter.enabled;
    }

    function scanBluetooth(): void {
        if (!bluetoothAdapter || !bluetoothAdapter.enabled)
            return;
        showNewDevices = true;
        bluetoothAdapter.discovering = true;
        discoveryTimeout.restart();
    }

    function stopScanning(): void {
        discoveryTimeout.stop();
        if (bluetoothAdapter?.discovering)
            bluetoothAdapter.discovering = false;
        showNewDevices = false;
    }

    function deviceGlyph(icon: string): string {
        if (icon.startsWith("input-gaming"))
            return "pad";
        if (icon.startsWith("audio-head"))
            return "phones";
        if (icon.startsWith("audio"))
            return "buds";
        return "bt";
    }

    Timer {
        id: wifiScanTimeout

        interval: 4000
        onTriggered: root.wifiScanning = false
    }

    Timer {
        id: discoveryTimeout

        interval: 15000
        onTriggered: {
            if (root.bluetoothAdapter?.discovering)
                root.bluetoothAdapter.discovering = false;
        }
    }
}
