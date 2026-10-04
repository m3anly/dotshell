import QtQuick
import qs.components
import qs.services
import qs.theme

Bay {
    id: bay

    property string screenName

    interactive: true
    spacing: 12
    active: Ui.panel === "quickSettings" && Ui.screen === screenName
    onClicked: Ui.togglePanel("quickSettings", screenName)

    component StatusIcon: DotIcon {
        property bool dim: false

        opacity: dim ? 0.3 : 1

        Behavior on opacity {
            Effects {}
        }
        Behavior on color {
            EffectsColor {}
        }
    }

    StatusIcon {
        name: "wifi"
        color: bay.foreground
        dim: !Radios.wifiConnected
    }

    StatusIcon {
        name: "bt"
        color: bay.foreground
        dim: !Radios.bluetoothEnabled
    }

    StatusIcon {
        name: "vol"
        color: bay.foreground
        dim: Audio.sinkSilent
    }

    DotIcon {
        name: "power"
        color: Theme.red
    }
}
