import QtQuick
import QtQuick.Effects
import qs.theme

Item {
    id: root

    property var capture: null
    property bool unlocking: false
    readonly property bool hasBackdrop: capture !== null && capture.hasContent

    onCaptureChanged: adopt()
    Component.onCompleted: adopt()

    function adopt(): void {
        if (!capture)
            return;
        capture.parent = holder;
        capture.anchors.fill = holder;
        capture.visible = true;
    }

    Item {
        id: holder

        anchors.fill: parent
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        visible: root.hasBackdrop
        source: holder
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 40
        blur: root.unlocking ? 0 : 1

        Behavior on blur {
            enabled: !Motion.reduced

            Exit {
                duration: 220
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.hasBackdrop ? Qt.rgba(8 / 255, 8 / 255, 9 / 255, 1) : Theme.glassBase
        opacity: root.hasBackdrop && root.unlocking ? 0 : root.hasBackdrop ? 0.55 : 1

        Behavior on opacity {
            enabled: !Motion.reduced

            Exit {
                duration: 220
            }
        }
    }
}
