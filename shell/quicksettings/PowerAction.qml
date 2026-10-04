import QtQuick
import qs.components
import qs.theme

MorphButton {
    id: root

    property string glyph
    property string text
    property int order: 0
    property bool shown: false
    property bool revealed: false
    property bool holdToFire: false
    property real holdMs: 900
    property real fill: 0

    signal fired

    implicitHeight: column.implicitHeight + 24
    restRadius: 14
    hoverRadius: 22
    pressScale: 0.9
    hoverColor: Qt.rgba(1, 1, 1, 0.11)
    opacity: revealed ? 1 : 0
    scale: pressed ? pressScale : revealed ? 1 : 0.7

    onShownChanged: {
        if (shown && !Motion.reduced) {
            delay.restart();
            return;
        }
        delay.stop();
        revealed = shown;
        if (!shown) {
            holdFill.stop();
            release.stop();
            fill = 0;
        }
    }
    onClicked: {
        if (!holdToFire)
            fired();
    }
    onPressStarted: {
        if (holdToFire)
            holdFill.start();
    }
    onPressEnded: {
        if (!holdToFire || fill >= 1)
            return;
        holdFill.stop();
        release.start();
    }

    Behavior on opacity {
        enabled: !Motion.reduced

        Effects {
            duration: root.revealed ? Motion.effectsMs : 100
        }
    }

    Timer {
        id: delay

        interval: root.order * 30 + 60
        onTriggered: root.revealed = true
    }

    NumberAnimation {
        id: holdFill

        target: root
        property: "fill"
        to: 1
        duration: root.holdMs * (1 - root.fill)
        onFinished: {
            if (root.fill >= 1)
                root.fired();
        }
    }

    Exit {
        id: release

        target: root
        property: "fill"
        to: 0
        duration: 200
    }

    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.holdToFire && root.fill > 0
        height: parent.height * root.fill
        clip: true

        Rectangle {
            anchors.bottom: parent.bottom
            width: root.width
            height: root.height
            radius: root.radius
            color: Theme.red
            antialiasing: true
        }
    }

    Column {
        id: column

        anchors.centerIn: parent
        spacing: 7

        DotIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: root.glyph
            size: 18
            color: root.holdToFire && root.fill < 0.5 ? Theme.red : Theme.fg
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.holdToFire && root.pressed ? "Hold" : root.text
            pixelSize: 10
        }
    }
}
