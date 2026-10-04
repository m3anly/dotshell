import QtQuick
import qs.services

MouseArea {
    id: root

    property string output
    property real touchpadX: 0
    property real touchpadY: 0
    property real wheelY: 0
    property bool cooling: false

    acceptedButtons: Qt.NoButton

    function step(accumulated: real): int {
        return accumulated < 0 ? 1 : -1;
    }

    function act(horizontal: bool, accumulated: real): void {
        if (Niri.focusedWorkspace && Niri.focusedWorkspace.output !== output)
            Niri.focusMonitor(output);
        if (horizontal)
            Niri.focusColumnRelative(step(accumulated));
        else
            Niri.focusWorkspaceRelative(step(accumulated));
        cooling = true;
        cooldown.restart();
    }

    onWheel: wheel => {
        wheel.accepted = false;
        if (cooling)
            return;
        const dx = wheel.angleDelta.x;
        const dy = wheel.angleDelta.y;
        const touchpad = wheel.pixelDelta.x !== 0 || wheel.pixelDelta.y !== 0;
        if (Math.abs(dx) > Math.abs(dy)) {
            if (!touchpad)
                return;
            touchpadX += dx;
            if (Math.abs(touchpadX) >= 500) {
                act(true, touchpadX);
                touchpadX = 0;
            }
            return;
        }
        if (touchpad) {
            touchpadY += dy;
            if (Math.abs(touchpadY) >= 500) {
                act(false, touchpadY);
                touchpadY = 0;
            }
            return;
        }
        wheelY += dy;
        if (Math.abs(wheelY) >= 120) {
            act(false, wheelY);
            wheelY = 0;
        }
    }

    Timer {
        id: cooldown

        interval: 100
        onTriggered: root.cooling = false
    }
}
