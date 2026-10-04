pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs.config

Singleton {
    id: root

    property string kind: ""
    property string screen: ""
    property bool shown: false
    property bool hovered: false
    property bool pressed: false
    readonly property bool held: hovered || pressed
    property real quietUntil: Date.now() + 2000
    readonly property PwNode sink: Audio.sink
    readonly property PwNode source: Audio.source
    readonly property var statusKinds: ["capslock", "numlock", "scrolllock", "layout", "wifi", "bluetooth", "profile"]
    readonly property bool isStatus: statusKinds.includes(kind)
    readonly property var status: describe(kind)

    onSinkChanged: quietUntil = Date.now() + 1500
    onSourceChanged: quietUntil = Date.now() + 1500
    onHeldChanged: {
        if (held)
            hideTimer.stop();
        else if (shown)
            hideTimer.restart();
    }

    function describe(value: string): var {
        const toggle = (glyph, label, on) => ({
                glyph: glyph,
                label: label,
                state: on ? "On" : "Off",
                on: on
            });
        switch (value) {
        case "capslock":
            return toggle("caps", "Caps Lock", Locks.caps);
        case "numlock":
            return toggle("num", "Num Lock", Locks.num);
        case "scrolllock":
            return toggle("scroll", "Scroll Lock", Locks.scroll);
        case "wifi":
            return toggle("wifi", "Wi-Fi", Radios.wifiEnabled);
        case "bluetooth":
            return toggle("bt", "Bluetooth", Radios.bluetoothEnabled);
        case "layout":
            return {
                glyph: "keyboard",
                label: Niri.layoutNames[Niri.layoutIndex] ?? "Layout",
                state: Niri.layoutShort,
                on: null
            };
        case "profile":
            if (Power.profile === PowerProfile.PowerSaver)
                return {
                    glyph: "leaf",
                    label: "Power mode",
                    state: "Efficiency",
                    on: null
                };
            if (Power.profile === PowerProfile.Performance)
                return {
                    glyph: "bolt",
                    label: "Power mode",
                    state: "Performance",
                    on: null
                };
            return {
                glyph: "half",
                label: "Power mode",
                state: "Balanced",
                on: null
            };
        default:
            return {
                glyph: "",
                label: "",
                state: "",
                on: null
            };
        }
    }

    function suppressed(nextKind: string, target: string): bool {
        const panelHere = Ui.panel !== "" && Ui.screen === target;
        const mediaHere = panelHere && Ui.panel === "dashboard" && Ui.dashboardTab === "media";
        switch (nextKind) {
        case "volume":
            return panelHere && (Ui.panel === "quickSettings" || mediaHere);
        case "media":
            return mediaHere;
        case "mic":
        case "brightness":
            return panelHere && Ui.panel === "quickSettings";
        case "wifi":
        case "bluetooth":
            return !Config.osd.radios || Ui.panel === "quickSettings";
        case "profile":
            return !Config.osd.powerMode || Ui.panel === "battery";
        case "capslock":
        case "numlock":
        case "scrolllock":
            return !Config.osd.lockKeys;
        case "layout":
            return !Config.osd.layout;
        default:
            return false;
        }
    }

    function show(nextKind: string): void {
        showOn(nextKind, shown ? screen : "");
    }

    function showOn(nextKind: string, screenName: string): void {
        const target = Ui.resolveScreen(screenName);
        if (suppressed(nextKind, target))
            return;
        screen = target;
        kind = nextKind;
        shown = true;
        if (!held)
            hideTimer.restart();
    }

    function hide(): void {
        shown = false;
        pressed = false;
        hideTimer.stop();
        Brightness.refresh();
    }

    function observed(nextKind: string): void {
        if (Date.now() >= quietUntil)
            show(nextKind);
    }

    Connections {
        target: root.sink?.audio ?? null

        function onVolumesChanged(): void {
            root.observed("volume");
        }

        function onMutedChanged(): void {
            root.observed("volume");
        }
    }

    Connections {
        target: root.source?.audio ?? null

        function onVolumesChanged(): void {
            root.observed("mic");
        }

        function onMutedChanged(): void {
            root.observed("mic");
        }
    }

    Connections {
        target: Locks

        function onToggled(key: string): void {
            root.show(`${key}lock`);
        }
    }

    Connections {
        target: Niri

        function onLayoutIndexChanged(): void {
            if (Niri.layoutNames.length > 1)
                root.observed("layout");
        }
    }

    Connections {
        target: Radios

        function onBluetoothAdapterChanged(): void {
            root.quietUntil = Math.max(root.quietUntil, Date.now() + 1500);
        }

        function onWifiEnabledChanged(): void {
            root.observed("wifi");
        }

        function onBluetoothEnabledChanged(): void {
            root.observed("bluetooth");
        }
    }

    Connections {
        target: Power

        function onProfileChanged(): void {
            root.observed("profile");
        }
    }

    Connections {
        target: Ui

        function onPanelChanged(): void {
            if (root.shown && root.suppressed(root.kind, root.screen))
                root.hide();
        }

        function onDashboardTabChanged(): void {
            if (root.shown && root.suppressed(root.kind, root.screen))
                root.hide();
        }
    }

    Timer {
        id: hideTimer

        interval: Math.max(500, Config.osd.timeout)
        onTriggered: root.hide()
    }
}
