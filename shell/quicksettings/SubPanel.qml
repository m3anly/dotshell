pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services
import qs.theme

Item {
    id: root

    property string kind: ""
    property string shownKind: ""
    readonly property bool open: kind !== ""
    property real openness: 0
    readonly property bool isWifi: shownKind === "wifi"
    readonly property bool scanning: isWifi ? Radios.wifiScanning : Radios.discovering
    readonly property string note: {
        if (isWifi) {
            if (!Radios.wifiEnabled)
                return "Wi-Fi is off · tap the round icon";
            return Radios.wifiNetworks.length === 0 ? "Searching for networks" : "";
        }
        if (!Radios.bluetoothEnabled)
            return "Bluetooth is off · tap the round icon";
        return Radios.bluetoothDevices.length === 0 ? "No devices · scan to add one" : "";
    }
    readonly property real maxListHeight: 300
    readonly property ListView activeList: isWifi ? wifiList : deviceList
    readonly property real targetListHeight: note !== "" ? noteLabel.implicitHeight : activeList.height
    property real listHeight: targetListHeight
    property real rowResizedAt: 0
    property var passwordNetwork: null

    implicitHeight: Math.round((card.height + 12) * openness)
    visible: openness > 0
    clip: true

    onKindChanged: {
        if (kind !== "")
            shownKind = kind;
        else
            passwordNetwork = null;
    }

    states: State {
        name: "open"
        when: root.open

        PropertyChanges {
            root.openness: 1
        }
    }

    transitions: [
        Transition {
            to: "open"
            enabled: !Motion.reduced

            Expand {
                property: "openness"
            }
        },
        Transition {
            from: "open"
            enabled: !Motion.reduced

            Exit {
                property: "openness"
                duration: 220
            }
        }
    ]

    Behavior on listHeight {
        enabled: !Motion.reduced && root.openness === 1

        SpatialStandard {}
    }

    component RowList: ListView {
        width: parent?.width ?? 0
        height: Math.min(contentHeight, root.maxListHeight)
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        spacing: 4
    }

    component RowSlot: Item {
        id: slot

        required property int index
        default property alias content: body.data
        property bool placed: false
        property real lastY: 0

        width: ListView.view?.width ?? 0
        implicitHeight: body.childrenRect.height
        height: implicitHeight
        onImplicitHeightChanged: {
            if (placed)
                root.rowResizedAt = Date.now();
        }
        onYChanged: {
            const delta = lastY - y;
            lastY = y;
            if (!placed || delta === 0 || Motion.reduced || Date.now() - root.rowResizedAt < 100)
                return;
            flip.y += delta;
            glide.restart();
        }
        ListView.onAdd: {
            if (Motion.reduced)
                return;
            body.opacity = 0;
            body.scale = 0.96;
            enter.restart();
        }

        Timer {
            running: true
            interval: 0
            onTriggered: {
                slot.lastY = slot.y;
                slot.placed = true;
            }
        }

        SpatialStandard {
            id: glide

            target: flip
            property: "y"
            to: 0
        }

        SequentialAnimation {
            id: enter

            PauseAnimation {
                duration: Math.max(0, Math.min(slot.index, 9)) * 30
            }
            ParallelAnimation {
                Effects {
                    target: body
                    property: "opacity"
                    to: 1
                }
                SpatialStandard {
                    target: body
                    property: "scale"
                    to: 1
                    epsilon: 0.002
                }
            }
        }

        Item {
            id: body

            width: parent.width
            transform: Translate {
                id: flip
            }
        }
    }

    Rectangle {
        id: card

        y: 12
        width: parent.width
        height: column.implicitHeight + 20
        radius: 16
        topLeftRadius: 6
        topRightRadius: 6
        color: Qt.rgba(1, 1, 1, 0.05)
        border.width: 1
        border.color: Theme.line
        antialiasing: true

        ColumnLayout {
            id: column

            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                Layout.topMargin: 2
                Layout.bottomMargin: 4
                Layout.preferredHeight: 30

                RollText {
                    Layout.fillWidth: true
                    text: root.isWifi ? "Wi-Fi networks" : "Bluetooth devices"
                    direction: root.isWifi ? -1 : 1
                }

                MorphButton {
                    visible: root.isWifi ? Radios.wifiEnabled : Radios.bluetoothEnabled
                    implicitWidth: scanRow.implicitWidth + 24
                    implicitHeight: 30
                    restRadius: 15
                    pressRadius: 6
                    pressScale: 0.92
                    hoverColor: Theme.hover
                    onClicked: root.isWifi ? Radios.scanWifi() : Radios.scanBluetooth()

                    Row {
                        id: scanRow

                        anchors.centerIn: parent
                        spacing: 8

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 14

                            DotIcon {
                                anchors.centerIn: parent
                                visible: !root.scanning
                                name: "reboot"
                            }

                            LoadingDots {
                                anchors.centerIn: parent
                                visible: root.scanning
                            }
                        }

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Scan"
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.listHeight
                clip: true

                Label {
                    id: noteLabel

                    width: parent.width
                    visible: root.note !== ""
                    topPadding: 18
                    bottomPadding: 18
                    leftPadding: 8
                    rightPadding: 8
                    text: root.note
                    color: Theme.fg2
                    pixelSize: 12
                    tracking: 0.08
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                RowList {
                    id: wifiList

                    visible: root.isWifi && root.note === ""
                    model: ScriptModel {
                        values: root.isWifi && Radios.wifiEnabled ? Radios.wifiNetworks : []
                    }
                    delegate: RowSlot {
                        id: networkSlot

                        required property var modelData

                        NetworkRow {
                            modelData: networkSlot.modelData
                            passwordOwner: root.passwordNetwork
                            onPasswordOpened: root.passwordNetwork = networkSlot.modelData
                        }
                    }
                }

                RowList {
                    id: deviceList

                    visible: !root.isWifi && root.note === ""
                    model: ScriptModel {
                        values: !root.isWifi && Radios.bluetoothEnabled ? Radios.bluetoothDevices : []
                    }
                    delegate: RowSlot {
                        id: deviceSlot

                        required property var modelData

                        DeviceRow {
                            modelData: deviceSlot.modelData
                        }
                    }
                }
            }
        }
    }
}
