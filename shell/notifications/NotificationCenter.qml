pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.components
import qs.services
import qs.theme

Panel {
    id: root

    readonly property int count: Notifications.list.length

    fromRight: true
    onOpenChanged: {
        if (!open)
            return;
        Notifications.markRead();
        list.followTop = true;
        list.positionViewAtBeginning();
    }

    component Pill: MorphButton {
        id: pill

        property string glyph
        property string text
        property bool on: false

        implicitWidth: pillRow.implicitWidth + 28
        implicitHeight: 34
        restRadius: on ? 10 : 17
        pressRadius: 8
        restColor: on ? Theme.fg : Theme.fill
        hoverColor: on ? Theme.fg : Qt.rgba(1, 1, 1, 0.1)
        outline: on ? "transparent" : Theme.line

        Row {
            id: pillRow

            anchors.centerIn: parent
            spacing: 8

            DotIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: pill.glyph !== ""
                name: pill.glyph
                color: pill.on ? Theme.glassBase : Theme.fg

                Behavior on color {
                    EffectsColor {}
                }
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: pill.text
                pixelSize: 12
                color: pill.on ? Theme.glassBase : Theme.fg

                Behavior on color {
                    EffectsColor {}
                }
            }
        }
    }

    Reveal {
        shown: root.open
        order: 0
        Layout.fillWidth: true
        implicitHeight: header.implicitHeight

        RowLayout {
            id: header

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 4
            spacing: 8

            Label {
                text: "Notifications"
            }

            RollText {
                Layout.fillWidth: true
                text: String(root.count)
                direction: 1
                color: Theme.fg2
            }

            Pill {
                glyph: "moon"
                text: "Silent"
                on: Notifications.doNotDisturb
                onClicked: Notifications.toggleDoNotDisturb()
            }

            Pill {
                text: "Clear"
                enabled: root.count > 0
                opacity: enabled ? 1 : 0.4
                onClicked: Notifications.clear()
            }
        }
    }

    Reveal {
        shown: root.open
        order: 1
        Layout.fillWidth: true
        implicitHeight: root.count > 0 ? Math.min(list.contentHeight, 720) : empty.implicitHeight

        Behavior on implicitHeight {
            enabled: !Motion.reduced && root.open

            SpatialStandard {}
        }

        Body {
            id: empty

            width: parent.width
            visible: root.count === 0
            topPadding: 28
            bottomPadding: 28
            horizontalAlignment: Text.AlignHCenter
            text: Notifications.doNotDisturb ? "Silent · popups are off" : "No notifications"
            color: Theme.fg2
        }

        ListView {
            id: list

            property bool followTop: true

            anchors.fill: parent
            clip: true
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
            onMovementEnded: followTop = contentY <= originY + 1
            onCountChanged: {
                if (followTop)
                    positionViewAtBeginning();
            }
            model: ScriptModel {
                comparisonMode: ObjectComparison.Identity
                values: Notifications.list
            }

            delegate: Item {
                id: slot

                required property Notification modelData
                required property int index

                width: list.width
                height: card.implicitHeight + (index > 0 ? 6 : 0)

                DottedLine {
                    visible: slot.index > 0
                    vertical: false
                    x: 12
                    width: parent.width - 24
                }

                NotificationCard {
                    id: card

                    y: slot.index > 0 ? 6 : 0
                    width: parent.width
                    notification: slot.modelData
                    bodyLines: 6
                }
            }

            add: Transition {
                enabled: !Motion.reduced && root.open

                SequentialAnimation {
                    PropertyAction {
                        property: "opacity"
                        value: 0
                    }
                    PropertyAction {
                        property: "scale"
                        value: 0.96
                    }
                    ParallelAnimation {
                        Effects {
                            property: "opacity"
                            to: 1
                        }
                        SpatialStandard {
                            property: "scale"
                            to: 1
                            epsilon: 0.002
                        }
                    }
                }
            }

            remove: Transition {
                enabled: !Motion.reduced

                ParallelAnimation {
                    Exit {
                        property: "opacity"
                        to: 0
                        duration: 160
                    }
                    Exit {
                        property: "x"
                        to: 60
                        duration: 200
                    }
                }
            }

            displaced: Transition {
                enabled: !Motion.reduced

                SpatialStandard {
                    property: "y"
                }
                Effects {
                    properties: "opacity,scale"
                    to: 1
                }
            }
        }
    }
}
