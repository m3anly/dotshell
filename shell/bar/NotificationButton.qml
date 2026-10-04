import QtQuick
import qs.components
import qs.services
import qs.theme

Bay {
    id: bay

    property string screenName

    interactive: true
    spacing: 6
    active: Ui.panel === "notifications" && Ui.screen === screenName
    onClicked: Ui.togglePanel("notifications", screenName)

    DotIcon {
        name: Notifications.doNotDisturb ? "moon" : "bell"
        color: bay.foreground

        Behavior on color {
            EffectsColor {}
        }
    }

    Rectangle {
        visible: Notifications.unread > 0 && !Notifications.doNotDisturb
        implicitWidth: 6
        implicitHeight: 6
        radius: 3
        color: Theme.red
    }
}
