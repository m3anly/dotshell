import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import qs.config
import qs.services
import qs.theme

PanelWindow {
    id: bar

    anchors {
        top: !Theme.barAtBottom
        bottom: Theme.barAtBottom
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight
    color: Theme.glass(Theme.tintBar)
    WlrLayershell.namespace: "dotshell-bar"
    WlrLayershell.layer: WlrLayer.Top
    BackgroundEffect.blurRegion: Theme.blur ? blurRegion : null

    Region {
        id: blurRegion

        item: content
    }

    Item {
        id: content

        anchors.fill: parent

        BarScroll {
            anchors.fill: parent
            z: -1
            output: bar.screen?.name ?? ""
        }

        RowLayout {
            id: left

            anchors.left: parent.left
            width: (parent.width - center.width) / 2
            height: parent.height
            spacing: 0

            SystemButton {
                screenName: bar.screen?.name ?? ""
            }

            Workspaces {
                output: bar.screen?.name ?? ""
            }

            WindowTitle {
                visible: Config.bar.show.focusedWindow
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }
        }

        Row {
            id: center

            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height

            DashboardButton {
                screenName: bar.screen?.name ?? ""
            }
        }

        Row {
            id: right

            anchors.right: parent.right
            height: parent.height

            Bay {
                visible: Config.bar.show.tray && SystemTray.items.values.length > 0
                spacing: 14

                Repeater {
                    model: SystemTray.items

                    TrayButton {}
                }
            }

            KeyboardLayout {
                visible: Config.bar.show.layout && Niri.layoutNames.length > 1
            }

            Battery {
                visible: Config.bar.show.battery && Power.present
                screenName: bar.screen?.name ?? ""
            }

            NotificationButton {
                visible: Config.bar.show.notifications
                screenName: bar.screen?.name ?? ""
            }

            QuickSettingsButton {
                visible: Config.bar.show.quickSettings
                screenName: bar.screen?.name ?? ""
            }
        }

        EdgeScroll {
            anchors.left: parent.left
            height: parent.height
            enabled: Config.bar.edgeScroll && Brightness.available
            stepSize: Config.brightness.step
            onStepped: step => {
                Brightness.change(step);
                Osd.showOn("brightness", bar.screen?.name ?? "");
            }
        }

        EdgeScroll {
            anchors.right: parent.right
            height: parent.height
            enabled: Config.bar.edgeScroll
            stepSize: Config.audio.step
            onStepped: step => {
                Audio.changeVolume(step);
                Osd.showOn("volume", bar.screen?.name ?? "");
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: Theme.barAtBottom ? parent.top : undefined
            anchors.bottom: Theme.barAtBottom ? undefined : parent.bottom
            height: 1
            color: Theme.line
        }
    }
}
