pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services
import qs.theme

FloatingWindow {
    id: window

    readonly property var sections: catalog.list
    readonly property int current: Math.max(0, sections.findIndex(section => section.id === Ui.settingsSection))
    property int previous: current
    property int direction: 1

    title: "Dotshell Settings"
    implicitWidth: 912
    implicitHeight: 672
    minimumSize: Qt.size(640, list.y + list.height + 16 + footer.implicitHeight + 20)
    color: "transparent"
    BackgroundEffect.blurRegion: Theme.blur ? blurRegion : null
    onVisibleChanged: {
        if (!visible)
            Ui.settingsOpen = false;
    }
    onCurrentChanged: {
        direction = current >= previous ? 1 : -1;
        previous = current;
        scroller.contentY = 0;
    }

    function select(index: int): void {
        const clamped = Math.max(0, Math.min(sections.length - 1, index));
        Ui.settingsSection = sections[clamped].id;
    }

    Sections {
        id: catalog
    }

    Region {
        id: blurRegion

        width: 16384
        height: 16384
    }

    Rectangle {
        id: surface

        anchors.fill: parent
        radius: 18
        color: Theme.glass(Theme.tintPanel)
        border.width: 1
        border.color: Theme.line
        antialiasing: true

        FocusScope {
            id: keys

            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: Ui.settingsOpen = false
            Keys.onUpPressed: event => {
                if (keys.Window.activeFocusItem === keys)
                    window.select(window.current - 1);
            }
            Keys.onDownPressed: event => {
                if (keys.Window.activeFocusItem === keys)
                    window.select(window.current + 1);
            }

            MouseArea {
                anchors.fill: parent
                onPressed: keys.forceActiveFocus()
            }

            Item {
                id: sidebar

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 216

                Column {
                    x: 20
                    y: 22
                    spacing: 4

                    Label {
                        text: "Settings"
                    }

                    Label {
                        text: "Dotshell"
                        pixelSize: 10
                        color: Theme.fg3
                    }
                }

                Item {
                    id: list

                    x: 10
                    y: 78
                    width: parent.width - 20
                    height: window.sections.length * 42

                    Rectangle {
                        id: highlight

                        width: parent.width
                        height: 40
                        y: window.current * 42
                        radius: 12
                        color: Theme.fill
                        border.width: 1
                        border.color: Theme.line
                        antialiasing: true

                        Behavior on y {
                            enabled: !Motion.reduced

                            SpatialFast {}
                        }

                        Rectangle {
                            x: 14
                            anchors.verticalCenter: parent.verticalCenter
                            width: 6
                            height: 6
                            radius: 3
                            color: Theme.red
                        }
                    }

                    Repeater {
                        model: window.sections

                        Item {
                            id: entry

                            required property var modelData
                            required property int index
                            readonly property bool selected: index === window.current

                            y: index * 42
                            width: list.width
                            height: 40

                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: mouse.containsMouse && !entry.selected ? Theme.hover : "transparent"

                                Behavior on color {
                                    EffectsColor {}
                                }
                            }

                            Label {
                                x: entry.selected ? 32 : 18
                                anchors.verticalCenter: parent.verticalCenter
                                text: entry.modelData.title
                                pixelSize: 12
                                color: entry.selected ? Theme.fg : Theme.fg2

                                Behavior on x {
                                    enabled: !Motion.reduced

                                    SpatialFast {}
                                }
                                Behavior on color {
                                    EffectsColor {}
                                }
                            }

                            MouseArea {
                                id: mouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    keys.forceActiveFocus();
                                    window.select(entry.index);
                                }
                            }
                        }
                    }
                }

                Text {
                    id: footer

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 20
                    text: `Saved to ${Config.userPath.replace(Quickshell.env("HOME"), "~")}`
                    font.family: Theme.uiFont
                    font.pixelSize: 10
                    color: Theme.fg3
                    wrapMode: Text.WrapAnywhere
                    textFormat: Text.PlainText
                }
            }

            DottedLine {
                anchors.left: sidebar.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: 18
                anchors.bottomMargin: 18
            }

            Item {
                id: content

                anchors.left: sidebar.right
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.leftMargin: 2

                Column {
                    id: heading

                    x: 28
                    y: 22
                    width: parent.width - 56
                    spacing: 4

                    RollText {
                        width: parent.width
                        text: window.sections[window.current].title
                        direction: window.direction
                    }

                    RollText {
                        width: parent.width
                        text: window.sections[window.current].blurb
                        direction: window.direction
                        uppercase: false
                        pixelSize: 11
                        color: Theme.fg2
                    }
                }

                Flickable {
                    id: scroller

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: heading.bottom
                    anchors.bottom: parent.bottom
                    anchors.topMargin: 10
                    anchors.leftMargin: 28
                    anchors.rightMargin: 28
                    contentWidth: width
                    contentHeight: page.implicitHeight + 20
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: contentHeight > height

                    Loader {
                        id: page

                        width: scroller.width
                        sourceComponent: window.sections[window.current].page
                    }
                }

                MouseArea {
                    id: scrollTrack

                    readonly property real range: Math.max(1, scroller.contentHeight - scroller.height)
                    readonly property real thumbHeight: Math.max(24, scroller.visibleArea.heightRatio * height)
                    readonly property real thumbY: Math.max(0, Math.min(1, scroller.contentY / range)) * (height - thumbHeight)
                    property real grab: 0

                    function scrollTo(top: real): void {
                        const travel = height - thumbHeight;
                        scroller.contentY = (travel > 0 ? Math.max(0, Math.min(1, top / travel)) : 0) * range;
                    }

                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    y: scroller.y
                    width: 16
                    height: scroller.height
                    visible: scroller.contentHeight > scroller.height
                    hoverEnabled: true
                    preventStealing: true
                    onPressed: mouse => {
                        grab = mouse.y >= thumbY && mouse.y <= thumbY + thumbHeight ? mouse.y - thumbY : thumbHeight / 2;
                        scrollTo(mouse.y - grab);
                    }
                    onPositionChanged: mouse => {
                        if (pressed)
                            scrollTo(mouse.y - grab);
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        y: scrollTrack.thumbY
                        width: scrollTrack.containsMouse || scrollTrack.pressed ? 6 : 3
                        height: scrollTrack.thumbHeight
                        radius: width / 2
                        color: scrollTrack.pressed ? Theme.fg : scrollTrack.containsMouse ? Theme.fg2 : Theme.fg3

                        Behavior on width {
                            Effects {}
                        }

                        Behavior on color {
                            EffectsColor {}
                        }
                    }
                }
            }
        }
    }
}
