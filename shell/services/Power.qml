pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.config

Singleton {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property var batteries: UPower.devices.values.filter(candidate => candidate.isLaptopBattery)
    readonly property UPowerDevice battery: batteries[0] ?? null
    readonly property bool present: device?.isLaptopBattery ?? false
    readonly property real level: Math.max(0, Math.min(1, device?.percentage ?? 0))
    readonly property int percent: Math.round(level * 100)
    readonly property int state: device?.state ?? UPowerDeviceState.Unknown
    readonly property bool charging: state === UPowerDeviceState.Charging
    readonly property bool discharging: state === UPowerDeviceState.Discharging
    readonly property bool onAc: !UPower.onBattery
    readonly property real secondsLeft: (charging ? device?.timeToFull : device?.timeToEmpty) ?? 0
    readonly property string timeLeft: secondsLeft > 0 ? formatDuration(secondsLeft) : ""
    readonly property string status: describeState(state)
    readonly property real rate: device?.changeRate ?? 0
    readonly property real energy: device?.energy ?? 0
    readonly property real energyFull: device?.energyCapacity ?? 0
    readonly property bool healthKnown: (battery?.healthSupported ?? false) && battery.healthPercentage > 0
    readonly property real health: healthKnown ? battery.healthPercentage : 0
    readonly property real energyDesign: healthKnown && battery.energyCapacity > 0 ? battery.energyCapacity / (battery.healthPercentage / 100) : 0
    readonly property string sysfs: battery?.nativePath ? `/sys/class/power_supply/${battery.nativePath}` : ""
    property real voltage: 0
    property int cycles: 0
    property var history: []

    property bool detailed: false
    property int alertedLevel: 0
    readonly property bool low: discharging && percent <= Config.battery.lowThreshold
    readonly property int alertLevel: !present || !discharging ? 0 : percent <= Config.battery.criticalAt ? 2 : percent <= Config.battery.notifyAt ? 1 : 0

    onAlertLevelChanged: {
        if (alertLevel > alertedLevel && Config.battery.notifyLow)
            notifyLow(alertLevel === 2);
        alertedLevel = alertLevel;
    }

    function notifyLow(critical: bool): void {
        const summary = critical ? "Battery critical" : "Battery low";
        const body = timeLeft !== "" ? `${percent}% · ${timeLeft} left` : `${percent}%`;
        Quickshell.execDetached(["gdbus", "call", "--session", "--dest", "org.freedesktop.Notifications", "--object-path", "/org/freedesktop/Notifications", "--method", "org.freedesktop.Notifications.Notify", "Battery", "0", critical ? "battery-caution" : "battery-low", summary, body, "[]", `{"urgency": <byte ${critical ? 2 : 1}>}`, "-1"]);
    }

    readonly property int profile: PowerProfiles.profile
    readonly property bool hasPerformance: PowerProfiles.hasPerformanceProfile
    readonly property string degradation: describeDegradation(PowerProfiles.degradationReason)
    readonly property var holds: PowerProfiles.holds

    function setProfile(value: int): void {
        if (value === PowerProfile.Performance && !hasPerformance)
            return;
        PowerProfiles.profile = value;
    }

    function formatDuration(seconds: real): string {
        const minutes = Math.floor(seconds / 60);
        return `${Math.floor(minutes / 60)}:${String(minutes % 60).padStart(2, "0")}`;
    }

    function describeState(value: int): string {
        switch (value) {
        case UPowerDeviceState.Charging:
            return "Charging";
        case UPowerDeviceState.Discharging:
            return "On battery";
        case UPowerDeviceState.FullyCharged:
            return "Fully charged";
        case UPowerDeviceState.PendingCharge:
            return "Not charging";
        case UPowerDeviceState.Empty:
            return "Empty";
        default:
            return onAc ? "Plugged in" : "On battery";
        }
    }

    function describeDegradation(reason: int): string {
        switch (reason) {
        case PerformanceDegradationReason.LapDetected:
            return "lap detected";
        case PerformanceDegradationReason.HighTemperature:
            return "high temperature";
        default:
            return "";
        }
    }

    function parseHistory(text: string): void {
        const points = [];
        const pattern = /\((?:uint32 )?(\d+), ([\d.]+), (?:uint32 )?(\d+)\)/g;
        let match;
        while ((match = pattern.exec(text)) !== null) {
            const state = Number(match[3]);
            if (state === UPowerDeviceState.Unknown)
                continue;
            points.push({
                time: Number(match[1]) * 1000,
                value: Number(match[2]),
                charging: state === UPowerDeviceState.Charging
            });
        }
        points.sort((a, b) => a.time - b.time);
        history = points;
    }

    function refreshDetails(): void {
        if (sysfs === "")
            return;
        voltageFile.reload();
        cyclesFile.reload();
        if (!historyProcess.running)
            historyProcess.running = true;
    }

    onDetailedChanged: {
        if (detailed)
            refreshDetails();
    }

    FileView {
        id: voltageFile

        path: root.sysfs === "" ? "" : `${root.sysfs}/voltage_now`
        printErrors: false
        onLoaded: root.voltage = (parseInt(text()) || 0) / 1e6
    }

    FileView {
        id: cyclesFile

        path: root.sysfs === "" ? "" : `${root.sysfs}/cycle_count`
        printErrors: false
        onLoaded: root.cycles = parseInt(text()) || 0
    }

    Process {
        id: historyProcess

        command: ["gdbus", "call", "--system", "--dest", "org.freedesktop.UPower", "--object-path", `/org/freedesktop/UPower/devices/battery_${root.battery?.nativePath ?? ""}`, "--method", "org.freedesktop.UPower.Device.GetHistory", "charge", "86400", "400"]
        stdout: StdioCollector {
            onStreamFinished: root.parseHistory(text)
        }
    }

    Timer {
        interval: 10000
        running: root.detailed
        repeat: true
        onTriggered: root.refreshDetails()
    }
}
