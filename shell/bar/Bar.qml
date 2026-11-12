pragma ComponentBehavior: Bound

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
    readonly property real sideRoom: (content.width - center.width) / 2
    readonly property var leftShown: fit([
        {
            item: workspaces,
            wanted: true
        },
        {
            item: windowTitle,
            wanted: bar.shows("focusedWindow"),
            width: 80
        }
    ].concat(pluginBlocks(leftPlugins)), sideRoom - systemButton.implicitWidth)
    readonly property var rightShown: fit([
        {
            item: quickSettingsBay,
            wanted: bar.shows("quickSettings")
        },
        {
            item: notificationsBay,
            wanted: bar.shows("notifications")
        },
        {
            item: batteryBay,
            wanted: bar.shows("battery") && Power.present
        },
        {
            item: layoutBay,
            wanted: bar.shows("layout") && Niri.layoutNames.length > 1
        },
        {
            item: trayBay,
            wanted: bar.shows("tray") && SystemTray.items.values.length > 0
        }
    ].concat(pluginBlocks(rightPlugins)), sideRoom)
    WlrLayershell.layer: WlrLayer.Top
    BackgroundEffect.blurRegion: Theme.blur ? blurRegion : null

    function shows(key: string): bool {
        return Config.bar.show[key] && !Plugins.hiddenBarBlocks.includes(key);
    }

    function pluginBlocks(repeater: Repeater): var {
        return Array.from({
            length: repeater.count
        }, (_, index) => {
            const item = repeater.itemAt(index) as PluginItem;
            return {
                item,
                wanted: item?.modelData.barShown ?? false
            };
        });
    }

    function fit(blocks: var, room: real): var {
        let used = 0;
        return blocks.map(block => {
            const width = block.width ?? block.item?.implicitWidth ?? 0;
            if (!block.wanted || used + width > room)
                return false;
            used += width;
            return true;
        });
    }

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

        Item {
            anchors.fill: parent
            opacity: Plugins.barOpacity
            transform: Translate {
                x: Plugins.barShift.x
                y: Plugins.barShift.y
            }

            RowLayout {
                id: left

                anchors.left: parent.left
                width: (parent.width - center.width) / 2
                height: parent.height
                spacing: 0

                SystemButton {
                    id: systemButton

                    screenName: bar.screen?.name ?? ""
                }

                Workspaces {
                    id: workspaces

                    visible: bar.leftShown[0]
                    output: bar.screen?.name ?? ""
                }

                WindowTitle {
                    id: windowTitle

                    visible: bar.leftShown[1]
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                }

                Repeater {
                    id: leftPlugins

                    model: Plugins.barItems("left")

                    PluginItem {
                        visible: bar.leftShown[2 + index] ?? false
                        screenName: bar.screen?.name ?? ""
                    }
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
                    id: trayBay

                    visible: bar.rightShown[4]
                    spacing: 14

                    Repeater {
                        model: SystemTray.items

                        TrayButton {}
                    }
                }

                KeyboardLayout {
                    id: layoutBay

                    visible: bar.rightShown[3]
                }

                Repeater {
                    id: rightPlugins

                    model: Plugins.barItems("right")

                    PluginItem {
                        visible: bar.rightShown[5 + index] ?? false
                        screenName: bar.screen?.name ?? ""
                    }
                }

                Battery {
                    id: batteryBay

                    visible: bar.rightShown[2]
                    screenName: bar.screen?.name ?? ""
                }

                NotificationButton {
                    id: notificationsBay

                    visible: bar.rightShown[1]
                    screenName: bar.screen?.name ?? ""
                }

                QuickSettingsButton {
                    id: quickSettingsBay

                    visible: bar.rightShown[0]
                    screenName: bar.screen?.name ?? ""
                }
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
            opacity: Plugins.barLineOpacity
        }
    }
}
