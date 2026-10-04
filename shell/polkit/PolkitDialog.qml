pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.theme

Rectangle {
    id: root

    property bool open: false
    readonly property var flow: Polkit.flow
    readonly property bool wrong: Polkit.failures > 0 && field.text === "" && !Polkit.checking
    readonly property string prompt: (flow?.inputPrompt ?? "").replace(/[:\s]+$/, "")
    readonly property string status: {
        if (Polkit.checking)
            return "Checking";
        if (flow?.supplementaryMessage)
            return flow.supplementaryMessage;
        if (wrong)
            return "Wrong password";
        return "";
    }
    readonly property bool statusIsError: !Polkit.checking && ((flow?.supplementaryMessage && flow.supplementaryIsError) || (!flow?.supplementaryMessage && wrong))

    width: 440
    height: layout.implicitHeight + 48
    radius: 24
    color: Theme.glass(Theme.tintLauncher)
    border.width: 1
    border.color: Theme.line
    antialiasing: true
    visible: opacity > 0
    opacity: 0
    scale: 0.94
    readonly property alias offset: shift.y

    transform: Translate {
        id: shift

        y: -18
    }

    function submit(): void {
        if (field.text === "")
            return;
        Polkit.submit(field.text);
    }

    onOpenChanged: {
        if (!open)
            return;
        field.text = "";
        focusDelay.restart();
    }

    Connections {
        target: Polkit

        function onStarted(): void {
            field.text = "";
            focusDelay.restart();
        }

        function onFailed(): void {
            field.text = "";
            if (!Motion.reduced)
                shake.restart();
        }
    }

    states: State {
        name: "open"
        when: root.open

        PropertyChanges {
            root.opacity: 1
            root.scale: 1
            shift.y: 0
        }
    }

    transitions: [
        Transition {
            to: "open"
            enabled: !Motion.reduced

            ParallelAnimation {
                Effects {
                    property: "opacity"
                }
                SpatialStandard {
                    property: "scale"
                    epsilon: 0.002
                }
                SpatialStandard {
                    target: shift
                    property: "y"
                }
            }
        },
        Transition {
            from: "open"
            enabled: !Motion.reduced

            ParallelAnimation {
                Exit {
                    property: "opacity"
                    duration: 150
                }
                Exit {
                    properties: "scale,y"
                    duration: 180
                }
            }
        }
    ]

    Behavior on height {
        enabled: !Motion.reduced && root.open

        SpatialStandard {}
    }

    Timer {
        id: focusDelay

        interval: 60
        onTriggered: field.forceActiveFocus()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: field.forceActiveFocus()
    }

    component Pill: MorphButton {
        id: pill

        property string glyph
        property string text
        property bool primary: false
        property bool busy: false

        implicitWidth: Math.max(112, pillRow.implicitWidth + 32)
        implicitHeight: 40
        restRadius: 20
        pressRadius: 8
        restColor: primary ? Theme.fg : Theme.fill
        hoverColor: primary ? Theme.fg : Qt.rgba(1, 1, 1, 0.1)
        outline: primary ? "transparent" : Theme.line

        Row {
            id: pillRow

            anchors.centerIn: parent
            spacing: 10
            visible: !pill.busy

            DotIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: pill.glyph !== ""
                name: pill.glyph
                color: pill.primary ? Theme.glassBase : Theme.fg
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: pill.text
                color: pill.primary ? Theme.glassBase : Theme.fg
            }
        }

        LoadingDots {
            anchors.centerIn: parent
            visible: pill.busy
            color: pill.primary ? Theme.glassBase : Theme.fg
        }
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: 24
        spacing: 18

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Rectangle {
                implicitWidth: 44
                implicitHeight: 44
                radius: 22
                color: Theme.fill
                border.width: 1
                border.color: Theme.line

                DotIcon {
                    anchors.centerIn: parent
                    name: "shield"
                    size: 18
                    color: Theme.red
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Label {
                    Layout.fillWidth: true
                    text: "Authentication required"
                    elide: Text.ElideRight
                }

                Label {
                    Layout.fillWidth: true
                    visible: Polkit.actionId !== ""
                    text: Polkit.actionId
                    color: Theme.fg3
                    pixelSize: 11
                    tracking: 0.02
                    font.capitalization: Font.MixedCase
                    elide: Text.ElideMiddle
                }
            }
        }

        Body {
            Layout.fillWidth: true
            text: Polkit.message
            wrapMode: Text.Wrap
            maximumLineCount: 5
            lineHeight: 1.15
            color: Theme.fg
        }

        DottedLine {
            Layout.fillWidth: true
            vertical: false
        }

        MorphButton {
            Layout.fillWidth: true
            implicitHeight: 44
            restRadius: 22
            pressRadius: 12
            pressScale: 0.97
            restColor: "transparent"
            hoverColor: Polkit.canSwitchIdentity ? Theme.hover : "transparent"
            outline: "transparent"
            enabled: Polkit.canSwitchIdentity
            onClicked: Polkit.selectNextIdentity()

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 4
                anchors.rightMargin: 12
                spacing: 12

                Rectangle {
                    implicitWidth: 34
                    implicitHeight: 34
                    radius: 17
                    color: Theme.fg

                    DisplayText {
                        anchors.centerIn: parent
                        text: Apps.monogram(Polkit.identityName)
                        color: Theme.glassBase
                        font.pixelSize: 16
                    }
                }

                RollText {
                    Layout.fillWidth: true
                    text: Polkit.identityName
                }

                DotIcon {
                    visible: Polkit.canSwitchIdentity
                    name: "chev"
                    color: Theme.fg2
                }
            }
        }

        Rectangle {
            id: fieldBox

            Layout.fillWidth: true
            implicitHeight: 46
            radius: field.activeFocus ? 12 : 23
            color: Theme.fill
            border.width: 1
            border.color: root.wrong ? Theme.red : field.activeFocus ? Theme.fg2 : Theme.line
            antialiasing: true
            transform: Translate {
                id: shakeOffset
            }

            Behavior on radius {
                enabled: !Motion.reduced

                SpatialStandard {}
            }
            Behavior on border.color {
                EffectsColor {}
            }

            SequentialAnimation {
                id: shake

                PropertyAction {
                    target: shakeOffset
                    property: "x"
                    value: 18
                }
                SpatialFast {
                    target: shakeOffset
                    property: "x"
                    to: 0
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                DotIcon {
                    name: "lock"
                    color: Theme.fg2
                }

                TextInput {
                    id: field

                    Layout.fillWidth: true
                    font.family: Theme.uiFont
                    font.pixelSize: 15
                    color: Theme.fg
                    selectionColor: Theme.fg2
                    echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                    passwordCharacter: "●"
                    font.letterSpacing: echoMode === TextInput.Password ? 3 : 0
                    readOnly: Polkit.checking
                    clip: true
                    onAccepted: root.submit()
                    Keys.onEscapePressed: Polkit.cancel()

                    Body {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: field.text === ""
                        text: root.prompt || "Password"
                        color: Theme.fg3
                        font.pixelSize: 15
                    }
                }
            }
        }

        Label {
            Layout.fillWidth: true
            Layout.preferredHeight: 14
            text: root.status
            color: root.statusIsError ? Theme.red : Theme.fg2
            pixelSize: 11
            elide: Text.ElideRight

            Behavior on color {
                EffectsColor {}
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item {
                Layout.fillWidth: true
            }

            Pill {
                text: "Cancel"
                onClicked: Polkit.cancel()
            }

            Pill {
                glyph: "lock"
                text: "Unlock"
                primary: true
                busy: Polkit.checking
                onClicked: root.submit()
            }
        }
    }
}
