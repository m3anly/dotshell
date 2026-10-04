pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.theme

Rectangle {
    id: root

    property real value
    property real from: 0
    property real to: 100
    property real step: 1
    property string unit
    property string zeroText
    readonly property string display: value === 0 && zeroText !== "" ? zeroText : unit !== "" ? `${value} ${unit}` : String(value)

    signal moved(real value)

    function commit(candidate: real): void {
        if (isNaN(candidate))
            return;
        const clamped = Math.max(from, Math.min(to, Math.round(candidate / step) * step));
        if (clamped !== value)
            moved(clamped);
    }

    implicitWidth: Math.max(176, Math.ceil(zeroMetrics.advanceWidth) + 2 * (minus.x + minus.width) + 16)
    implicitHeight: 36
    radius: input.activeFocus ? 12 : 18
    color: Theme.fill
    border.width: 1
    border.color: input.activeFocus ? Theme.fg2 : Theme.line
    antialiasing: true

    Behavior on radius {
        enabled: !Motion.reduced

        SpatialStandard {}
    }
    Behavior on border.color {
        EffectsColor {}
    }

    component StepButton: MorphButton {
        id: button

        required property int direction
        required property string sign

        y: 3
        width: 30
        height: 30
        restRadius: 15
        pressRadius: 8
        pressScale: 0.88
        restColor: "transparent"
        hoverColor: Theme.hover
        outline: "transparent"
        enabled: direction < 0 ? root.value > root.from : root.value < root.to
        opacity: enabled ? 1 : 0.35
        onClicked: root.commit(root.value + direction * root.step)
        onPressStarted: repeat.restart()
        onPressEnded: repeat.stop()

        Label {
            anchors.centerIn: parent
            text: button.sign
            pixelSize: 15
            color: Theme.fg2
        }

        Timer {
            id: repeat

            interval: 420
            repeat: true
            onTriggered: {
                interval = 70;
                root.commit(root.value + button.direction * root.step);
            }
            onRunningChanged: {
                if (!running)
                    interval = 420;
            }
        }
    }

    StepButton {
        id: minus

        x: 3
        direction: -1
        sign: "−"
    }

    StepButton {
        id: plus

        x: root.width - width - 3
        direction: 1
        sign: "+"
    }

    TextMetrics {
        id: zeroMetrics

        font: input.font
        text: root.zeroText
    }

    Binding {
        target: input
        property: "text"
        value: root.display
        when: !input.activeFocus
    }

    MouseArea {
        anchors.left: minus.right
        anchors.right: plus.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        cursorShape: Qt.IBeamCursor
        onPressed: event => {
            input.forceActiveFocus();
            event.accepted = false;
        }
    }

    TextInput {
        id: input

        anchors.left: minus.right
        anchors.right: plus.left
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: TextInput.AlignHCenter
        font.family: Theme.uiFont
        font.pixelSize: 13
        color: Theme.fg
        selectionColor: Theme.fg2
        selectByMouse: true
        clip: true
        onActiveFocusChanged: {
            if (!activeFocus)
                return;
            text = String(root.value);
            selectAll();
        }
        onEditingFinished: {
            root.commit(Number(text.replace(",", ".")));
            focus = false;
        }
        Keys.onEscapePressed: event => {
            text = root.display;
            focus = false;
            event.accepted = true;
        }
    }
}
