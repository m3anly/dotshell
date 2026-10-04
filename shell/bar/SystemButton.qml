pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.theme

Bay {
    id: bay

    property string screenName

    interactive: true
    dividerLeft: false
    active: Ui.panel === "system" && Ui.screen === screenName
    onClicked: Ui.togglePanel("system", screenName)

    Grid {
        columns: 3
        spacing: 3

        Repeater {
            model: 9

            Rectangle {
                required property int index

                width: 4
                height: 4
                radius: 2
                color: index === 4 ? Theme.red : bay.foreground
                scale: bay.active ? (index % 2 === 0 ? 1.4 : 0.7) : 1

                Behavior on scale {
                    enabled: !Motion.reduced

                    SpatialFast {
                        epsilon: 0.002
                    }
                }
                Behavior on color {
                    EffectsColor {}
                }
            }
        }
    }
}
