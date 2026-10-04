pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import qs.components
import qs.services
import qs.theme

Item {
    id: root

    required property Notification notification
    property int bodyLines: 3
    readonly property bool hovered: hover.hovered
    readonly property bool critical: notification?.urgency === NotificationUrgency.Critical
    readonly property string image: notification?.image ?? ""
    readonly property var buttons: (notification?.actions ?? []).filter(action => action.identifier !== "default" && action.text !== "")

    implicitHeight: row.implicitHeight + 24

    HoverHandler {
        id: hover
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: root.hovered ? Theme.hover : "transparent"

        Behavior on color {
            EffectsColor {}
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.MiddleButton)
                Notifications.dismiss(root.notification);
            else
                Notifications.activate(root.notification);
        }
    }

    RowLayout {
        id: row

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 12

        Rectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 40
            implicitHeight: 40
            radius: picture.status === Image.Ready ? 12 : 20
            color: root.critical ? Theme.red : Theme.fill
            border.width: root.critical ? 0 : 1
            border.color: Theme.line
            antialiasing: true

            DisplayText {
                anchors.centerIn: parent
                visible: picture.status !== Image.Ready
                text: Notifications.lead(root.notification)
                font.pixelSize: 22
            }

            RoundedImage {
                id: picture

                anchors.fill: parent
                visible: status === Image.Ready
                radius: 12
                source: root.image.startsWith("/") ? `file://${root.image}` : root.image
                sourceSize: Qt.size(80, 80)
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    Layout.fillWidth: true
                    text: root.notification?.appName || "Notification"
                    color: root.critical ? Theme.red : Theme.fg2
                    pixelSize: 11
                    elide: Text.ElideRight
                }

                Label {
                    text: Notifications.age(root.notification, Time.now)
                    color: Theme.fg3
                    pixelSize: 11
                }

                MorphButton {
                    implicitWidth: 22
                    implicitHeight: 22
                    restColor: "transparent"
                    hoverColor: Theme.hover
                    outline: "transparent"
                    pressScale: 0.86
                    opacity: root.hovered ? 1 : 0
                    onClicked: Notifications.dismiss(root.notification)

                    Behavior on opacity {
                        Effects {}
                    }

                    DotIcon {
                        anchors.centerIn: parent
                        name: "close"
                        size: 10
                        color: Theme.fg2
                    }
                }
            }

            Body {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notification?.summary ?? ""
                wrapMode: Text.Wrap
                maximumLineCount: 2
            }

            Body {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notification?.body ?? ""
                color: Theme.fg2
                font.pixelSize: 12
                wrapMode: Text.Wrap
                maximumLineCount: root.bodyLines
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 6
                visible: root.buttons.length > 0
                spacing: 6

                Repeater {
                    model: root.buttons

                    MorphButton {
                        id: actionButton

                        required property NotificationAction modelData

                        implicitWidth: actionLabel.implicitWidth + 24
                        implicitHeight: 28
                        restRadius: 14
                        pressRadius: 8
                        hoverColor: Qt.rgba(1, 1, 1, 0.1)
                        onClicked: Notifications.invoke(root.notification, actionButton.modelData)

                        Label {
                            id: actionLabel

                            anchors.centerIn: parent
                            text: actionButton.modelData?.text ?? ""
                            pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}
