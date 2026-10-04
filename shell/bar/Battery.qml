pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services
import qs.theme

Bay {
    id: bay

    property string screenName
    readonly property int litCells: Math.round(Power.level * 10)

    visible: Power.present
    interactive: true
    active: Ui.panel === "battery" && Ui.screen === screenName
    onClicked: Ui.togglePanel("battery", screenName)

    Row {
        spacing: 6

        Label {
            text: "BAT"
            color: bay.active ? Qt.rgba(0, 0, 0, 0.55) : Theme.fg2

            Behavior on color {
                EffectsColor {}
            }
        }

        Label {
            text: `${Power.percent}%`
            color: bay.foreground

            Behavior on color {
                EffectsColor {}
            }
        }
    }

    Row {
        spacing: 2

        Repeater {
            model: 10

            Rectangle {
                required property int index

                width: 3
                height: 10
                color: index < bay.litCells ? bay.foreground : bay.active ? Qt.rgba(0, 0, 0, 0.15) : Theme.off

                Behavior on color {
                    EffectsColor {}
                }
            }
        }
    }
}
