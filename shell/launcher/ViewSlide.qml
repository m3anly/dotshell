import QtQuick
import qs.theme

Item {
    id: root

    property bool active: false
    property bool animateEnter: false
    property int enterFrom: 1

    visible: active
    transform: Translate {
        id: slide
    }

    onActiveChanged: {
        if (active && animateEnter && !Motion.reduced)
            enter.restart();
    }

    ParallelAnimation {
        id: enter

        SpatialStandard {
            target: slide
            property: "x"
            from: root.enterFrom * 28
            to: 0
        }
        Effects {
            target: root
            property: "opacity"
            from: 0
            to: 1
        }
    }
}
