import QtQuick
import qs.theme

Item {
    id: root

    property string text
    property string rollKey: text
    property string shownKey: ""
    property int direction: 1
    property color color: Theme.fg
    property int elide: Text.ElideRight
    property int horizontalAlignment: Text.AlignLeft
    property int pixelSize: Theme.labelSize
    property bool uppercase: true
    property bool display: false

    clip: true
    implicitWidth: Math.max(current.implicitWidth, previous.opacity > 0 ? previous.implicitWidth : 0)
    implicitHeight: current.implicitHeight

    Component.onCompleted: {
        current.text = text;
        shownKey = rollKey;
    }
    onTextChanged: Qt.callLater(roll)
    onRollKeyChanged: Qt.callLater(roll)

    function roll(): void {
        const sameKey = rollKey === shownKey;
        shownKey = rollKey;
        if (current.text === text)
            return;
        if (Motion.reduced || current.text === "" || sameKey) {
            current.text = text;
            return;
        }
        exit.stop();
        previous.text = current.text;
        previous.y = current.y;
        previous.opacity = current.opacity;
        exit.start();

        slide.enabled = false;
        current.text = text;
        current.y = direction * root.height;
        current.opacity = 0;
        slide.enabled = true;
        current.y = 0;
        fadeIn.restart();
    }

    Label {
        id: previous

        width: root.width
        opacity: 0
        color: root.color
        elide: root.elide
        horizontalAlignment: root.horizontalAlignment
        pixelSize: root.pixelSize
        font.capitalization: root.uppercase && !root.display ? Font.AllUppercase : Font.MixedCase
        font.family: root.display ? Theme.displayFont : Theme.uiFont
        font.weight: root.display ? 800 : Font.Normal
        font.variableAxes: root.display ? Theme.displayAxes : ({})
        tracking: root.display ? 0 : Theme.labelTracking
    }

    Label {
        id: current

        width: root.width
        color: root.color
        elide: root.elide
        horizontalAlignment: root.horizontalAlignment
        pixelSize: root.pixelSize
        font.capitalization: root.uppercase && !root.display ? Font.AllUppercase : Font.MixedCase
        font.family: root.display ? Theme.displayFont : Theme.uiFont
        font.weight: root.display ? 800 : Font.Normal
        font.variableAxes: root.display ? Theme.displayAxes : ({})
        tracking: root.display ? 0 : Theme.labelTracking

        Behavior on y {
            id: slide

            SpatialStandard {}
        }
    }

    ParallelAnimation {
        id: exit

        Exit {
            target: previous
            property: "y"
            to: -root.direction * root.height * 0.7
            duration: 160
        }
        Exit {
            target: previous
            property: "opacity"
            to: 0
            duration: 160
        }
    }

    Effects {
        id: fadeIn

        target: current
        property: "opacity"
        from: 0
        to: 1
        duration: 220
    }
}
