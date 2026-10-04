pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.theme

Rectangle {
    id: root

    property bool open: false
    property bool live: false
    property bool stagger: false
    property bool settled: false
    readonly property bool searching: Ui.launcherMode !== "clipboard"
    readonly property LauncherList list: searching ? searchView.list : clipboardView.list
    readonly property var current: list.current
    readonly property real targetBodyHeight: searching ? searchView.implicitHeight : clipboardView.implicitHeight
    property real bodyHeight: targetBodyHeight
    readonly property var leftHints: {
        if (searching) {
            const hints = [["↑↓", "Move", "", false]];
            if (current)
                hints.push(["↵", searchView.primaryLabel, "go", true]);
            return hints;
        }
        if (!current)
            return [];
        return [["↵", "Paste", "go", true], ["⇧↵", "Copy", "copy", false], ["Ctrl P", current.entry.pinned ? "Unpin" : "Pin", "pin", false], ["Ctrl ⌫", "Delete", "delete", false]];
    }
    readonly property var rightHints: searching ? [["Tab", "Clipboard", "tab", false], ["Esc", "Close", "close", false]] : [["Tab", "Search", "tab", false]]

    width: 760
    height: column.implicitHeight
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

    onOpenChanged: {
        if (!open) {
            settled = false;
            return;
        }
        input.text = "";
        live = true;
        stagger = !Motion.reduced;
        staggerEnd.restart();
        settle.restart();
        focusDelay.restart();
        searchView.list.reset();
        clipboardView.list.reset();
    }
    onVisibleChanged: {
        if (!visible)
            live = false;
    }

    function switchMode(): void {
        Ui.setLauncherMode(searching ? "clipboard" : "search");
    }

    function trigger(action: string): void {
        switch (action) {
        case "go":
            list.activate(false);
            break;
        case "copy":
            list.activate(true);
            break;
        case "pin":
            clipboardView.togglePin();
            break;
        case "delete":
            clipboardView.removeSelected();
            break;
        case "tab":
            switchMode();
            break;
        case "close":
            Ui.closeAll();
            break;
        }
        input.forceActiveFocus();
    }

    function handleKey(event: var): void {
        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
        const shiftHeld = (event.modifiers & Qt.ShiftModifier) !== 0;
        switch (event.key) {
        case Qt.Key_Escape:
            Ui.closeAll();
            break;
        case Qt.Key_Tab:
        case Qt.Key_Backtab:
            switchMode();
            break;
        case Qt.Key_Down:
            list.moveVertical(1);
            break;
        case Qt.Key_Up:
            list.moveVertical(-1);
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            list.activate(shiftHeld);
            break;
        case Qt.Key_P:
            if (searching || !ctrl) {
                event.accepted = false;
                return;
            }
            clipboardView.togglePin();
            break;
        case Qt.Key_Backspace:
            if (searching || !ctrl) {
                event.accepted = false;
                return;
            }
            clipboardView.removeSelected();
            break;
        case Qt.Key_Delete:
            if (searching || input.text !== "") {
                event.accepted = false;
                return;
            }
            clipboardView.removeSelected();
            break;
        default:
            event.accepted = false;
            return;
        }
        event.accepted = true;
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
                    duration: 140
                }
                Exit {
                    properties: "scale,y"
                    duration: 180
                }
            }
        }
    ]

    Behavior on bodyHeight {
        enabled: !Motion.reduced && root.settled

        SpatialStandard {}
    }

    Timer {
        id: staggerEnd

        interval: 400
        onTriggered: root.stagger = false
    }

    Timer {
        id: settle

        interval: 80
        onTriggered: root.settled = root.open
    }

    Timer {
        id: focusDelay

        interval: 30
        onTriggered: input.forceActiveFocus()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }

    ColumnLayout {
        id: column

        width: parent.width
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 66

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 22
                anchors.rightMargin: 14
                spacing: 14

                DotIcon {
                    size: 18
                    name: root.searching ? "search" : "clip"
                    color: Theme.fg2
                }

                TextInput {
                    id: input

                    Layout.fillWidth: true
                    font.family: Theme.uiFont
                    font.pixelSize: 20
                    color: Theme.fg
                    selectionColor: Theme.fg2
                    selectedTextColor: Theme.glassBase
                    clip: true
                    Keys.onPressed: event => root.handleKey(event)

                    Body {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        visible: input.text === ""
                        text: root.searching ? "Search apps, calculate, find in clipboard" : "Filter clipboard history"
                        color: Theme.fg3
                        font.pixelSize: 20
                    }
                }

                ModeSwitch {
                    mode: Ui.launcherMode
                    animate: root.settled
                    onPicked: mode => {
                        Ui.setLauncherMode(mode);
                        input.forceActiveFocus();
                    }
                }
            }
        }

        DottedLine {
            Layout.fillWidth: true
            vertical: false
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.bodyHeight
            clip: true

            SearchView {
                id: searchView

                width: parent.width
                height: implicitHeight
                active: root.searching
                animateEnter: root.settled
                live: root.live
                stagger: root.stagger
                query: input.text
            }

            ClipboardView {
                id: clipboardView

                width: parent.width
                height: implicitHeight
                active: !root.searching
                animateEnter: root.settled
                live: root.live
                stagger: root.stagger
                query: input.text
            }
        }

        DottedLine {
            Layout.fillWidth: true
            vertical: false
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(46, hints.implicitHeight + 16)

            RowLayout {
                id: hints

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Repeater {
                    model: root.leftHints

                    KeyHint {
                        required property var modelData

                        keys: modelData[0]
                        label: modelData[1]
                        action: modelData[2]
                        primary: modelData[3]
                        onTriggered: action => root.trigger(action)
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Repeater {
                    model: root.rightHints

                    KeyHint {
                        required property var modelData

                        keys: modelData[0]
                        label: modelData[1]
                        action: modelData[2]
                        primary: modelData[3]
                        onTriggered: action => root.trigger(action)
                    }
                }
            }
        }
    }
}
