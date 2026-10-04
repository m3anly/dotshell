import QtQuick
import qs.theme

Item {
    id: root

    property bool shown: false
    property int order: 0
    property bool revealed: false

    opacity: revealed ? 1 : 0
    scale: revealed ? 1 : 0.94
    transform: Translate {
        y: root.revealed ? 0 : 10

        Behavior on y {
            enabled: !Motion.reduced

            SpatialStandard {}
        }
    }

    onShownChanged: {
        if (shown && !Motion.reduced) {
            delay.restart();
            return;
        }
        delay.stop();
        revealed = shown;
    }

    Behavior on opacity {
        enabled: !Motion.reduced

        Effects {
            duration: root.revealed ? Motion.effectsMs : 100
        }
    }
    Behavior on scale {
        enabled: !Motion.reduced

        SpatialStandard {
            epsilon: 0.002
        }
    }

    Timer {
        id: delay

        interval: root.order * 26 + 40
        onTriggered: root.revealed = true
    }
}
