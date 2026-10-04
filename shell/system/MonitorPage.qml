pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.theme

TabPage {
    id: root

    readonly property real networkPeak: Math.max(64 * 1024, ...Sysmon.networkHistory)

    tab: "monitor"
    group: "system"
    implicitHeight: layout.implicitHeight

    function bytes(value: real): string {
        const units = ["B", "KB", "MB", "GB", "TB"];
        let index = 0;
        while (value >= 1024 && index < units.length - 1) {
            value /= 1024;
            index++;
        }
        return `${value < 10 && index > 0 ? value.toFixed(1) : Math.round(value)} ${units[index]}`;
    }

    function split(text: string): var {
        const space = text.indexOf(" ");
        return [text.slice(0, space), text.slice(space + 1)];
    }

    function processName(name: string): string {
        if (!name.startsWith("."))
            return name;
        const bare = name.slice(1);
        const suffix = "-wrapped";
        for (let length = suffix.length; length >= 2; length--) {
            if (bare.endsWith(suffix.slice(0, length)))
                return bare.slice(0, -length);
        }
        return bare;
    }

    function percent(value: real): string {
        return String(Math.round(value * 100));
    }

    function detail(parts: var): string {
        return parts.filter(part => part !== "").join(" · ");
    }

    function temperature(milli: real): string {
        const value = Sysmon.celsius(milli);
        return value < 0 ? "" : `${value}°`;
    }

    component MeterTile: Rectangle {
        id: tile

        property string heading
        property string value
        property string unit
        property string detail
        property var history: []

        implicitHeight: 132
        radius: 16
        color: Theme.fill
        border.width: 1
        border.color: Theme.line
        antialiasing: true

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 14
            text: tile.heading
            pixelSize: 10
            color: Theme.fg2
        }

        Label {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            text: tile.detail
            pixelSize: 10
            color: Theme.fg3
        }

        Row {
            x: 14
            y: 30
            spacing: 6

            DisplayText {
                id: number

                text: Sysmon.ready ? tile.value : "–"
                font.pixelSize: 36
            }

            Label {
                anchors.baseline: number.baseline
                text: tile.unit
                pixelSize: 11
                color: Theme.fg2
            }
        }

        DotChart {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 14
            height: 40
            values: tile.history
        }
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 8
            rowSpacing: 8

            MeterTile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                heading: "CPU"
                value: root.percent(Sysmon.cpu)
                unit: "%"
                detail: root.detail([root.temperature(Sysmon.sample?.cpuTemp ?? -1), (Sysmon.sample?.freq ?? -1) > 0 ? `${(Sysmon.sample.freq / 1000).toFixed(1)} GHz` : ""])
                history: Sysmon.cpuHistory
            }

            MeterTile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                heading: "Memory"
                value: root.percent(Sysmon.memory)
                unit: "%"
                detail: root.detail([`${root.bytes(Sysmon.memoryUsed)} of ${root.bytes(Sysmon.memoryTotal)}`, Sysmon.swapUsed >= 1024 * 1024 ? `swap ${root.bytes(Sysmon.swapUsed)}` : ""])
                history: Sysmon.memoryHistory
            }

            MeterTile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                visible: Sysmon.hasGpu || !Sysmon.ready
                heading: "GPU"
                value: root.percent(Sysmon.gpu)
                unit: "%"
                detail: root.detail([root.temperature(Sysmon.sample?.gpuTemp ?? -1), (Sysmon.sample?.vramUsed ?? -1) >= 0 ? `VRAM ${root.bytes(Sysmon.sample.vramUsed)}` : ""])
                history: Sysmon.gpuHistory
            }

            MeterTile {
                readonly property var down: root.split(root.bytes(Math.max(0, Sysmon.sample?.rx ?? 0)))

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.columnSpan: Sysmon.hasGpu || !Sysmon.ready ? 1 : 2
                heading: "Network"
                value: down[0]
                unit: `${down[1]}/s in`
                detail: `out ${root.bytes(Math.max(0, Sysmon.sample?.tx ?? 0))}/s`
                history: Sysmon.networkHistory.map(rate => rate / root.networkPeak)
            }
        }

        RowLayout {
            readonly property real used: Sysmon.sample?.diskUsed ?? -1
            readonly property real size: Sysmon.sample?.diskSize ?? -1
            readonly property int lit: size > 0 ? Math.max(1, Math.round(used / size * 30)) : 0

            id: disk

            Layout.fillWidth: true
            Layout.topMargin: 6
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 12

            Label {
                text: "Disk /"
                pixelSize: 10
                color: Theme.fg2
            }

            Row {
                Layout.fillWidth: true
                spacing: 3

                Repeater {
                    model: 30

                    Rectangle {
                        required property int index

                        anchors.verticalCenter: parent.verticalCenter
                        width: 6
                        height: 6
                        radius: 3
                        antialiasing: true
                        color: index + 1 === disk.lit ? Theme.red : index < disk.lit ? Theme.fg2 : Theme.off
                    }
                }
            }

            Label {
                text: disk.size > 0 ? `${root.bytes(disk.used)} of ${root.bytes(disk.size)}` : ""
                pixelSize: 10
                color: Theme.fg3
            }
        }

        DottedLine {
            Layout.fillWidth: true
            Layout.topMargin: 6
            vertical: false
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 0

            Label {
                Layout.fillWidth: true
                text: "Processes"
                pixelSize: 10
                color: Theme.fg2
            }

            Label {
                Layout.preferredWidth: 72
                horizontalAlignment: Text.AlignRight
                text: "CPU"
                pixelSize: 10
                color: Theme.fg2
            }

            Label {
                Layout.preferredWidth: 84
                horizontalAlignment: Text.AlignRight
                text: "Memory"
                pixelSize: 10
                color: Theme.fg2
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 5 * 28

            LoadingDots {
                anchors.centerIn: parent
                visible: Sysmon.processes.length === 0
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right

                Repeater {
                    model: Sysmon.processes

                    RowLayout {
                        id: process

                        required property var modelData
                        required property int index

                        width: parent.width
                        height: 28
                        spacing: 0

                        Rectangle {
                            Layout.leftMargin: 4
                            Layout.rightMargin: 10
                            Layout.preferredWidth: 6
                            Layout.preferredHeight: 6
                            radius: 3
                            antialiasing: true
                            color: process.index === 0 ? Theme.red : Theme.fg3
                        }

                        Body {
                            Layout.fillWidth: true
                            text: root.processName(process.modelData.name)
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }

                        Body {
                            Layout.preferredWidth: 72
                            horizontalAlignment: Text.AlignRight
                            text: `${(process.modelData.cpu * 100).toFixed(1)}%`
                            font.pixelSize: 13
                            color: Theme.fg2
                        }

                        Body {
                            Layout.preferredWidth: 84
                            Layout.rightMargin: 4
                            horizontalAlignment: Text.AlignRight
                            text: root.bytes(process.modelData.memory)
                            font.pixelSize: 13
                            color: Theme.fg2
                        }
                    }
                }
            }
        }
    }
}
