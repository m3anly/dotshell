pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.battery
import qs.dashboard
import qs.notifications
import qs.quicksettings
import qs.services
import qs.system
import qs.theme

PanelWindow {
    id: host

    required property ShellScreen output
    readonly property bool active: Ui.panel !== "" && Ui.screen === output.name

    screen: output
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Normal
    color: "transparent"
    visible: active || [systemPanel, quickSettings, batteryPanel, notificationCenter, dashboard].some(slot => slot.panel?.visible ?? false)
    mask: active ? null : passThrough
    WlrLayershell.namespace: "dotshell-panels"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    BackgroundEffect.blurRegion: Theme.blur ? blurRegion : null

    Region {
        id: passThrough
    }

    component PanelSlot: Loader {
        id: slot

        required property string name
        readonly property bool shown: host.active && Ui.panel === name
        readonly property Panel panel: item as Panel
        property bool held: false

        anchors.top: Theme.barAtBottom ? undefined : parent.top
        anchors.bottom: Theme.barAtBottom ? parent.bottom : undefined
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        active: shown || held
        onShownChanged: {
            if (shown)
                held = true;
        }
        onLoaded: panel.open = Qt.binding(() => slot.shown)

        Connections {
            target: slot.panel

            function onVisibleChanged(): void {
                if (!slot.panel.visible && !slot.shown)
                    slot.held = false;
            }
        }
    }

    component PanelRegion: TrackedRegion {
        required property PanelSlot slot

        target: slot.panel
        offset: slot.panel?.offset ?? 0
        radius: 18
    }

    Region {
        id: blurRegion

        PanelRegion {
            slot: systemPanel
        }

        PanelRegion {
            slot: quickSettings
        }

        PanelRegion {
            slot: batteryPanel
        }

        PanelRegion {
            slot: notificationCenter
        }

        PanelRegion {
            slot: dashboard
        }
    }

    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Ui.closeAll()
        Keys.onTabPressed: event => {
            event.accepted = Ui.panel === "dashboard" || Ui.panel === "system";
            if (event.accepted)
                Ui.stepTab(Ui.panel, 1);
        }
        Keys.onBacktabPressed: event => {
            event.accepted = Ui.panel === "dashboard" || Ui.panel === "system";
            if (event.accepted)
                Ui.stepTab(Ui.panel, -1);
        }

        MouseArea {
            anchors.fill: parent
            enabled: host.active
            acceptedButtons: Qt.AllButtons
            onPressed: Ui.closeAll()
        }

        PanelSlot {
            id: systemPanel

            name: "system"
            x: 6
            sourceComponent: Component {
                SystemPanel {}
            }
        }

        PanelSlot {
            id: quickSettings

            name: "quickSettings"
            anchors.right: parent.right
            anchors.rightMargin: 6
            sourceComponent: Component {
                QuickSettings {}
            }
        }

        PanelSlot {
            id: batteryPanel

            name: "battery"
            anchors.right: parent.right
            anchors.rightMargin: 6
            sourceComponent: Component {
                BatteryPanel {}
            }
        }

        PanelSlot {
            id: notificationCenter

            name: "notifications"
            anchors.right: parent.right
            anchors.rightMargin: 6
            sourceComponent: Component {
                NotificationCenter {}
            }
        }

        PanelSlot {
            id: dashboard

            name: "dashboard"
            anchors.horizontalCenter: parent.horizontalCenter
            sourceComponent: Component {
                Dashboard {}
            }
        }
    }
}
