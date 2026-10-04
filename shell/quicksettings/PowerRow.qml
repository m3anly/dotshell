import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.theme

Item {
    id: root

    property bool open: false
    property real openness: 0
    readonly property real holdMs: Math.max(100, Config.power.holdMs)

    function confirms(action: string): bool {
        return Config.power.confirm.includes(action);
    }

    implicitHeight: Math.round((actions.implicitHeight + 12) * openness)
    visible: openness > 0
    clip: true

    states: State {
        name: "open"
        when: root.open

        PropertyChanges {
            root.openness: 1
        }
    }

    transitions: [
        Transition {
            to: "open"
            enabled: !Motion.reduced

            Expand {
                property: "openness"
            }
        },
        Transition {
            from: "open"
            enabled: !Motion.reduced

            Exit {
                property: "openness"
                duration: 220
            }
        }
    ]

    RowLayout {
        id: actions

        y: 12
        width: parent.width
        spacing: 6

        PowerAction {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            order: 0
            shown: root.open
            glyph: "lock"
            text: "Lock"
            holdToFire: root.confirms("lock")
            holdMs: root.holdMs
            onFired: Session.lock()
        }

        PowerAction {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            order: 1
            shown: root.open
            glyph: "moon"
            text: "Sleep"
            holdToFire: root.confirms("suspend")
            holdMs: root.holdMs
            onFired: Session.suspend()
        }

        PowerAction {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            order: 2
            shown: root.open
            glyph: "logout"
            text: "Log out"
            holdToFire: root.confirms("logout")
            holdMs: root.holdMs
            onFired: Session.logOut()
        }

        PowerAction {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            order: 3
            shown: root.open
            glyph: "reboot"
            text: "Reboot"
            holdToFire: root.confirms("reboot")
            holdMs: root.holdMs
            onFired: Session.reboot()
        }

        PowerAction {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            order: 4
            shown: root.open
            glyph: "power"
            text: "Power off"
            holdToFire: root.confirms("poweroff")
            holdMs: root.holdMs
            onFired: Session.powerOff()
        }
    }
}
