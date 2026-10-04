import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.theme

Reveal {
    id: root

    implicitHeight: row.implicitHeight + 8

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.margins: 4
        spacing: 12

        Rectangle {
            implicitWidth: 44
            implicitHeight: 44
            radius: 22
            color: Theme.fill
            border.width: 1
            border.color: Theme.line

            DisplayText {
                anchors.centerIn: parent
                text: Session.userName.slice(0, 2)
                font.pixelSize: 20
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Label {
                Layout.fillWidth: true
                text: Session.userName
                elide: Text.ElideRight
            }

            Label {
                Layout.fillWidth: true
                text: Session.uptime
                color: Theme.fg2
                pixelSize: 11
                elide: Text.ElideRight
            }
        }

        Row {
            visible: Power.present
            spacing: 6

            Label {
                text: "BAT"
                color: Theme.fg2
            }

            Label {
                text: Power.timeLeft !== "" ? `${Power.percent}% · ${Power.timeLeft}` : `${Power.percent}%`
            }
        }
    }
}
