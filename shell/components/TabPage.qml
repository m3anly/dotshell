pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.theme

Item {
    id: root

    required property string tab
    property string group: "dashboard"
    readonly property int direction: Ui[`${group}Direction`]
    readonly property bool current: Ui[`${group}Tab`] === tab

    visible: opacity > 0
    opacity: 0
    enabled: current
    transform: Translate {
        id: shift
    }

    Component.onCompleted: {
        if (current)
            opacity = 1;
    }

    onCurrentChanged: {
        enter.stop();
        leave.stop();
        if (Motion.reduced) {
            opacity = current ? 1 : 0;
            shift.x = 0;
            return;
        }
        if (current)
            enter.start();
        else
            leave.start();
    }

    ParallelAnimation {
        id: enter

        SpatialStandard {
            target: shift
            property: "x"
            from: root.direction * 28
            to: 0
        }
        Effects {
            target: root
            property: "opacity"
            to: 1
        }
    }

    ParallelAnimation {
        id: leave

        Exit {
            target: shift
            property: "x"
            to: -root.direction * 16
            duration: 140
        }
        Exit {
            target: root
            property: "opacity"
            to: 0
            duration: 140
        }
    }
}
