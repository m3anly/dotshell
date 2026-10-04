pragma ComponentBehavior: Bound

import QtQuick
import qs.theme

Item {
    id: root

    property url source
    property size sourceSize
    property int front: 0
    readonly property bool ready: (images.itemAt(front) as Image)?.status === Image.Ready

    onSourceChanged: {
        const back = images.itemAt(1 - front) as Image;
        if (!back)
            return;
        back.source = source;
        if (source.toString() === "" || back.status === Image.Ready)
            front = 1 - front;
    }

    Repeater {
        id: images

        model: 2

        Image {
            required property int index

            anchors.fill: parent
            asynchronous: true
            cache: false
            fillMode: Image.PreserveAspectCrop
            sourceSize: root.sourceSize
            opacity: root.front === index ? 1 : 0
            Component.onCompleted: {
                if (index === root.front)
                    source = root.source;
            }
            onStatusChanged: {
                if (status === Image.Ready && root.front !== index && source === root.source)
                    root.front = index;
            }

            Behavior on opacity {
                enabled: !Motion.reduced

                NumberAnimation {
                    duration: 480
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.effectsCurve
                }
            }
        }
    }
}
