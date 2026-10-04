pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.theme
import "Binds.js" as Binds

Rectangle {
    id: root

    property bool open: false
    property real maxHeight: 800
    property string query: ""
    readonly property int columnCount: width > 900 ? 3 : 2
    readonly property var groups: Binds.grouped(Keybinds.binds, query)
    readonly property var columns: Binds.columns(groups, columnCount)
    readonly property int shownCount: groups.reduce((sum, group) => sum + group.rows.length, 0)

    height: Math.min(maxHeight, layout.implicitHeight + layout.anchors.margins * 2)
    radius: 24
    color: Theme.glass(Theme.tintLauncher)
    border.width: 1
    border.color: Theme.line
    antialiasing: true
    visible: opacity > 0
    opacity: 0
    scale: 0.94
    readonly property alias offset: shift.y

    transform: Translate {
        id: shift

        y: -18
    }

    Behavior on height {
        enabled: !Motion.reduced && root.open

        SpatialStandard {}
    }

    Keys.onEscapePressed: Ui.closeAll()
    onQueryChanged: body.contentY = 0
    onOpenChanged: {
        if (!open)
            return;
        Keybinds.reload();
        search.text = "";
        body.contentY = 0;
        focusDelay.restart();
    }

    states: State {
        name: "open"
        when: root.open

        PropertyChanges {
            root.opacity: 1
            root.scale: 1
            shift.y: 0
        }
    }

    transitions: [
        Transition {
            to: "open"
            enabled: !Motion.reduced

            ParallelAnimation {
                Effects {
                    property: "opacity"
                }
                SpatialStandard {
                    property: "scale"
                    epsilon: 0.002
                }
                SpatialStandard {
                    target: shift
                    property: "y"
                }
            }
        },
        Transition {
            from: "open"
            enabled: !Motion.reduced

            ParallelAnimation {
                Exit {
                    property: "opacity"
                    duration: 150
                }
                Exit {
                    properties: "scale,y"
                    duration: 180
                }
            }
        }
    ]

    Timer {
        id: focusDelay

        interval: 60
        onTriggered: search.input.forceActiveFocus()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }

    component Keycap: Rectangle {
        id: cap

        required property string modelData

        implicitWidth: Math.max(22, capLabel.implicitWidth + 12)
        implicitHeight: 22
        radius: 6
        color: Theme.fill
        border.width: 1
        border.color: Theme.line

        Label {
            id: capLabel

            anchors.centerIn: parent
            text: cap.modelData
            pixelSize: 11
            tracking: 0.04
        }
    }

    component Group: Column {
        id: group

        required property var modelData
        required property int index
        property int order: 0

        spacing: 2

        Label {
            text: group.modelData.continued ? `${group.modelData.name} · cont.` : group.modelData.name
            color: group.modelData.continued ? Theme.fg3 : Theme.fg2
            pixelSize: 11
            bottomPadding: 6
        }

        Repeater {
            model: group.modelData.rows

            Item {
                id: row

                required property var modelData

                width: group.width
                height: 30

                Body {
                    anchors.left: parent.left
                    anchors.right: caps.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.title
                }

                Row {
                    id: caps

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Repeater {
                        model: row.modelData.keys

                        Keycap {}
                    }
                }
            }
        }
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        RowLayout {
            id: header

            Layout.fillWidth: true
            spacing: 12

            Label {
                text: "Keybinds"
            }

            RollText {
                Layout.fillWidth: true
                text: String(root.shownCount)
                color: Theme.fg2
            }

            SearchField {
                id: search

                Layout.preferredWidth: 300
                placeholder: "Filter"
                onTextChanged: root.query = text
            }
        }

        DottedLine {
            Layout.fillWidth: true
            vertical: false
        }

        Flickable {
            id: body

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: contentHeight
            contentHeight: Math.max(columnsRow.implicitHeight, empty.visible ? empty.implicitHeight : 0)
            clip: true
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds

            Row {
                id: columnsRow

                width: body.width
                spacing: 32

                Repeater {
                    model: root.columns

                    Column {
                        id: column

                        required property var modelData
                        required property int index

                        width: (columnsRow.width - columnsRow.spacing * (root.columnCount - 1)) / root.columnCount
                        spacing: 22

                        Repeater {
                            model: column.modelData

                            Reveal {
                                id: reveal

                                required property var modelData
                                required property int index

                                width: column.width
                                implicitHeight: block.implicitHeight
                                shown: root.open
                                order: column.index + reveal.index * root.columnCount

                                Group {
                                    id: block

                                    width: parent.width
                                    modelData: reveal.modelData
                                    index: reveal.index
                                }
                            }
                        }
                    }
                }
            }

            Body {
                id: empty

                width: body.width
                visible: root.shownCount === 0
                topPadding: 24
                bottomPadding: 24
                horizontalAlignment: Text.AlignHCenter
                text: Keybinds.binds.length === 0 ? "No keybinds found in the niri config" : `No keybinds match "${root.query}"`
                color: Theme.fg2
            }
        }
    }
}
