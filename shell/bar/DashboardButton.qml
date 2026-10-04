pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.theme

Bay {
    id: bay

    property string screenName
    readonly property color secondary: active ? Qt.rgba(0, 0, 0, 0.55) : Theme.fg2

    interactive: true
    dividerRight: true
    active: Ui.panel === "dashboard" && Ui.screen === screenName
    onClicked: event => Ui.toggleDashboard(tabAt(event.x), screenName)

    function tabAt(x: real): string {
        if (weather.visible && weatherDivider.mapFromItem(bay, x, 0).x >= 0)
            return "weather";
        if (dateDivider.mapFromItem(bay, x, 0).x >= 0)
            return "calendar";
        return "media";
    }

    component Divider: DottedLine {
        Layout.preferredHeight: Theme.barHeight
        Layout.leftMargin: Theme.bayPadding - Theme.baySpacing
        Layout.rightMargin: Theme.bayPadding - Theme.baySpacing
        color: bay.active ? Qt.rgba(0, 0, 0, 0.3) : Theme.fg3
    }

    DotClock {
        Layout.bottomMargin: 1
        digits: Time.hhmm
        color: bay.foreground
    }

    Label {
        visible: Time.hour12
        text: Time.period
        color: bay.foreground

        Behavior on color {
            EffectsColor {}
        }
    }

    Divider {
        id: dateDivider
    }

    Label {
        text: Time.dayLabel
        color: bay.foreground

        Behavior on color {
            EffectsColor {}
        }
    }

    Divider {
        id: weatherDivider

        visible: weather.visible
    }

    RowLayout {
        id: weather

        visible: Weather.available
        spacing: Theme.baySpacing

        DotIcon {
            name: Weather.glyph
            color: bay.foreground

            Behavior on color {
                EffectsColor {}
            }
        }

        RollText {
            text: Weather.temperature
            color: bay.secondary
        }

        RollText {
            text: Weather.condition
            color: bay.foreground
        }
    }
}
