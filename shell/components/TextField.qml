import QtQuick
import qs.components
import qs.theme

Rectangle {
    id: root

    property string text
    property string placeholder
    property bool valid: true
    property bool controlled: true
    readonly property alias input: input
    readonly property alias editing: input.activeFocus

    signal committed(string text)

    implicitWidth: 260
    implicitHeight: 40
    radius: input.activeFocus ? 12 : 20
    color: Theme.fill
    border.width: 1
    border.color: !valid ? Theme.red : input.activeFocus ? Theme.fg2 : Theme.line
    antialiasing: true

    function commit(): void {
        if (input.text !== root.text)
            root.committed(input.text);
    }

    Behavior on radius {
        enabled: !Motion.reduced

        SpatialStandard {}
    }
    Behavior on border.color {
        EffectsColor {}
    }

    Binding {
        target: input
        property: "text"
        value: root.text
        when: root.controlled && !input.activeFocus
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onPressed: event => {
            input.forceActiveFocus();
            event.accepted = false;
        }
    }

    TextInput {
        id: input

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        font.family: Theme.uiFont
        font.pixelSize: 13
        color: Theme.fg
        selectionColor: Theme.fg2
        selectByMouse: true
        clip: true
        onEditingFinished: root.commit()
        Keys.onEscapePressed: event => {
            input.text = root.text;
            input.focus = false;
            event.accepted = true;
        }

        Body {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            visible: input.text === "" && !input.activeFocus
            text: root.placeholder
            color: Theme.fg3
        }
    }
}
